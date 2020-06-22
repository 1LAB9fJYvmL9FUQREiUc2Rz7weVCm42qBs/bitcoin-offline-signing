#!/bin/bash
#set -x
priv=`cat -`
dirname=`dirname $0`
#pk=`python $dirname/priv2pub.py $priv | sed 's/0x//g' | tr -d 'L' | xargs -I{} echo 04{}`
pk=`python $dirname/priv2pub.py $priv | sed -e's/0x//g' -e's/L//g' | xargs -I{} echo 04{}`
echo "Public Key : --------------------------------------" >&2
echo $pk >&2
echo -n $pk
