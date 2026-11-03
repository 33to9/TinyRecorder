#!/usr/bin/env python3
"""
Sparkle EdDSA utility — generate keypair / sign files (pure Python, no deps).

Sparkle 2 uses standard RFC 8032 Ed25519:
  - public key string  = base64(32-byte public key)
  - private key string = base64(seed(32) || public(32))  (64 bytes total)
  - sparkle:edSignature = base64(64-byte detached signature over file bytes)

Usage:
  python3 sparkle_eddsa.py genkey                 # prints private + public key strings
  python3 sparkle_eddsa.py sign <priv> <file>     # prints base64 edSignature
  python3 sparkle_eddsa.py selftest               # verify against RFC 8032 test vectors
"""
import base64
import hashlib
import os
import sys

# ---------- ed25519 reference implementation (RFC 8032) ----------
p = 2**255 - 19
q = 2**252 + 27742317777372353535851937790883648493


def _inv(x):
    return pow(x, p - 2, p)


_d = -121665 * _inv(121666) % p
_I = pow(2, (p - 1) // 4, p)


def _xrecover(y):
    xx = (y * y - 1) * _inv(_d * y * y + 1)
    x = pow(xx, (p + 3) // 8, p)
    if (x * x - xx) % p != 0:
        x = (x * _I) % p
    if x % 2 != 0:
        x = p - x
    return x


_By = 4 * _inv(5) % p
_Bx = _xrecover(_By)
_B = (_Bx % p, _By % p, 1, _Bx * _By % p)  # extended homogeneous coords
_ident = (0, 1, 1, 0)


def _edwards_add(P, Q):
    x1, y1, z1, t1 = P
    x2, y2, z2, t2 = Q
    a = (y1 - x1) * (y2 - x2) % p
    b = (y1 + x1) * (y2 + x2) % p
    c = t1 * 2 * _d * t2 % p
    dd = z1 * 2 * z2 % p
    e = b - a
    f = dd - c
    g = dd + c
    h = b + a
    return (e * f % p, g * h % p, f * g % p, e * h % p)


def _scalarmult(P, e):
    if e == 0:
        return _ident
    Q = _scalarmult(P, e // 2)
    Q = _edwards_add(Q, Q)
    if e & 1:
        Q = _edwards_add(Q, P)
    return Q


def _encodepoint(P):
    x, y, z, t = P
    zi = _inv(z)
    x = x * zi % p
    y = y * zi % p
    bits = y | ((x & 1) << 255)
    return bits.to_bytes(32, "little")


def _encodeint(n):
    return n.to_bytes(32, "little")


def _decodeint(s):
    return int.from_bytes(s, "little")


def _expand_seed(seed):
    h = hashlib.sha512(seed).digest()
    a = 2**254 + (_decodeint(h[:32]) & (2**254 - 8))
    return h, a


def public_from_seed(seed):
    _, a = _expand_seed(seed)
    return _encodepoint(_scalarmult(_B, a))


def sign_with_seed(seed, msg):
    h, a = _expand_seed(seed)
    r = _decodeint(hashlib.sha512(h[32:] + msg).digest()) % q
    R = _scalarmult(_B, r)
    A = _encodepoint(_scalarmult(_B, a))
    S = (r + _decodeint(hashlib.sha512(_encodepoint(R) + A + msg).digest()) * a) % q
    return _encodepoint(R) + _encodeint(S)


def _point_decode(s):
    if len(s) != 32:
        raise ValueError("point must be 32 bytes")
    y = int.from_bytes(s, "little")
    sign = y >> 255
    y &= (1 << 255) - 1
    x = _xrecover(y)
    if (x & 1) != sign:
        x = p - x
    return (x, y, 1, x * y % p)


def verify(pub_bytes, msg, sig_bytes):
    """Verify a detached Ed25519 signature (RFC 8032, non-cofactor form)."""
    if len(sig_bytes) != 64 or len(pub_bytes) != 32:
        return False
    R = sig_bytes[:32]
    S = _decodeint(sig_bytes[32:])
    if S >= q:
        return False
    A = _point_decode(pub_bytes)
    R_pt = _point_decode(R)
    h = _decodeint(hashlib.sha512(R + pub_bytes + msg).digest()) % q
    lhs = _scalarmult(_B, S)
    rhs = _edwards_add(R_pt, _scalarmult(A, h))
    return _encodepoint(lhs) == _encodepoint(rhs)


# ---------- Sparkle helpers ----------

def genkey():
    seed = os.urandom(32)
    pub = public_from_seed(seed)
    priv = base64.b64encode(seed + pub).decode()
    pub_s = base64.b64encode(pub).decode()
    return priv, pub_s


def sign(priv_str, path):
    if priv_str == "-":
        priv_str = os.environ.get("SPARKLE_PRIVATE_KEY", "")
    raw = base64.b64decode(priv_str)
    assert len(raw) == 64, "private key must be 64 bytes (seed||pub)"
    seed = raw[:32]
    with open(path, "rb") as f:
        msg = f.read()
    return base64.b64encode(sign_with_seed(seed, msg)).decode()


def selftest():
    # RFC 8032 §7.1 test vectors (verified values)
    vectors = [
        ("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60",
         "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
         b"",
         "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e06522490155"
         "5fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b"),
        ("4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb",
         "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
         bytes([0x72]),
         "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da"
         "085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00"),
    ]
    for i, (seed_hex, pub_hex, msg, sig_hex) in enumerate(vectors):
        seed = bytes.fromhex(seed_hex)
        pub = public_from_seed(seed)
        sig = sign_with_seed(seed, msg)
        assert pub.hex() == pub_hex, f"v{i+1} pub mismatch: {pub.hex()}"
        assert sig.hex() == sig_hex, f"v{i+1} sig mismatch: {sig.hex()}"
        print(f"vector {i+1}: OK")
    print("selftest passed")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "genkey":
        priv, pub = genkey()
        print(f"PRIVATE_KEY={priv}")
        print(f"PUBLIC_KEY={pub}")
    elif cmd == "sign" and len(sys.argv) == 4:
        print(sign(sys.argv[2], sys.argv[3]))
    elif cmd == "verify" and len(sys.argv) == 5:
        pub = base64.b64decode(sys.argv[2])
        sig = base64.b64decode(sys.argv[3])
        with open(sys.argv[4], "rb") as f:
            msg = f.read()
        print("PASS" if verify(pub, msg, sig) else "FAIL")
        sys.exit(0 if verify(pub, msg, sig) else 1)
    elif cmd == "selftest":
        selftest()
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
