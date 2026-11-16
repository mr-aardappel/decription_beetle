import json
import os
from pathlib import Path
from typing import Any, Dict, List

from cryptography.hazmat.primitives import cmac
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

TB_DIR = Path(__file__).resolve().parent
VECTORS_FILE = TB_DIR / "test_vectors.json"


# -------------------------------------------------------------------------
# Golden Reference Cryptographic Functions (via OpenSSL/cryptography)
# -------------------------------------------------------------------------
def ref_aes128_ecb(key: bytes, plaintext: bytes) -> bytes:
    cipher = Cipher(algorithms.AES(key), modes.ECB())
    encryptor = cipher.encryptor()
    return encryptor.update(plaintext) + encryptor.finalize()


def ref_aes128_ctr(key: bytes, iv: bytes, plaintext: bytes) -> bytes:
    cipher = Cipher(algorithms.AES(key), modes.CTR(iv))
    encryptor = cipher.encryptor()
    return encryptor.update(plaintext) + encryptor.finalize()


def ref_aes128_cmac(key: bytes, message: bytes) -> bytes:
    c = cmac.CMAC(algorithms.AES(key))
    c.update(message)
    return c.finalize()


# -------------------------------------------------------------------------
# Vector Builders (100% Dynamically Generated)
# -------------------------------------------------------------------------
def build_core_vectors(num_vectors: int) -> List[Dict[str, str]]:
    vectors = []
    for i in range(num_vectors):
        key = os.urandom(16)
        pt = os.urandom(16)
        ct = ref_aes128_ecb(key, pt)
        vectors.append({
            "name": f"CORE_{i}",
            "key": key.hex(),
            "pt": pt.hex(),
            "ct": ct.hex(),
        })
    return vectors


def build_ctr_vectors(num_vectors: int) -> List[Dict[str, Any]]:
    vectors = []
    for i in range(num_vectors):
        key = os.urandom(16)
        iv = os.urandom(16)
        # Multi-block payloads between 1 and 8 blocks (16 to 128 bytes)
        num_blocks = (i % 8) + 1
        pt = os.urandom(num_blocks * 16)
        ct = ref_aes128_ctr(key, iv, pt)
        vectors.append({
            "name": f"CTR_{i}",
            "key": key.hex(),
            "iv": iv.hex(),
            "pt": pt.hex(),
            "ct": ct.hex(),
            "num_blocks": num_blocks,
        })
    return vectors


def build_cmac_vectors(num_vectors: int) -> List[Dict[str, Any]]:
    vectors = []
    for i in range(num_vectors):
        key = os.urandom(16)
        # Sweeps message lengths from 0 bytes up to 64 bytes (covers empty, partial, and multi-block)
        byte_len = i % 65
        msg = os.urandom(byte_len)
        tag = ref_aes128_cmac(key, msg)
        vectors.append({
            "name": f"CMAC_{i}_len{byte_len}",
            "key": key.hex(),
            "msg": msg.hex(),
            "byte_len": byte_len,
            "tag": tag.hex(),
        })
    return vectors


# -------------------------------------------------------------------------
# Entry Points for run_tests.py and cocotb Testbenches
# -------------------------------------------------------------------------
def generate_all_vectors(num_random: int = 50, output_path: Path = VECTORS_FILE) -> Dict[str, Any]:
    data = {
        "core": build_core_vectors(num_random),
        "ctr": build_ctr_vectors(num_random),
        "cmac": build_cmac_vectors(num_random),
    }
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    return data


def load_vectors(input_path: Path = VECTORS_FILE) -> Dict[str, Any]:
    if not input_path.exists():
        return generate_all_vectors(output_path=input_path)
    with open(input_path, "r", encoding="utf-8") as f:
        return json.load(f)


if __name__ == "__main__":
    vecs = generate_all_vectors(num_random=10)
    print(f"Saved vectors to {VECTORS_FILE}")
    for k, v in vecs.items():
        print(f"  {k}: {len(v)} vectors")