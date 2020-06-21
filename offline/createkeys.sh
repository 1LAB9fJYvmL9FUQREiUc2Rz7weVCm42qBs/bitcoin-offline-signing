#!/bin/bash
# based on the 32-byte string piped into this script it will:
# - create the bitcoin private key in WIF (wallet input format)
# - convert back from WIF to the private key (hex string)
# - create the private key in DER format (readable by openssl) (as hex string)
# - create the public key in DER format (readable by openssl) (as hex string)
# - extract the public key from the openssl public key
# - convert the public key to a compressed public key
# - create the public key hash from the compressed public key
# - create the bitcoin address from the public key hash
# ######################################################################################### FUNCTIONS:
declare -r FEEMIN=5000
declare -r FEEMAX=12000
declare -r GREEN='\033[1;32m'
declare -r ORANGE='\033[1;33m'
declare -r NOCOLOR='\033[0m'
function errout {
        G=$(<<<$GREEN sed 's/\\/\\\\/g');
        O=$(<<<$ORANGE sed 's/\\/\\\\/g');
        NC=$(<<<$NOCOLOR sed 's/\\/\\\\/g');
        cat - \
        | sed -E "s/(failure|error)/${O}\\1${NC}/i" \
        | sed -E "s/(success)/${G}\\1${NC}/i" \
        | xargs -0 -n1 -I{} printf {} >&2
}
function priv2pub {
	method=${1:-"openssl"}
        case ${method} in
                "openssl")
			${dirname}/priv2der.sh \
			| ${dirname}/der2pubder.sh \
			| ${dirname}/../common/pubder2pub.sh
		;;
                "python")
			${dirname}/python/priv2pub.sh
		;;
                "bash")
			${dirname}/bash/priv2pub.sh
		;;
        esac
}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ /FUNCTIONS^

echo "Enter your 32-byte secret as a hex string and press ctrl-d when you're done (ignore this message if you've piped the byte string through STDIN)"
secret=`cat -`
[[ ! $secret =~ ^[0-9a-fA-F]{64}$ ]] && <<<"ERROR: $secret is not a hex representation of 32 bytes" errout && exit 1
pubkeycreationmethod=${1:-"openssl"}
dirname=`dirname $0`

<<<$secret $dirname/priv2wif.sh \
| ${dirname}/wif2priv.sh \
| priv2pub ${pubkeycreationmethod} \
| ${dirname}/../common/pub2compressedpub.sh \
| ${dirname}/../common/pub2pubkeyhash.sh \
| ${dirname}/../common/pubkeyhash2addr.sh \

exit









| ${dirname}/priv2der.sh \
| ${dirname}/der2pubder.sh \
| ${dirname}/../common/pubder2pub.sh \
