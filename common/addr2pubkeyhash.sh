#!/bin/bash
#set -x
#Generate pubkeyhash from address
#################################### FUNCTIONS:
declare -r ORANGE='\033[1;33m'
declare -r NOCOLOR='\033[0m'
function errout { O=$(<<<$ORANGE sed 's/\\/\\\\/g'); NC=$(<<<$NOCOLOR sed 's/\\/\\\\/g'); cat - | sed -E "s/(failure|error)/${O}\\1${NC}/i" | xargs -0 -n1 -I{} printf {} 1>&2 ;}
function bin2hex { cat - | xxd -p -c 256 | tr -d '\n' ;}
function hex2bin { cat - | xxd -r -p ;}
function sha256 { echo -n $1 | hex2bin | openssl dgst --binary -sha256 | bin2hex ;}
####################################

addr=`cat -`

# decode the WIF private key with base58:
nnhashcccccccc=`echo -n ${addr} | base58 -d | bin2hex`

# remove the 4 checksum bytes:
nnhash=${nnhashcccccccc%????????}

#A0=`addchecksum ${a1}`
# validate the checksum:
nnhashCCCCCCCC=`<<<$nnhash appendchecksum`
[[ "${nnhashcccccccc}" == "${nnhashCCCCCCCC}" ]] || <<<"Checksum verification FAILURE: ${nnhashcccccccc} != ${nnhashCCCCCCCC}" errout

# remove the net prefix (0x00 MAINNET) (TESTNET would be 0x6F):
hash=${nnhash:2}

echo "BTC pubkeyhash: ------------------------------------" >&2
echo ${hash} >&2
echo -n ${hash}

