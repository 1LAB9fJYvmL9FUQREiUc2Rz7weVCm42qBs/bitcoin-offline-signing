#!/bin/bash
#Generate public key hash from (compressed) public key
# pipe in an uncompressed public key(with the 04 byte prefix) or compressed public key (with the 02 or 03 byte prefix), indicating the sign of the public key y component):
#set -x
#################################### FUNCTIONS:
function bin2hex { cat - | xxd -p -c 256 | tr -d '\n' ;}
function hex2bin { cat - | xxd -r -p ;}
function sha256 { hex2bin | openssl dgst --binary --sha256 | bin2hex ;}
function ripemd160 { hex2bin | openssl dgst --binary --ripemd160 | bin2hex ;}
####################################

net=${1:-"00"}
hash=`sha256 | ripemd160`

echo "pubkeyhash: ----------------------------------------" >&2
echo ${hash} >&2
echo -n ${hash}
