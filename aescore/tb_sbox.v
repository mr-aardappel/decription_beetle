`timescale 1ns / 1ps

module tb_SBox;

    // Inputs
    reg [7:0] in_byte;

    // Outputs
    wire [7:0] out_byte;

    // Instantiate the Unit Under Test (UUT)
    SBox uut (
        .in_byte(in_byte),
        .out_byte(out_byte)
    );

    initial begin
        // Optional: for waveform dumping in tools like Icarus Verilog/GTKWave
        $dumpfile("tb_sbox.vcd");
        $dumpvars(0, tb_SBox);

        $display("Starting SBox Testbench...");

        // Test Case 1: Row 0, Col 0
        in_byte = 8'h00;
        #10;
        if (out_byte === 8'h63) $display("PASS: in=00, out=%h", out_byte);
        else $display("FAIL: in=00, expected=63, got=%h", out_byte);

        // Test Case 2: Row 0, Col 1
        in_byte = 8'h01;
        #10;
        if (out_byte === 8'h7c) $display("PASS: in=01, out=%h", out_byte);
        else $display("FAIL: in=01, expected=7c, got=%h", out_byte);

        // Test Case 3: Row 5, Col 3
        in_byte = 8'h53;
        #10;
        if (out_byte === 8'hed) $display("PASS: in=53, out=%h", out_byte);
        else $display("FAIL: in=53, expected=ed, got=%h", out_byte);

        // Test Case 4: Row f, Col f
        in_byte = 8'hff;
        #10;
        if (out_byte === 8'h16) $display("PASS: in=ff, out=%h", out_byte);
        else $display("FAIL: in=ff, expected=16, got=%h", out_byte);

        $display("SBox tests completed.");
        $finish;
    end

endmodule