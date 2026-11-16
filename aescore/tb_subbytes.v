`timescale 1ns / 1ps

module tb_SubBytes;

    // Inputs
    reg [127:0] state_in;

    // Outputs
    wire [127:0] state_out;

    // Instantiate the Unit Under Test (UUT)
    SubBytes uut (
        .state_in(state_in),
        .state_out(state_out)
    );

    initial begin
        // Optional: for waveform dumping
        $dumpfile("tb_subbytes.vcd");
        $dumpvars(0, tb_SubBytes);

        $display("Starting SubBytes Testbench...");

        // Test Case 1: NIST FIPS 197 Appendix B - Round 1 SubBytes state
        // Input state after the initial AddRoundKey
        state_in = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
        #10;
        
        // Expected output state after SubBytes
        if (state_out === 128'hd42711aee0bf98f1b8b45de51e415230)
            $display("PASS: NIST Round 1 State");
        else begin
            $display("FAIL: NIST Round 1 State");
            $display("Expected: d42711aee0bf98f1b8b45de51e415230");
            $display("Got:      %h", state_out);
        end

        // Test Case 2: All zeroes
        // Since SBox(00) = 63, a 128-bit vector of 0s must become a 128-bit vector of 63s
        state_in = 128'h00000000000000000000000000000000;
        #10;
        
        if (state_out === 128'h63636363636363636363636363636363)
            $display("PASS: All Zeroes");
        else 
            $display("FAIL: All Zeroes, got: %h", state_out);

        $display("SubBytes tests completed.");
        $finish;
    end

endmodule