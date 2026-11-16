import sys
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

# Allow importing vector_gen from the same tb/ directory
TB_DIR = Path(__file__).resolve().parent
if str(TB_DIR) not in sys.path:
    sys.path.insert(0, str(TB_DIR))

import vector_gen


def hex_to_int(hex_str: str) -> int:
    return int.from_bytes(bytes.fromhex(hex_str), byteorder="big")


def int_to_hex(val: int, byte_len: int = 16) -> str:
    return val.to_bytes(byte_len, byteorder="big").hex()


async def reset_dut(dut):
    """Apply active-high synchronous/asynchronous reset matching aes128_core.v."""
    dut.rst.value = 1
    dut.start.value = 0
    dut.key.value = 0
    dut.data_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_aes128_core_vectors(dut):
    """Drives all generated AES-128 core vectors and verifies ciphertext output."""
    # Start 100 MHz clock (10 ns period)
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    all_vectors = vector_gen.load_vectors()
    core_vectors = all_vectors["core"]
    dut._log.info(f"Loaded {len(core_vectors)} test vectors for aes128_core.")

    for vec in core_vectors:
        name = vec["name"]
        key_int = hex_to_int(vec["key"])
        pt_int = hex_to_int(vec["pt"])
        expected_ct = vec["ct"].lower()

        # Drive inputs and pulse 'start' for 1 clock cycle
        dut.key.value = key_int
        dut.data_in.value = pt_int
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0

        # Wait for 'done' to go high (expected ~12 cycles; 30-cycle timeout safety)
        cycles = 0
        while int(dut.done.value) == 0:
            await RisingEdge(dut.clk)
            cycles += 1
            if cycles > 30:
                raise TimeoutError(f"[{name}] Timed out waiting for 'done' signal.")

        # Read output on the cycle 'done' asserts
        actual_ct = int_to_hex(int(dut.data_out.value), 16)

        assert actual_ct == expected_ct, (
            f"[{name}] Ciphertext mismatch!\n"
            f"  Key      : {vec['key']}\n"
            f"  Plaintext: {vec['pt']}\n"
            f"  Expected : {expected_ct}\n"
            f"  Actual   : {actual_ct}"
        )

        # Wait one idle cycle before starting the next block
        await RisingEdge(dut.clk)

    dut._log.info(f"SUCCESS: All {len(core_vectors)} aes128_core vectors passed!")