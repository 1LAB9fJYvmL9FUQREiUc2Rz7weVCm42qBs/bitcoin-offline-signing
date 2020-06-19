#!/bin/bash
xmlreadonly=${1?"Usage: $0 <xml file with transaction data)> (and pipe your private key in WIF (wallet input format) through STDIN)"}
xml=`mktemp`; cp $xmlreadonly $xml
echo "Press ctrl-d when you are done entering the private key in wallet input format (ignore this message if you've piped the private key through STDIN)"
wif=`cat -`
compressed="false"; [[ $wif =~ ^(K|L).* ]] && compressed="true"
#read -p "If you are not on an OFFLINE computer, cancel (ctrl/c) this script! Otherwise, enter private key in hex notation: " priv
# ######################################################################################### FUNCTIONS:
declare -r FEEMIN=5000
declare -r FEEMAX=12000
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
function toggleendian { sed -e 's/\(..\)/\1 /g' | xargs -n1 echo | grep -n '' | sort -gr | cut -d: -f2 | xargs echo | tr -d ' ' ;}
function appendchecksum { hex=`cat -`; echo -n $hex; <<<$hex sha256 | sha256 | head -c 8 ;}
#function addr2pubkeyhash { hex=`cat - | base58 -d | bin2hex`; tmp=`<<<$hex sed 's/........$//'`; [[ "$hex" == "`<<<$tmp appendchecksum`" ]] || <<<"FAILURE: INVALID ADDRESS!" errout; <<<$tmp sed 's/^..//' ;}
function addr2pubkeyhash { hex=`base58 -d | bin2hex`; tmp=${hex:0:42}; [[ "$hex" == "`<<<$tmp appendchecksum`" ]] || <<<"FAILURE: INVALID ADDRESS!" errout; echo -n ${tmp:2} ;}
function pub2compressedpub { pub=`cat -`; <<<${pub:(-1)} tr 02468aAcCeE 2 | tr 13579bBdDfF 3 | xargs -n1 -I{} echo -n 0{}${pub:2:64} ;}
function xmlget { xpath="$1"; cat $xml | xmlstarlet sel --text --template --value-of "$xpath" | tr -d '\n' ;}
function xmlset { value="`cat -`"; xpath="$1"; xmlstarlet ed --omit-decl --inplace --update "$xpath" --value "$value" $xml;}
function xmlgetutxo { i=`xmlget "//tx[@type='current']//input[1]/raw[4]"`; xmlget "//tx[@type='previous'][1]//output[@index='$i']/value" ;}
function checkfee { spending=`cat -`; utxo=`xmlgetutxo`; fee=$(($utxo-$spending));
	[[ "$fee" -lt "$FEEMIN" ]] && <<<"ERROR: FEE ($fee satoshis) TOO LOW! (Adjust FEEMIN if you disagree)" errout && exit 1;
	[[ "$fee" -gt "$FEEMAX" ]] && <<<"ERROR: FEE ($fee satoshis) TOO HIGH! (Adjust FEEMAX if you disagree)" errout && exit 1;
        echo $fee
}
function foreachoutput { cat $xml | xmlstarlet sel --template --match "//tx[@type='current']//output" --value-of "position()" --nl ;}
# openssl signing with BIP62 treatment for S values, see https://bitcoin.stackexchange.com/questions/59820/sign-a-tx-with-low-s-value-using-openssl :
function signrawtransactionwithkey { raw=`cat -`; sig=''; for i in {0..999}; do sig=`<<<$raw hex2bin | openssl pkeyutl -inkey ${privatekeyfile} -sign -in - -pkeyopt digest:sha256 | bin2hex`; [[ $sig =~ 022100 ]] || break; done; echo $sig ;}
function verifyrawtransactionwithkey { hex2bin | openssl pkeyutl -inkey ${publickeyfile} -pubin -verify -in - -pkeyopt digest:sha256 -sigfile <(<<<$1 hex2bin) ;}
function wif2priv { hex=`base58 -d | bin2hex`; tmp=${hex:0:68}; [[ "$hex" == "`<<<$tmp appendchecksum`" ]] || <<<"FAILURE: INVALID ADDRESS!" errout; echo -n ${tmp:2:64} ;}
function priv2pem { echo "-----BEGIN EC PRIVATE KEY-----"; <<<"302E0201010420`cat -`a00706052b8104000a" hex2bin | base64; echo "-----END EC PRIVATE KEY-----" ;}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FUNCTIONS^
priv=`<<<$wif wif2priv`
privatekeyfile=`mktemp`; <<<$priv priv2pem >$privatekeyfile
publickeyfile=`mktemp`; openssl ec -in $privatekeyfile -pubout -out $publickeyfile 2>/dev/null || exit 1 

previoustxid=`xmlget "//tx[@type='previous'][1]/txid"`
echo "previoustxid: $previoustxid"
[[ ! $previoustxid =~ ^[0-9a-fA-F]{64}$ ]] && <<<"ERROR: $previoustxid is not a hex representation of 32 bytes" errout && exit 1
<<<$previoustxid toggleendian | xmlset "//tx[@type='current']//input[1]/raw[3]"

address=`xmlget "//tx[@type='previous']//output[1]/address"`
pubkeyhash=`<<<$address addr2pubkeyhash`
echo "outpoint pubkeyhash: $pubkeyhash"
<<<$pubkeyhash xmlset "//tx[@type='current']//input[1]/scriptsig[@iteration='1']/raw[5]"

totalsatoshis=0
for i in `foreachoutput`; do
	targetaddress=`xmlget "//tx[@type='current']//output[$i]/address"`
	nextpubkeyhash=`<<<$targetaddress addr2pubkeyhash`
	echo "nextpubkeyhash: $nextpubkeyhash"
	<<<$nextpubkeyhash xmlset "//tx[@type='current']//output[$i]/raw[6]"
	satoshis=`xmlget "//tx[@type='current']//output[$i]/value"`
	totalsatoshis=$(($totalsatoshis + $satoshis))
	echo "satoshis: $satoshis (`<<<$satoshis dec2hex \"%016x\" | toggleendian`)"
	<<<$satoshis dec2hex "%016x" | toggleendian | xmlset "//tx[@type='current']//output[$i]/raw[1]"
done
echo "totalsatoshis: $totalsatoshis (decimal)"
echo -n "fee: "; <<<$totalsatoshis checkfee || exit 1

rawtransaction=`xmlget "//tx[@type='current']//raw[not(ancestor-or-self::*[@iteration='2'])]"`
echo "rawtransaction: $rawtransaction"

rawtransactionhash=`<<<$rawtransaction sha256 | sha256`
echo "rawtransactionhash: $rawtransactionhash"

signedrawtransaction=`<<<$rawtransactionhash signrawtransactionwithkey`
echo "signedrawtransaction: $signedrawtransaction"

verifytransaction=`<<<$rawtransactionhash verifyrawtransactionwithkey $signedrawtransaction`
<<<"verifytransaction: $verifytransaction" errout

signedrawtransactionlength=`<<<"${signedrawtransaction}01" hexstringlength`
publickey=`openssl ec -in $privatekeyfile -pubout -outform DER 2>/dev/null | tail -c 65 | bin2hex`
[[ "$compressed" == "true" ]] && publickey=`<<<$publickey pub2compressedpub`
echo "publickey: $publickey"
publickeylength=`<<<$publickey hexstringlength`
<<<$signedrawtransactionlength xmlset "//tx[@type='current']//input[1]//scriptsig[@iteration='2']/hex/raw[1]"
<<<$signedrawtransaction xmlset "//tx[@type='current']//input[1]//scriptsig[@iteration='2']/hex/raw[2]"
<<<$publickeylength xmlset "//tx[@type='current']//input[1]//scriptsig[@iteration='2']/hex/raw[4]"
<<<$publickey xmlset "//tx[@type='current']//input[1]//scriptsig[@iteration='2']/hex/raw[5]"

scriptsig=`xmlget "//tx[@type='current']//input[1]//scriptsig[@iteration='2']/hex/raw"`
echo "scriptsig: $scriptsig"
scriptsiglength=`<<<$scriptsig hexstringlength`
<<<$scriptsiglength xmlset "//tx[@type='current']//input[1]//scriptsig[@iteration='2']/raw[1]"

#echo "xml file: (${xml}):"
cat $xml

signedtransaction=`xmlget "//tx[@type='current']//raw[not(ancestor-or-self::*[@iteration='1'])]" | tr 'ABCDEF' 'abcdef'`
txid=`<<<$signedtransaction sha256 | sha256 | toggleendian`
echo "txid: $txid"
printf "signedtransaction: ${GREEN}$signedtransaction${NOCOLOR}\n"
printf "For ${GREEN}verification${NOCOLOR}, paste your signedtransaction into ${GREEN}https://blockchain.com/btc/decode-tx${NOCOLOR} and check if everything looks as you planned.\n"
printf "After verification, paste your signedtransaction into ${GREEN}https://blockchain.com/btc/pushtx${NOCOLOR} to ${GREEN}broadcast${NOCOLOR} it.\n"
printf "Once you have successfully broadcast your tansaction, watch its status on the blockchain: ${GREEN}https://blockchain.com/btc/tx/${txid}${NOCOLOR}.\n"

shred $privatekeyfile; rm $privatekeyfile
shred $publickeyfile; rm $publickeyfile
shred $xml; rm $xml
