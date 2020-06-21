#!/bin/bash
#reverse WIF creation process: base58 decode and remove the padding.
#set -x
#################################### FUNCTIONS:
declare -r ORANGE='\033[1;33m'
declare -r NOCOLOR='\033[0m'
function errout { O=$(<<<$ORANGE sed 's/\\/\\\\/g'); NC=$(<<<$NOCOLOR sed 's/\\/\\\\/g'); cat - | sed -E "s/(failure|error)/${O}\\1${NC}/i" | xargs -0 -n1 -I{} printf {} 1>&2 ;}
function bin2hex { xxd -p -c 256 | tr -d '\n' ;}
function hex2bin { xxd -r -p ;}
function sha256 { hex2bin | openssl dgst --binary --sha256 | bin2hex ;}
function appendchecksum() { hex=`cat -`; echo -n $hex; <<<$hex sha256 | sha256 | head -c 8 ;}
####################################

wif=`cat -`

    #1. Take the WIF private key and decode it with base58:
nnsknncccccccc=`<<<${wif} base58 -d | bin2hex`

    #2. Remove the four checksum bytes from the end of the extended key:
nnsknn=${nnsknncccccccc%????????}

    #3. Validate checksum:
nnsknncccccccc1=`<<<${nnsknn} appendchecksum`

[[ "${nnsknncccccccc}" == "${nnsknncccccccc1}" ]] || <<<"WARNING: Checksum verification FAILURE: ${nnsknncccccccc} != ${nnsknncccccccc1}" errout

    #4. Remove 0x01 byte suffix (compression) if existing:
nnsk=${nnsknn:0:66}

    #5. Remove MAINNET (0x80) or TESTNET (0xEF) byte prefix
sk=${nnsk:2}

echo "Private key: ---------------------------------------" 1>&2
echo "$sk" 1>&2
echo -n ${sk}

