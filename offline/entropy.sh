#!/bin/bash
#set -x
#################################### FUNCTIONS:
declare -r ORANGE='\033[1;33m'
declare -r NOCOLOR='\033[0m'
function errout { O=$(<<<$ORANGE sed 's/\\/\\\\/g'); NC=$(<<<$NOCOLOR sed 's/\\/\\\\/g'); cat - | sed -E "s/(failure|error)/${O}\\1${NC}/i" | xargs -0 -n1 -I{} printf {} 1>&2 ;}
function bin2hex { cat - | xxd -p -c 256 | tr -d '\n' ;}
####################################

bits=${1:-256}
entropy_max=`cat /proc/sys/kernel/random/entropy_avail`
[[ $entropy_max -lt $bits ]] && <<<"ERROR: Linux System Entropy too low: $entropy_max" errout && exit 1

bytes=$(( ${bits} / 8 ))
entropy=`cat /dev/random | head -c ${bytes} | bin2hex`
echo -n $entropy
