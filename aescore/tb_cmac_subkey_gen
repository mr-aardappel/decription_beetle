`timescale 1ns / 1ps

module tb_cmac_subkey_gen;

    reg          clk;
    reg          rst;
    reg          start;
    reg  [127:0] key;
    wire [127:0] K1;
    wire [127:0] K2;
    wire         done;

    cmac_subkey_gen uut (
        .clk   (clk),
        .rst   (rst),
        .start (start),
        .key   (key),
        .K1    (K1),
        .K2    (K2),
        .done  (done)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_cmac_subkey_gen.vcd");
        $dumpvars(0, tb_cmac_subkey_gen);
    end

    // NIST SP 800-38B D.1 AES-128 Subkeys
    localparam [127:0] NIST_KEY = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] NIST_K1  = 128'hfbeed618357133667c85e08f7236a8de;
    localparam [127:0] NIST_K2  = 128'hf7ddac306ae266ccf90bc11ee46d513b;

    // All-Zeros Key Subkeys
    // L  = AES_0(0) = 66e94bd4ef8a2c3b884cfa59ca342b2e (MSB=0)
    // K1 = L << 1   = cdd297a9df1458771099f4b39468565c (MSB=1)
    // K2 = (K1<<1)^0x87 = 9ba52f53be28b0ee2133e96728d0ac3f
    localparam [127:0] ZERO_KEY = 128'h00000000000000000000000000000000;
    localparam [127:0] ZERO_K1  = 128'hcdd297a9df1458771099f4b39468565c;
    localparam [127:0] ZERO_K2  = 128'h9ba52f53be28b0ee2133e96728d0ac3f;

    integer errors;

    task run_subkey_test;
        input [127:0] t_key;
        input [127:0] exp_k1;
        input [127:0] exp_k2;
        input [127:0] label;
        begin
            @(negedge clk);
            key   = t_key;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            @(posedge done);
            #1;
            if (K1 !== exp_k1 || K2 !== exp_k2) begin
                $display("[FAIL] %0s", label);
                $display("       Got K1: %h | Exp K1: %h", K1, exp_k1);
                $display("       Got K2: %h | Exp K2: %h", K2, exp_k2);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s | K1: %h | K2: %h", label, K1, K2);
            end
        end
    endtask

    initial begin
        clk    = 0;
        rst    = 1;
        start  = 0;
        key    = 128'h0;
        errors = 0;

        #20 rst = 0;
        #10;

        $display("==========================================================");
        $display(" Testing cmac_subkey_gen");
        $display("==========================================================");
        run_subkey_test(NIST_KEY, NIST_K1, NIST_K2, "NIST D.1");
        run_subkey_test(ZERO_KEY, ZERO_K1, ZERO_K2, "ALL ZEROS");

        $display("==========================================================");
        if (errors == 0) $display(" ALL SUBKEY TESTS PASSED!");
        else             $display(" COMPLETED WITH %0d ERROR(S).", errors);
        $display("==========================================================");
        $finish;
    end

endmodule