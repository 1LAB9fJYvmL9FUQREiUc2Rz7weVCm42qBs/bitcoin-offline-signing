#!/bin/bash
dirname=`dirname $0`
pk=`xargs python $dirname/priv2pub.py`
echo "Public Key : --------------------------------------" >&2
echo $pk >&2
echo -n $pk
