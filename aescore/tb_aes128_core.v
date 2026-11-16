`timescale 1ns / 1ps

module tb_aes128_core;

    // Inputs
    reg         clk;
    reg         rst;
    reg         start;
    reg [127:0] key;
    reg [127:0] data_in;

    // Outputs
    wire [127:0] data_out;
    wire         done;

    // Instantiate the Unit Under Test (UUT)
    aes128_core uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .key(key),
        .data_in(data_in),
        .data_out(data_out),
        .done(done)
    );

    // Clock Generation (100 MHz clock, 10ns period)
    always #5 clk = ~clk;

    initial begin
        // Optional: for waveform dumping
        $dumpfile("tb_aes128_core.vcd");
        $dumpvars(0, tb_aes128_core);

        $display("Starting aes128_core Testbench...");

        // Step 1: Initialize Inputs
        clk     = 0;
        rst     = 1;
        start   = 0;
        key     = 128'h0;
        data_in = 128'h0;

        // Step 2: Release Reset
        #20;
        rst = 0;
        #10;

        // Step 3: Apply NIST FIPS 197 Appendix B Test Vector
        // Key:                 2b7e151628aed2a6abf7158809cf4f3c
        // Plaintext (data_in): 3243f6a8885a308d313198a2e0370734
        key     = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        data_in = 128'h3243f6a8885a308d313198a2e0370734;

        // Pulse start signal for 1 clock cycle
        start = 1;
        #10;
        start = 0;

        // Step 4: Wait for the done signal from the AES core
        @(posedge done);
        #1; // Small delta delay to sample stable output

        // Step 5: Check output against expected NIST FIPS 197 Appendix B Ciphertext
        if (data_out === 128'h3925841d02dc09fbdc118597196a0b32) begin
            $display("PASS: NIST FIPS 197 Full Encryption Match");
            $display("Ciphertext: %h", data_out);
        end else begin
            $display("FAIL: NIST FIPS 197 Full Encryption Mismatch");
            $display("Expected: 3925841d02dc09fbdc118597196a0b32");
            $display("Got:      %h", data_out);
        end

        $display("aes128_core tests completed.");
        $finish;
    end

endmodule