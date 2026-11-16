`timescale 1ns / 1ps

module tb_ShiftRows;

    // Inputs
    reg [127:0] state_in;

    // Outputs
    wire [127:0] state_out;

    // Instantiate the Unit Under Test (UUT)
    ShiftRows uut (
        .state_in(state_in),
        .state_out(state_out)
    );

    initial begin
        // Optional: for waveform dumping
        $dumpfile("tb_shiftrows.vcd");
        $dumpvars(0, tb_ShiftRows);

        $display("Starting ShiftRows Testbench...");

        // Test Case 1: NIST FIPS 197 Appendix B - Round 1 ShiftRows state
        // This is the expected output from the Round 1 SubBytes step
        state_in = 128'hd42711aee0bf98f1b8b45de51e415230;
        #10;
        
        // Expected output state after ShiftRows
        if (state_out === 128'hd4bf5d30e0b452aeb84111f11e2798e5)
            $display("PASS: NIST Round 1 State");
        else begin
            $display("FAIL: NIST Round 1 State");
            $display("Expected: d4bf5d30e0b452aeb84111f11e2798e5");
            $display("Got:      %h", state_out);
        end

        // Test Case 2: NIST FIPS 197 Appendix B - Round 2 ShiftRows state
        // This is the expected output from the Round 2 SubBytes step
        state_in = 128'haa6182680f4f9a0c7104b2a33f42e47d;
        #10;
        
        // Expected output state after ShiftRows
        if (state_out === 128'haa4fb27d0f04e4687142820c3f619aa3)
            $display("PASS: NIST Round 2 State");
        else begin
            $display("FAIL: NIST Round 2 State");
            $display("Expected: aa4fb27d0f04e4687142820c3f619aa3");
            $display("Got:      %h", state_out);
        end

        $display("ShiftRows tests completed.");
        $finish;
    end

endmodule