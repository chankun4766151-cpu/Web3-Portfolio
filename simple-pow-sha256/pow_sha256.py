import hashlib
import time


# ===== 在这里把昵称改成你自己的 =====
NICKNAME = "Sam"  # 比如改成 "ChenKun" 或你的英文/网名


def mine(target_prefix: str):
    """
    不断尝试 NICKNAME + nonce 做 sha256，直到 hash 以 target_prefix 开头
    打印耗时、内容和 hash 值
    """
    nonce = 0
    start = time.perf_counter()

    while True:
        content = f"{NICKNAME}{nonce}"
        hash_hex = hashlib.sha256(content.encode("utf-8")).hexdigest()

        if hash_hex.startswith(target_prefix):
            elapsed = time.perf_counter() - start
            print("====================================")
            print(f"目标前缀        : {target_prefix}")
            print(f"耗时（秒）      : {elapsed:.6f}")
            print(f"nonce          : {nonce}")
            print(f"Hash 内容      : {content}")
            print(f"Hash 值 (hex)  : {hash_hex}")
            print("====================================\n")
            return nonce, content, hash_hex, elapsed

        nonce += 1


def main():
    # 先找到前 4 个 0 的 hash
    print("开始挖掘：前缀 0000")
    mine("0000")

    # 再重新开始挖掘前 5 个 0 的 hash
    print("开始挖掘：前缀 00000")
    mine("00000")


if __name__ == "__main__":
    main()
