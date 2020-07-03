#!/bin/bash
xmlreadonly=${1?"Usage: $0 <xml file with transaction data)> [<txin position to sign>] [<--overwrite|--new>] (and pipe your private key in WIF (wallet input format) through STDIN)"}
inputnumber=${2:-1}
xmlfilepolicy=${3:-"--new"}
xml=`mktemp --dry-run`; [[ "$xmlfilepolicy" == "--overwrite" ]] && xml=$xmlreadonly || cp $xmlreadonly $xml
echo "Press ctrl-d when you are done entering the private key in wallet input format (ignore this message if you've piped the private key through STDIN)"
wif=`cat -`
compressed="false"; [[ $wif =~ ^(K|L).* ]] && compressed="true"
# ######################################################################################### FUNCTIONS:
declare -r FEEMIN=1000
declare -r FEEMAX=20000
declare -r GREEN='\033[1;32m'
declare -r ORANGE='\033[1;33m'
declare -r NOCOLOR='\033[0m'
function errout { 
        G=$(<<<$GREEN sed 's/\\/\\\\/g'); 
        O=$(<<<$ORANGE sed 's/\\/\\\\/g'); 
        NC=$(<<<$NOCOLOR sed 's/\\/\\\\/g'); 
        cat - \
        | sed -E "s/(failure|error)/${O}\\1${NC}/i" \
        | sed -E "s/(success)/${G}\\1${NC}/i" \
        | xargs -0 -n1 -I{} printf {} >&2 
}
function hex2bin { xxd -r -p ;}
function bin2hex { xxd -p -c 256 | tr -d '\n' ;}
function dec2hex { xargs printf ${1:-"%02x"} ;}
function hexstringlength { echo $(( `cat - | wc -c` / 2 )) | dec2hex ;}
function sha256 { hex2bin | openssl dgst --binary --sha256 | bin2hex ;}
function ripemd160 { hex2bin | openssl dgst --binary --ripemd160 | bin2hex ;}
function toggleendian { local i=`cat`; [[ $i =~ ... ]] && <<<${i:2} toggleendian; echo -n "${i:0:2}" ;}
function appendchecksum { hex=`cat -`; echo -n $hex; <<<$hex sha256 | sha256 | head -c 8 ;}
function addr2pubkeyhash { hex=`base58 -d | bin2hex`; tmp=${hex:0:42}; [[ "$hex" == "`<<<$tmp appendchecksum`" ]] || <<<"FAILURE: INVALID ADDRESS!" errout; echo -n ${tmp:2} ;}
function xmlget { xpath="$1"; cat $xml | xmlstarlet sel --text --template --value-of "$xpath" | tr -d '\n' ;}
function xmlset { value="`cat -`"; xpath="$1"; xmlstarlet ed --omit-decl --inplace --update "$xpath" --value "$value" $xml;}
function xmlclonenode { xpath="$1"; ename=${xpath##*\/}; ename=${ename%%[*};
        xmlstarlet ed --omit-decl --inplace --append "$xpath" --type elem -n "$ename" $xml 
        xmlstarlet ed --omit-decl --inplace --update "$xpath" -x "${xpath%\/*}/${ename}[1]/@*" $xml
        xmlstarlet ed --omit-decl --inplace --update "$xpath" -x "${xpath%\/*}/${ename}[1]/*" $xml
}
function xmlgetutxos { cat $xml | xmlstarlet sel --template --match "//txin//output" --value-of "@value" --nl ;}
function checkfee { spending=`cat -`; utxos=0; for u in `xmlgetutxos`; do utxos=$(($utxos+$u)); done; fee=$((${utxos}-${spending})); 
        echo $fee 
        [[ "$fee" -lt "$FEEMIN" ]] && { <<<"ERROR: FEE ($fee satoshis) TOO LOW! (Adjust FEEMIN if you disagree)" errout; exit 1 ;}
        [[ "$fee" -gt "$FEEMAX" ]] && { <<<"ERROR: FEE ($fee satoshis) TOO HIGH! (Adjust FEEMAX if you disagree)" errout; exit 1 ;}
}
function xmlforeach { xpath="$1"; cat $xml | xmlstarlet sel --template --match "$xpath" --value-of "position()" --nl ;}
function wif2priv { hex=`base58 -d | bin2hex`; tmp=${hex%????????}; [[ "$hex" == "`<<<$tmp appendchecksum`" ]] || <<<"FAILURE: INVALID ADDRESS!" errout; echo -n ${tmp:2:64} ;}
function priv2der { xargs -I{} echo "302e0201010420{}a00706052b8104000a" ;}
function priv2pem { xargs -I{} echo "302e0201010420{}a00706052b8104000a" | hex2bin | base64 | xargs -I{} echo -e "-----BEGIN EC PRIVATE KEY-----\n{}\n-----END EC PRIVATE KEY-----" | bin2hex ;}
function der2pubder { openssl ec -inform der -in <(hex2bin) -pubout -outform der -out - 2>/dev/null | bin2hex ;}
function pubder2pub { tail -c 130 ;}
function pub2compressedpub { pub=`cat -`; <<<${pub:(-1)} tr 02468aAcCeE 2 | tr 13579bBdDfF 3 | xargs -n1 -I{} echo -n 0{}${pub:2:64} ;}
# openssl signing with BIP62 treatment for S values, see https://bitcoin.stackexchange.com/questions/59820/sign-a-tx-with-low-s-value-using-openssl :
function signrawtransactionwithkey { raw=`cat -`; sig=''; for i in {0..999}; do sig=`<<<$raw hex2bin | openssl pkeyutl -inkey <(echo ${pem}|hex2bin) -sign -in - -pkeyopt digest:sha256 | bin2hex`; [[ $sig =~ 022100 ]] || break; done; echo $sig ;}
function verifyrawtransactionwithkey { hex2bin | openssl pkeyutl -keyform DER -inkey <(<<<$der der2pubder|hex2bin) -pubin -verify -in - -pkeyopt digest:sha256 -sigfile <(<<<$1 hex2bin) ;}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FUNCTIONS^
priv=`<<<$wif wif2priv`
der=`<<<$priv priv2der`
pem=`<<<$priv priv2pem`

totalsatoshis=0
for i in `xmlforeach "//txout//output"`; do
        satoshis=`xmlget "//txout//output[$i]/@value"`
        totalsatoshis=$(($totalsatoshis + $satoshis))
done
echo "totalsatoshis: $totalsatoshis (decimal)"
fee=`<<<$totalsatoshis checkfee || exit 1`
echo "fee: $fee"

# eliminate the pkscript of the outpoints that are not to be signed, and replace lenght with 00; see https://bitcoin.stackexchange.com/questions/41209/how-to-sign-a-transaction-with-multiple-inputs:
rawtransaction=`xmlget "
/txs/raw 
| //txin [position()=$inputnumber] /descendant::raw [not(ancestor::sigscript)] 
| //txin [position()!=$inputnumber]/descendant::raw [not(ancestor::sigscript)]  [not( (ancestor::pkscript or parent::output and count(preceding-sibling::raw)=1) )]
| //txin [position()!=$inputnumber]//output/raw[2]/@nullvalue
"`
rawtransaction+=`xmlget "//txout/descendant::raw"`
echo "rawtransaction: $rawtransaction"

rawtransactionhash=`<<<$rawtransaction sha256 | sha256`
echo "rawtransactionhash: $rawtransactionhash"



signedrawtransaction=`<<<$rawtransactionhash signrawtransactionwithkey`
echo "signedrawtransaction: $signedrawtransaction"
signedrawtransactionlength=`<<<"${signedrawtransaction}01" hexstringlength`

publickey=`<<<$der der2pubder | pubder2pub`
[[ "$compressed" == "true" ]] && publickey=`<<<$publickey pub2compressedpub`
echo "publickey: $publickey"
publickeylength=`<<<$publickey hexstringlength`

[[ ! "`<<<$publickey sha256 | ripemd160`" == ""`xmlget "//txin[$inputnumber]//output/pkscript/raw[4]"` ]] && { <<<"FAILURE: Provided private key does not resolve to public key hash of chosen outpoint!" errout; exit 1 ;}
verifytransaction=`<<<$rawtransactionhash verifyrawtransactionwithkey $signedrawtransaction`
<<<"verifytransaction: $verifytransaction" errout

# create sigscript structure underneath pkscript of signed txin:
xmlstarlet ed --omit-decl --inplace --delete "//txin[$inputnumber]//output/sigscript" $xml 
xmlstarlet ed --omit-decl --inplace --append "//txin[$inputnumber]//output/pkscript" --type elem -n "sigscript" $xml 
xmlstarlet ed --omit-decl --inplace --update "//txin[$inputnumber]//output/sigscript" --expr "//template/sigscript/*" $xml 
<<<$signedrawtransactionlength xmlset "//txin[$inputnumber]//output/sigscript/raw[1]"
<<<$signedrawtransaction       xmlset "//txin[$inputnumber]//output/sigscript/raw[2]"
<<<$publickeylength            xmlset "//txin[$inputnumber]//output/sigscript/raw[4]"
<<<$publickey                  xmlset "//txin[$inputnumber]//output/sigscript/raw[5]"

sigscript=`xmlget "//txin[$inputnumber]//output/sigscript/raw"`
echo "sigscript: $sigscript"
sigscriptlength=`<<<$sigscript hexstringlength`
<<<$sigscriptlength            xmlset "//txin[$inputnumber]//output/raw[2]"

cat $xml
printf "Above you see the content of xml file: ${GREEN}${xml}${NOCOLOR}\n"

signedtransaction=`xmlget "
//raw 
  [not( ancestor-or-self::*[@iteration='1'] )] 
  [not( ancestor::template )]
  [not( ancestor::pkscript[following-sibling::sigscript] )] 
" | tr 'ABCDEF' 'abcdef'`
txid=`<<<$signedtransaction sha256 | sha256 | toggleendian`
echo "txid: $txid"
printf "signedtransaction: ${GREEN}$signedtransaction${NOCOLOR}\n"
printf "satoshis/byte (rounded down):${GREEN} $(( $fee / 16#$(<<<$signedtransaction hexstringlength) )) ${NOCOLOR}\n"
printf "For ${GREEN}verification${NOCOLOR}, paste your signedtransaction into ${GREEN}https://blockchain.com/btc/decode-tx${NOCOLOR} and check if everything looks as you planned.\n"
printf "After verification, paste your signedtransaction into ${GREEN}https://blockchain.com/btc/pushtx${NOCOLOR} to ${GREEN}broadcast${NOCOLOR} it.\n"
printf "Once you have successfully broadcast your tansaction, watch its status on the blockchain: ${GREEN}https://blockchain.com/btc/tx/${txid}${NOCOLOR}.\n"

