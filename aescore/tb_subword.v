`timescale 1ns / 1ps

module tb_SubWord;

    // Inputs
    reg [31:0] in_word;

    // Outputs
    wire [31:0] out_word;

    // Instantiate the Unit Under Test (UUT)
    SubWord uut (
        .in_word(in_word),
        .out_word(out_word)
    );

    initial begin
        // Optional: for waveform dumping
        $dumpfile("tb_subword.vcd");
        $dumpvars(0, tb_SubWord);

        $display("Starting SubWord Testbench...");

        // Test Case 1: Combining the four byte values we tested in the SBox testbench
        // SBox(00) = 63, SBox(01) = 7c, SBox(53) = ed, SBox(ff) = 16
        in_word = 32'h000153ff;
        #10;
        if (out_word === 32'h637ced16) 
            $display("PASS: in=%h, out=%h", in_word, out_word);
        else 
            $display("FAIL: in=%h, expected=637ced16, got=%h", in_word, out_word);

        // Test Case 2: All zeroes
        // SBox(00) = 63 for all 4 bytes
        in_word = 32'h00000000;
        #10;
        if (out_word === 32'h63636363) 
            $display("PASS: in=%h, out=%h", in_word, out_word);
        else 
            $display("FAIL: in=%h, expected=63636363, got=%h", in_word, out_word);

        $display("SubWord tests completed.");
        $finish;
    end

endmodule