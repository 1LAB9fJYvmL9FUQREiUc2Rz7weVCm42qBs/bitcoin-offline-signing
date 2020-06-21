#!/bin/bash
# in a public key DER file, the last 65 bytes would represent the public key. Because we're dealing with the hex representation, we need to double the amount
pub=`tail -c 130`
echo "Public key: ----------------------------------------" >&2
echo "${pub}" >&2
echo -n "${pub}"

