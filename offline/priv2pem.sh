#!/bin/bash
# this script generates openssl private key pem file content from the given secret
function hex2bin { cat - | xxd -r -p ;}

priv=`cat -`
#pub=${1:-$(echo -n ${priv} | ./priv2pub.sh 2>/dev/null)}
echo "-----BEGIN EC PRIVATE KEY-----"
#echo -n "30740201010420${priv}a00706052b8104000aa144034200${pub}" | hex2bin.sh | base64
<<<"302E0201010420${priv}a00706052b8104000a" hex2bin | base64
echo "-----END EC PRIVATE KEY-----"
