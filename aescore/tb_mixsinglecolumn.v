`timescale 1ns / 1ps

module tb_MixSingleColumn;

    // Inputs
    reg [31:0] col_in;

    // Outputs
    wire [31:0] col_out;

    // Instantiate the Unit Under Test (UUT)
    MixSingleColumn uut (
        .col_in(col_in),
        .col_out(col_out)
    );

    initial begin
        // Optional: for waveform dumping
        $dumpfile("tb_mixsinglecolumn.vcd");
        $dumpvars(0, tb_MixSingleColumn);

        $display("Starting MixSingleColumn Testbench...");

        // Test Case 1: NIST FIPS 197 Appendix B - Round 1, Column 0
        col_in = 32'hd4bf5d30;
        #10;
        
        if (col_out === 32'h046681e5)
            $display("PASS: NIST Round 1, Column 0");
        else begin
            $display("FAIL: NIST Round 1, Column 0");
            $display("Expected: 046681e5");
            $display("Got:      %h", col_out);
        end

        // Test Case 2: NIST FIPS 197 Appendix B - Round 1, Column 1
        col_in = 32'he0b452ae;
        #10;
        
        if (col_out === 32'he0cb199a)
            $display("PASS: NIST Round 1, Column 1");
        else begin
            $display("FAIL: NIST Round 1, Column 1");
            $display("Expected: e0cb199a");
            $display("Got:      %h", col_out);
        end

        $display("MixSingleColumn tests completed.");
        $finish;
    end

endmodule