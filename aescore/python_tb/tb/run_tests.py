import os
import sys
import traceback
from pathlib import Path
from cocotb.runner import get_runner

# Ensure the tb directory is on sys.path so cocotb and vector_gen can be imported
TB_DIR = Path(__file__).resolve().parent
RTL_DIR = TB_DIR.parent / "rtl"
sys.path.insert(0, str(TB_DIR))

import vector_gen  # Will be created in the next step

# Shared core Verilog sources needed by all upper-level modules
# Note: Adjust filenames if SubWord, SBox, etc. are in separate .v files or combined
CORE_SOURCES = [
    RTL_DIR / "SBox.v",
    RTL_DIR / "SubWord.v",
    RTL_DIR / "SubBytes.v",
    RTL_DIR / "ShiftRows.v",
    RTL_DIR / "MixSingleColumn.v",
    RTL_DIR / "MixColumns.v",
    RTL_DIR / "KeyExpansion.v",
    RTL_DIR / "AddRoundKey.v",
    RTL_DIR / "aes128_core.v",
]

# Define each verification target: (Display Name, Top Module, Verilog Sources, Python Test Module)
TEST_SUITES = [
    (
        "AES-128 Core",
        "aes128_core",
        CORE_SOURCES,
        "test_aes_core",
    ),
    (
        "AES-128 CTR",
        "aes128_ctr",
        CORE_SOURCES + [RTL_DIR / "aes128_ctr.v"],
        "test_aes_ctr",
    ),
    (
        "AES-128 CTR Stream",
        "aes128_ctr_stream",
        CORE_SOURCES + [RTL_DIR / "aes128_ctr.v", RTL_DIR / "aes128_ctr_stream.v"],
        "test_aes_ctr_stream",
    ),
    (
        "AES-128 CMAC",
        "aes128_cmac_top",
        CORE_SOURCES + [RTL_DIR / "aes128_cmac_top.v"],
        "test_aes_cmac",
    ),
]


def run_suite(sim_name: str, suite_name: str, toplevel: str, sources: list[Path], test_module: str) -> bool:
    print(f"\n{'=' * 60}")
    print(f"RUNNING SUITE: {suite_name} (Top: {toplevel})")
    print(f"{'=' * 60}")

    # Verify all Verilog files exist before invoking the simulator
    missing = [str(src) for src in sources if not src.exists()]
    if missing:
        print(f"[SKIP] Missing RTL files for {suite_name}:")
        for m in missing:
            print(f"  - {m}")
        return False

    build_dir = TB_DIR / "sim_build" / toplevel
    runner = get_runner(sim_name)

    try:
        runner.build(
            verilog_sources=[str(src) for src in sources],
            hdl_toplevel=toplevel,
            build_dir=str(build_dir),
            always=True,
        )

        runner.test(
            hdl_toplevel=toplevel,
            test_module=test_module,
            build_dir=str(build_dir),
        )
        print(f"[PASS] {suite_name}")
        return True

    except Exception as e:
        print(f"[FAIL] {suite_name}: {e}")
        traceback.print_exc()
        return False


def main():
    # Default to Icarus Verilog; override via environment variable: SIM=verilator python run_tests.py
    sim_name = os.getenv("SIM", "icarus")

    print("Step 1: Generating fresh AES-128 test vectors...")
    vectors = vector_gen.generate_all_vectors(num_random=50)
    print(f"Generated vectors for: {', '.join(vectors.keys())}")

    print(f"\nStep 2: Running RTL simulations using '{sim_name}'...")
    results = {}

    for suite_name, toplevel, sources, test_module in TEST_SUITES:
        # Check if the python test file has been written yet
        if not (TB_DIR / f"{test_module}.py").exists():
            print(f"\n[SKIP] {suite_name}: '{test_module}.py' not found yet.")
            results[suite_name] = "SKIPPED"
            continue

        passed = run_suite(sim_name, suite_name, toplevel, sources, test_module)
        results[suite_name] = "PASS" if passed else "FAIL"

    # Final Summary Report
    print(f"\n{'=' * 60}")
    print("VERIFICATION SUMMARY")
    print(f"{'=' * 60}")
    for name, status in results.items():
        print(f"  {name:<22} : {status}")

    if "FAIL" in results.values():
        sys.exit(1)


if __name__ == "__main__":
    main()