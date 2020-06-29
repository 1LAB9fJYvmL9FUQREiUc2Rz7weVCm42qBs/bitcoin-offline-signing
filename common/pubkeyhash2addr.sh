#!/bin/bash
#Generate BTC address from public key hash
#set -x
#################################### FUNCTIONS:
function bin2hex { cat - | xxd -p -c 256 | tr -d '\n' ;}
function hex2bin { cat - | xxd -r -p ;}
function sha256 { hex2bin | openssl dgst --binary --sha256 | bin2hex ;}
function appendchecksum() { hex=`cat -`; echo -n $hex; <<<$hex sha256 | sha256 | head -c 8 ;}
####################################

net=${1:-"00"}
# add a prefix of 0x00 (BTC/MAINNET/P2PKH) or 0x05 (BTC/MAINNET/P2SH) or 0x6F (TESTNET/P2PKH) or 0x30 (LiteCoin/MAINNET/P2PKH):
nnhash="${net}`cat -`"

# Append the checksum bytes:
nnhashcccccccc=`<<<${nnhash} appendchecksum`

# Convert the result using Base58Check encoding.
addr=`<<<${nnhashcccccccc} hex2bin | base58`
echo "BTC Address: ---------------------------------------" >&2
echo ${addr} >&2
echo -n ${addr}
