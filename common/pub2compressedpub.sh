#!/bin/bash
pub=`cat -`
pubc=`echo -n ${pub:(-1)} | tr 02468aAcCeE 2 | tr 13579bBdDfF 3 | xargs -n1 -I{} echo -n 0{}${pub:2:64}`
echo "Public Key (compressed): --------------------------" 1>&2
echo $pubc 1>&2
echo -n $pubc
