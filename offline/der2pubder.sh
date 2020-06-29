#!/bin/bash
# this script generates openssl public key DER file content (as hex representation) from the given openssl private key DER file content (as hex representation)
function hex2bin { xxd -r -p ;}
function bin2hex { xxd -p -c 256 | tr -d '\n' ;}

pubder=`openssl ec -inform der -in <(hex2bin) -pubout -outform der -out - 2>/dev/null | bin2hex`
echo "Public key in DER format: --------------------------" >&2
echo "${pubder}" >&2
echo -n "${pubder}"
