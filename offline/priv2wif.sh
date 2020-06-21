#!/bin/bash
#Wallet Import Format (WIF)
#WIF (Wallet Import Format) representation of private key: uses base58Check encoding, decreasing the chance of misreading or mistyping.
#set -x
#################################### FUNCTIONS:
function bin2hex { xxd -p -c 256 | tr -d '\n' ;}
function hex2bin { xxd -r -p ;}
function sha256 { hex2bin | openssl dgst --binary --sha256 | bin2hex ;}
function appendchecksum() { hex=`cat -`; echo -n $hex; <<<$hex sha256 | sha256 | head -c 8 ;}
####################################

# 80==MAINNET; EF=TESTNET:
net=${1:-"80"}
compression=${2-"01"}
dirname=`dirname $0`
sk=`cat -`
    #1. .................................................................. Take (or generate) a 256bit private key:
[[ -z ${sk} ]] && sk=`$dirname/entropy.sh 256`
echo "Private key: ---------------------------------------" >&2
echo "$sk" >&2

    #2. .................................................................. Add a 0x80 byte in front of it for mainnet addresses or 0xef for testnet addresses.
nnsk="${net}${sk}"

    #3. .................................................................. Append a 0x01 byte after it if it should be used with compressed public keys. Nothing is appended if it is used with uncompressed public keys.
nnsknn="${nnsk}${compression}"

    #4. .................................................................. Append checksum:
nnsknncccccccc=`<<<${nnsknn} appendchecksum`

    #5. .................................................................. Convert the result from a byte string into a Base58 string:
echo "Private WIF: ---------------------------------------" >&2
<<<${nnsknncccccccc} hex2bin | base58 | xargs echo >&2
<<<${nnsknncccccccc} hex2bin | base58

