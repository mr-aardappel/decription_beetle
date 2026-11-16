`timescale 1ns / 1ps

module tb_MixColumns;

    // Inputs
    reg [127:0] state_in;

    // Outputs
    wire [127:0] state_out;

    // Instantiate the Unit Under Test (UUT)
    MixColumns uut (
        .state_in(state_in),
        .state_out(state_out)
    );

    initial begin
        // Optional: for waveform dumping
        $dumpfile("tb_mixcolumns.vcd");
        $dumpvars(0, tb_MixColumns);

        $display("Starting MixColumns Testbench...");

        // Test Case 1: NIST FIPS 197 Appendix B - Round 1
        // State after Round 1 ShiftRows
        state_in = 128'hd4bf5d30e0b452aeb84111f11e2798e5;
        #10;
        
        if (state_out === 128'h046681e5e0cb199a48f8d37a2806264c)
            $display("PASS: NIST Round 1 State");
        else begin
            $display("FAIL: NIST Round 1 State");
            $display("Expected: 046681e5e0cb199a48f8d37a2806264c");
            $display("Got:      %h", state_out);
        end

        // Test Case 2: NIST FIPS 197 Appendix B - Round 2
        // CORRECTED: The actual State after Round 2 ShiftRows
        state_in = 128'h49db873b453953897f02d2f177de961a;
        #10;
        
        // Expected state after Round 2 MixColumns
        if (state_out === 128'h584dcaf11b4b5aacdbe7caa81b6bb0e5)
            $display("PASS: NIST Round 2 State");
        else begin
            $display("FAIL: NIST Round 2 State");
            $display("Expected: 584dcaf11b4b5a91dbe7c1c91b6b58fb");
            $display("Got:      %h", state_out);
        end

        $display("MixColumns tests completed.");
        $finish;
    end

endmodule