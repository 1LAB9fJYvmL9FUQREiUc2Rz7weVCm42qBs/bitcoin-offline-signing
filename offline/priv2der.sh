#!/bin/bash
# this script generates openssl private key DER file content (as hex representation) from the given secret

priv=`cat -`
echo "Private key in DER format: -------------------------" >&2
echo "302e0201010420${priv}a00706052b8104000a" >&2
echo -n "302e0201010420${priv}a00706052b8104000a"
