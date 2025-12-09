import hashlib
import time
import random
from math import gcd

# ========== Part 1: 简单 POW ==========

def pow_search(nickname: str, prefix: str = "0000"):
    """寻找满足 sha256(nickname + nonce) 以 prefix 开头的 nonce"""
    nonce = 0
    start = time.time()
    while True:
        msg = f"{nickname}{nonce}"
        h = hashlib.sha256(msg.encode("utf-8")).hexdigest()
        if h.startswith(prefix):
            end = time.time()
            print("=== POW 结果 ===")
            print(f"昵称: {nickname}")
            print(f"找到的 nonce: {nonce}")
            print(f"消息: {msg}")
            print(f"SHA256: {h}")
            print(f"耗时: {end - start:.4f} 秒\n")
            return msg, h, nonce
        nonce += 1


# ========== Part 2: 简单 RSA 实现（教学版） ==========

def is_prime(n: int, k: int = 10) -> bool:
    """Miller-Rabin 素数测试（概率性），够作业使用"""
    if n < 2:
        return False
    small_primes = [2, 3, 5, 7, 11, 13, 17, 19, 23]
    if n in small_primes:
        return True
    for p in small_primes:
        if n % p == 0:
            return False

    # 写成 n-1 = 2^r * d 形式
    r, d = 0, n - 1
    while d % 2 == 0:
        r += 1
        d //= 2

    # 随机测试 k 次
    for _ in range(k):
        a = random.randrange(2, n - 2)
        x = pow(a, d, n)
        if x == 1 or x == n - 1:
            continue
        for __ in range(r - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False
    return True


def generate_large_prime(bits: int = 512) -> int:
    """生成大素数"""
    while True:
        # 随机奇数
        candidate = random.getrandbits(bits) | 1 | (1 << (bits - 1))
        if is_prime(candidate):
            return candidate


def generate_rsa_keypair(bits: int = 1024):
    """生成 RSA 公私钥对 (e, n), (d, n)"""
    print("正在生成 RSA 密钥对，请稍等...")
    e = 65537  # 常用公开指数
    while True:
        p = generate_large_prime(bits // 2)
        q = generate_large_prime(bits // 2)
        if p == q:
            continue
        n = p * q
        phi = (p - 1) * (q - 1)
        if gcd(e, phi) == 1:
            # 求 d = e^{-1} mod phi
            d = pow(e, -1, phi)
            break

    public_key = (e, n)
    private_key = (d, n)

    print("=== RSA 密钥对生成完成 ===")
    print(f"公钥 (e, n): e = {e}, n 位数长度 = {n.bit_length()}")
    print(f"私钥 (d, n): d 位数长度 = {d.bit_length()}")
    print()
    return public_key, private_key


# ========== Part 3: 签名 & 验证 ==========

def sha256_int(message: str) -> int:
    """把消息的 sha256 哈希转成整数"""
    h = hashlib.sha256(message.encode("utf-8")).digest()
    return int.from_bytes(h, byteorder="big")


def rsa_sign(message: str, private_key):
    """用私钥对消息做签名：签名的是 sha256(message)"""
    d, n = private_key
    h_int = sha256_int(message)
    signature = pow(h_int, d, n)
    return signature


def rsa_verify(message: str, signature: int, public_key) -> bool:
    """用公钥验证签名"""
    e, n = public_key
    h_int = sha256_int(message)
    # “解密”签名
    h_from_sig = pow(signature, e, n)
    return h_int == h_from_sig


# ========== 主流程 ==========

def main():
    nickname = "Sam"  # 这里改成你的昵称
    # 1. 先做 POW，找到 4 个 0 开头的 hash
    msg, h, nonce = pow_search(nickname, prefix="0000")

    # 2. 生成 RSA 公私钥对
    public_key, private_key = generate_rsa_keypair(bits=1024)

    # 3. 用私钥对 “昵称 + nonce” 这段原始文本签名
    signature = rsa_sign(msg, private_key)
    print("=== 签名结果 ===")
    print(f"待签名消息: {msg}")
    print(f"签名（十进制大整数）: {signature}\n")

    # 4. 用公钥验证签名
    ok = rsa_verify(msg, signature, public_key)
    print("=== 验证结果 ===")
    print("验证通过 ✅" if ok else "验证失败 ❌")


if __name__ == "__main__":
    main()
