`timescale 1ns / 1ps

module tb_AddRoundKey;

    // Inputs
    reg [127:0] state_in;
    reg [127:0] round_key;

    // Outputs
    wire [127:0] state_out;

    // Instantiate the Unit Under Test (UUT)
    AddRoundKey uut (
        .state_in(state_in),
        .round_key(round_key),
        .state_out(state_out)
    );

    initial begin
        // Optional: for waveform dumping
        $dumpfile("tb_addroundkey.vcd");
        $dumpvars(0, tb_AddRoundKey);

        $display("Starting AddRoundKey Testbench...");

        // Test Case 1: NIST FIPS 197 Appendix B - Initial AddRoundKey
        // Input is the raw plaintext
        state_in = 128'h3243f6a8885a308d313198a2e0370734;
        
        // Key is the original cipher key (Round 0 Key)
        round_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        #10;
        
        // Expected output is the state before Round 1 SubBytes
        if (state_out === 128'h193de3bea0f4e22b9ac68d2ae9f84808)
            $display("PASS: Initial AddRoundKey");
        else begin
            $display("FAIL: Initial AddRoundKey");
            $display("Expected: 193de3bea0f4e22b9ac68d2ae9f84808");
            $display("Got:      %h", state_out);
        end

        $display("AddRoundKey tests completed.");
        $finish;
    end

endmodule