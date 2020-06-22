#!/bin/bash
#set -x
#################################### FUNCTIONS:
declare -r ORANGE='\033[1;33m'
declare -r NOCOLOR='\033[0m'
function errout { O=$(<<<$ORANGE sed 's/\\/\\\\/g'); NC=$(<<<$NOCOLOR sed 's/\\/\\\\/g'); cat - | sed -E "s/(failure|error)/${O}\\1${NC}/i" | xargs -0 -n1 -I{} printf {} 1>&2 ;}
function bin2hex { cat - | xxd -p -c 256 | tr -d '\n' ;}
function mixor {
        local e=`cat`
        local ae=${1:-"00000000"}
        local o=`echo $((0x${e:0:8} ^ 0x${ae:0:8})) | xargs printf '00000000%0x'`
        echo -n ${o:(-8)}
        [[ $e =~ .{9} ]] && <<<${e:8} mixor ${ae:8}
}
####################################

bits=${1:-256}
additionalentropy=${2}

entropy_max=`cat /proc/sys/kernel/random/entropy_avail`
[[ $entropy_max -lt $bits ]] && <<<"ERROR: Linux System Entropy too low: $entropy_max" errout && exit 1

bytes=$(( ${bits} / 8 ))
entropy=`cat /dev/random | head -c ${bytes} | bin2hex`
if [ -n "$additionalentropy" ]; then
	echo "System Entropy: ------------------------------------" >&2
	echo $entropy >&2
	entropy=`echo -n $entropy | mixor ${additionalentropy}`
	echo "Entropy: -------------------------------------------" >&2
	echo $entropy >&2
fi
echo -n $entropy
