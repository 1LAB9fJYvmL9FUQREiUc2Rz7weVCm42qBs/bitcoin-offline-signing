#!/bin/bash
# create ECDSA public key from private key
# code originally taken from user1658887's answer at: https://bitcoin.stackexchange.com/questions/25024/how-do-you-get-a-bitcoin-public-key-from-a-private-key
# converted to bash code (requires bc) by lordlezehaf / 1LAB9fJYvmL9FUQREiUc2Rz7weVCm42qBs 

#set -x
sk=`cat - | tr abcdef ABCDEF`

# base point (generator)
Gx=79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
Gy=483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
# field prime
P=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
# order
#N=$(( (1 << 256) - 0x14551231950B75FC4402DA1732FC9BEBF))

# ****************************
# bc calculates with long ints
# if not present, install with: sudo apt install bc
# ***************************
function calc() {
  formula=$1
  ibase=${2:-"G"}
  obase=${3:-"G"}
  BC_LINE_LENGTH=999 bc<<< "ibase=${ibase};obase=${obase};$formula" | sed 's/ //g'
}

# ****************************
# Modular exponentiation
# ***************************
function pow() {
  x=$1		# long x
  y=$2		# long y
  p=$3		# long modulo
  res=1      # Initialize result  
  
  x=$(calc "$x % $p")  # Update x if it is more than or equal to p 
   
  [[ "$x" == "0" ]] && echo 00 # In case x is divisible by p; 
  
  while [ ! "$y" == "0" ]; do  
	[[ $(calc "$y % 2") -ne 0 ]] && res=$(calc "$res * $x % $p")  
  
	y=$(calc "$y / 2") 	# y = y/2  
	x=$(calc "$x*$x % $p")  
  done
  echo $res  
} 

# ****************************
    # addition operation on the elliptic curve
    # see: https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Point_addition
    # note that the coordinates need to be given modulo P and that division is done by computing the multiplicative inverse, 
    # which can be done with x^-1 = x^(P-2) mod P using fermat's little theorem (even for very large P)
# ***************************
function add() {
  px=$1
  py=$2
  qx=$3
  qy=$4
  lam=1
  if [ "$px" == "$qx"  -a  "$py" == "$qy" ]; then
    lam=`pow $(calc "2*$py") $(calc "$P-2") $P`
    lam=$(calc "3 * $px*$px * $lam")
  else
    lam=`pow $(calc "$qx-($px)") $(calc "$P-2") $P`
    lam=$(calc "($qy-($py)) * $lam")
  fi
  rx=$(calc "$lam * $lam - ($px) - ($qx)")
  ry=$(calc "$lam * ($px-($rx)) - ($py)")
  echo $(calc "$rx%$P"),$(calc "$ry%$P")
}

# ****************************
# progress bar
# ****************************
function progressstep() {
        step=$1
        max=$2
        char=${3:-"<"}
        echo -n $' \r'; for j in `seq 1 $(($max-$step))`; do echo -n "$char"; done 
	echo -ne " [$((($max-$step)*100/$max))% left]  \x08\x08"
}

# ****************************
# main:
# ****************************
pkx=0
pky=0
for i in {0..255}; do
  xi=`calc $i A G`
  #echo $xi
  #echo "$sk % 2^($xi+1) - $sk % 2^$xi"
  if [ ! $(calc "$sk % 2^($xi+1) - $sk % 2^$xi") == "0" ]; then
    if [ "$pkx" == "0"  -a  "$pky" == "0" ]; then
      pkx=$Gx
      pky=$Gy
    else
      tmp=`add $pkx $pky $Gx $Gy`
      pkx=`echo $tmp | cut -d, -f1`
      pky=`echo $tmp | cut -d, -f2`
    fi
  fi
  tmp=`add $Gx $Gy $Gx $Gy`
  Gx=`echo $tmp | cut -d, -f1`
  Gy=`echo $tmp | cut -d, -f2`
  (progressstep $i 255) >&2
done

#ybyte=`calc "2 + $pky%2"`
#echo -n "0$ybyte"; calc $pkx
echo $'\nPublic Key: ---------------------------------------' >&2
echo -n '04' >&2
calc $pkx | xargs echo -n >&2
calc $pky | xargs echo >&2
echo -n '04'
calc $pkx | xargs echo -n
calc $pky | xargs echo -n

