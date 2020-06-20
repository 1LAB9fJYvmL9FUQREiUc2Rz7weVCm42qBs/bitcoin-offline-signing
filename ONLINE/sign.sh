#!/bin/bash
xmlreadonly=${1?"Usage: $0 <xml template file with transaction structure)>"}
xml=`mktemp`; cp $xmlreadonly $xml
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
function wif2priv { hex=`base58 -d | bin2hex`; tmp=${hex%????????}; [[ "$hex" == "`<<<$tmp appendchecksum`" ]] || <<<"FAILURE: INVALID ADDRESS!" errout; echo -n ${tmp:2:64} ;}
function priv2pem { echo "-----BEGIN EC PRIVATE KEY-----"; <<<"302E0201010420`cat -`a00706052b8104000a" hex2bin | base64; echo "-----END EC PRIVATE KEY-----" ;}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FUNCTIONS^

printf "Enter the transaction ID (${GREEN}txid${NOCOLOR}) of the outpoint that you want to spend from"; read -p ": " previoustxid
echo "previoustxid: $previoustxid"
[[ ! $previoustxid =~ ^[0-9a-fA-F]{64}$ ]] && <<<"ERROR: $previoustxid is not a hex representation of 32 bytes" errout && exit 1
<<<$previoustxid xmlset "//tx[@type='previous'][1]/txid"
<<<$previoustxid toggleendian | xmlset "//tx[@type='current']//input[1]/raw[3]"

printf "In order to provide the following data, open you favourite block explorer (e.g. ${GREEN}https://www.blockchain.com/btc/tx/$previoustxid${NOCOLOR}) in your (tor) browser.\n"
printf "Enter the (decimal) output ${GREEN}INDEX${NOCOLOR} of the outpoint that you want to spend from"; read -p ": " outpointindex
outpointindex=`<<<$outpointindex dec2hex "%08x" | toggleendian`
echo "outpoint index: $outpointindex"
<<<$outpointindex xmlset "//tx[@type='previous'][1]//output[1]/@index"
<<<$outpointindex xmlset "//tx[@type='current']//input[1]/raw[4]"

printf "Enter the ${GREEN}bitcoin address${NOCOLOR} (P2PKH format, starts with the letter '1') of the outpoint that you want to spend from"; read -p ": " address
echo "outpoint address: $address"
<<<$address xmlset "//tx[@type='previous']//output[1]/address"
pubkeyhash=`<<<$address addr2pubkeyhash`
echo "outpoint pubkeyhash: $pubkeyhash"
<<<$pubkeyhash xmlset "//tx[@type='previous'][1]//output[1]//raw[4]"
<<<$pubkeyhash xmlset "//tx[@type='current']//input[1]/scriptsig[@iteration='1']/raw[5]"

printf "Enter the ${GREEN}decimal value${NOCOLOR} (in ${GREEN}satoshis${NOCOLOR}) of unspent transaction output (${GREEN}UTXO${NOCOLOR}) of that outpoint"; read -p ": " utxo
echo "outpoint utxo: $utxo"
<<<$utxo xmlset "//tx[@type='previous'][1]//output[@index='$outpointindex']/value"

while
	if [[ -n "`xmlget "//tx[@type='current']//output[1]/address"`" ]]; then
		echo "0) finish!" >&2
		select opt in "add a recipient"; do
  			case ${REPLY} in
    				0) choice="exit"; break;;
    				*) choice="${options[$(( $REPLY - 1 ))]}"; break;;
  			esac
		done
	fi
	[[ ! "$choice" == "exit" ]]
do
	if [[ -n "`xmlget "//tx[@type='current']//output[1]/address"`" ]]; then
		xmlstarlet ed --omit-decl --inplace --append "//tx[@type='current']/outputs/output[last()]" --type elem -n output $xml
		xmlstarlet ed --omit-decl --inplace --update "//tx[@type='current']/outputs/output[last()]" -x "//tx[@type='current']/outputs/output[1]/*" $xml
		xmlstarlet ed --omit-decl --inplace --update "//tx[@type='current']/outputs/output[last()]/address" -v "" $xml
		xmlstarlet ed --omit-decl --inplace --update "//tx[@type='current']/outputs/output[last()]/value" -v "" $xml
	fi
	printf "Enter the ${GREEN}bitcoin address${NOCOLOR} (P2PKH format, starts with the letter '1') of the ${GREEN}recipient${NOCOLOR} that you want to send to"; read -p ": " targetaddress
	echo "[`foreachoutput | wc -w`] recipient address: $targetaddress"
	<<<$targetaddress xmlset "//tx[@type='current']//output[last()]/address"
	printf "Enter the ${GREEN}decimal amount${NOCOLOR} of ${GREEN}satoshis${NOCOLOR} that the recipient should receive"; read -p ": " satoshis
	echo "[`foreachoutput | wc -w`] satoshis: $(($satoshis))"
	<<<$satoshis xmlset "//tx[@type='current']//output[last()]/value"
done

numberofoutputs=`foreachoutput | wc -w`
numberofoutputs=`<<<$numberofoutputs dec2hex`
echo "numberofoutputs: $numberofoutputs"
<<<$numberofoutputs xmlset "//tx[@type='current']//outputs/raw[1]"

totalsatoshis=0
for i in `foreachoutput`; do
	targetaddress=`xmlget "//tx[@type='current']//output[$i]/address"`
	echo "next address: $targetaddress"
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

cat $xml
printf "Above you see the content of xml file: ${GREEN}${xml}${NOCOLOR}\n"
printf "${GREEN}Copy that xml file to your OFFLINE computer (the computer where your private keys are securely stored) for transaction signing with offline/sign.sh${NOCOLOR}\n"
