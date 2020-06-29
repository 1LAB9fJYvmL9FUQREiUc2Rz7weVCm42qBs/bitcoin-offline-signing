import binascii
import struct
import sys

# code taken from user1658887's answer at: https://bitcoin.stackexchange.com/questions/25024/how-do-you-get-a-bitcoin-public-key-from-a-private-key

def sk_to_pk(sk):
    """
    Derive the public key of a secret key on the secp256k1 curve.

    Args:
        sk: An integer representing the secret key (also known as secret
          exponent).

    Returns:
        A coordinate (x, y) on the curve repesenting the public key
          for the given secret key.

    Raises:
        ValueError: The secret key is not in the valid range [1,N-1].
    """
    # base point (generator)
    G = (0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798,
         0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8)

    # field prime
    P = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F

    # order
    N = (1 << 256) - 0x14551231950B75FC4402DA1732FC9BEBF

    # check if the key is valid
    if not(0 < sk < N):
        msg = "{} is not a valid key (not in range [1, {}])"
        raise ValueError(msg.format(hex(sk), hex(N-1)))

    # addition operation on the elliptic curve
    # see: https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Point_addition
    # note that the coordinates need to be given modulo P and that division is
    # done by computing the multiplicative inverse, which can be done with
    # x^-1 = x^(P-2) mod P using fermat's little theorem (the pow function of
    # python can do this efficiently even for very large P)
    def add(p, q):
        px, py = p
        qx, qy = q
        if p == q:
            lam = (3 * px * px) * pow(2 * py, P - 2, P)
        else:
            lam = (qy - py) * pow(qx - px, P - 2, P)
        rx = lam**2 - px - qx
        ry = lam * (px - rx) - py
        return rx % P, ry % P

    # compute G * sk with repeated addition
    # by using the binary representation of sk this can be done in 256
    # iterations (double-and-add)
    ret = None
    for i in xrange(256):
        if sk & (1 << i):
            if ret is None:
                ret = G
            else:
                ret = add(ret, G)
        G = add(G, G)

    return ret

if len(sys.argv) >= 2:
    sk = long(sys.argv[1], 16)
else:
    raise ValueError('Please provide the private key in hex format as a 1st parameter')

pk = sk_to_pk(sk)
pkx, pky = pk
ybyte=0x02 if pky % 2 == 0 else 0x03    # can be used when a compressed pubkey is desired
hexpk = "%s%s%s" % ("04",hex(pkx),hex(pky)) # 04 indicates that an uncompressed pubkey is desired
print (hexpk.replace("0x","",2).replace("L","",2));
