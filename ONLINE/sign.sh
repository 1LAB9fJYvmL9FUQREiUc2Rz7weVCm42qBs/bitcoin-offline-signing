#!/bin/bash
xmlreadonly=${1?"Usage: $0 <xml template file with transaction structure)>"}
xml=`mktemp`; cp $xmlreadonly $xml
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
#function signrawtransactionwithkey { raw=`cat -`; sig=''; for i in {0..999}; do sig=`<<<$raw hex2bin | openssl pkeyutl -inkey <(echo ${pem}|hex2bin) -sign -in - -pkeyopt digest:sha256 | bin2hex`; [[ $sig =~ 022100 ]] || break; done; echo $sig ;}
#function verifyrawtransactionwithkey { hex2bin | openssl pkeyutl -keyform DER -inkey <(<<<$der der2pubder|hex2bin) -pubin -verify -in - -pkeyopt digest:sha256 -sigfile <(<<<$1 hex2bin) ;}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FUNCTIONS^

while
	if [[ -n "`xmlget "//txin//output[1]/@address"`" ]]; then
		echo "0) finish!" >&2
		select opt in "add an input (utxo)"; do
  			case ${REPLY} in
    				0) choice="exit"; break;;
    				*) choice="${options[$(( $REPLY - 1 ))]}"; break;;
  			esac
		done
	fi
	[[ ! "$choice" == "exit" ]]
do
	if [[ -n "`xmlget "//txin//output[1]/@address"`" ]]; then
		xmlclonenode "/txs/txin[last()]"
	fi
	current=`xmlforeach "//txin" | wc -w`
	printf "Enter the transaction ID (${GREEN}txid${NOCOLOR}) of the outpoint that you want to spend from"; read -p ": " previoustxid
	echo "[$current] previoustxid: $previoustxid"
	[[ ! $previoustxid =~ ^[0-9a-fA-F]{64}$ ]] && <<<"ERROR: $previoustxid is not a hex representation of 32 bytes" errout && exit 1
	<<<$previoustxid xmlset                "//txin[last()]/descendant::raw[1]/@id"
	<<<$previoustxid toggleendian | xmlset "//txin[last()]/descendant::raw[1]"

	printf "In order to provide the following data, open you favourite block explorer (e.g. ${GREEN}https://www.blockchain.com/btc/tx/$previoustxid${NOCOLOR}) in your (tor) browser.\n"
	printf "Enter the (decimal) output ${GREEN}INDEX${NOCOLOR} of the outpoint that you want to spend from"; read -p ": " outpointindex
	outpointindex=`<<<$outpointindex dec2hex "%08x" | toggleendian`
	echo "[$current] outpoint index: $outpointindex"
	<<<$outpointindex xmlset "//txin[last()]//output[1]/descendant::raw[1]"

	printf "Enter the ${GREEN}bitcoin address${NOCOLOR} (P2PKH format, starts with the letter '1') of the outpoint that you want to spend from"; read -p ": " address
	echo "[$current] outpoint address: $address"
	<<<$address xmlset "//txin[last()]//output[1]/@address"
	pubkeyhash=`<<<$address addr2pubkeyhash`
	echo "[$current] outpoint pubkeyhash: $pubkeyhash"
	<<<$pubkeyhash xmlset "//txin[last()]//output[1]/descendant::raw[6]"

	printf "Enter the ${GREEN}decimal value${NOCOLOR} (in ${GREEN}satoshis${NOCOLOR}) of unspent transaction output (${GREEN}UTXO${NOCOLOR}) of that outpoint"; read -p ": " utxo
	echo "[$current] outpoint utxo: $utxo"
	<<<$utxo xmlset "//txin[last()]//output[1]/@value"
done

numberofinputs=`xmlforeach "//txin//output" | wc -w | dec2hex`
echo "numberofinputs: $numberofinputs"
<<<$numberofinputs xmlset "//txs/raw[2]"

while
	choice=''
	if [[ -n "`xmlget "//txout//output[1]/@address"`" ]]; then
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
	if [[ -n "`xmlget "//txout//output[1]/@address"`" ]]; then
		xmlclonenode "//txout/outputs/output[last()]"
	fi
	current=`xmlforeach "//txout//output" | wc -w`
	printf "Enter the ${GREEN}bitcoin address${NOCOLOR} (P2PKH format, starts with the letter '1') of the ${GREEN}recipient${NOCOLOR} that you want to send to"; read -p ": " targetaddress
	echo "[$current] recipient address: $targetaddress"
	<<<$targetaddress xmlset "//txout//output[last()]/@address"
	nextpubkeyhash=`<<<$targetaddress addr2pubkeyhash`
	echo "[$current] nextpubkeyhash: $nextpubkeyhash"
	<<<$nextpubkeyhash xmlset "//txout//output[last()]/descendant::raw[6]"
	printf "Enter the ${GREEN}decimal amount${NOCOLOR} of ${GREEN}satoshis${NOCOLOR} that the recipient should receive"; read -p ": " satoshis
	echo "[$current] satoshis: $(($satoshis))"
	<<<$satoshis xmlset "//txout//output[last()]/@value"
	<<<$satoshis dec2hex "%016x" | toggleendian | xmlset "//txout//output[last()]/descendant::raw[1]"
done

numberofoutputs=`xmlforeach "//txout//output" | wc -w`
numberofoutputs=`<<<$numberofoutputs dec2hex`
echo "numberofoutputs: $numberofoutputs"
<<<$numberofoutputs xmlset "//txout//outputs/descendant::raw[1]"

totalsatoshis=0
for i in `xmlforeach "//txout//output"`; do
	satoshis=`xmlget "//txout//output[$i]/@value"`
	totalsatoshis=$(($totalsatoshis + $satoshis))
done
echo "totalsatoshis: $totalsatoshis (decimal)"
fee=`<<<$totalsatoshis checkfee || exit 1`
echo "fee: $fee"

rawtransaction=`xmlget "//raw[not(ancestor::scriptsig)]"`
echo "rawtransaction: $rawtransaction"

rawtransactionhash=`<<<$rawtransaction sha256 | sha256`
echo "rawtransactionhash: $rawtransactionhash"

cat $xml
cat $xml | common/xml2qr.sh dark
printf "Above you see the content of xml file: ${GREEN}${xml}${NOCOLOR}, as text and as a QR code.\n"
printf "${GREEN}In order to transfer the xml file, copy it using a USB drive or: scan the QR code with your OFFLINE computer and decode the result with script common/qr2xml.sh${NOCOLOR}\n"
printf "${GREEN}Then, sign the transaction offline with the corresponding private keys and the script offline/sign.sh${NOCOLOR}\n"
