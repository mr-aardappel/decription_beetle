`timescale 1ns / 1ps

module tb_aes128_cmac_mac_gen;

    reg          clk;
    reg          rst;
    reg          start_msg;
    reg          process_block;
    reg          is_final_block;
    reg          is_complete;
    reg  [127:0] key;
    reg  [127:0] K1;
    reg  [127:0] K2;
    reg  [127:0] data_in;
    wire [127:0] mac_out;
    wire         done;
    wire         ready;

    aes128_cmac_mac_gen uut (
        .clk            (clk),
        .rst            (rst),
        .start_msg      (start_msg),
        .process_block  (process_block),
        .is_final_block (is_final_block),
        .is_complete    (is_complete),
        .key            (key),
        .K1             (K1),
        .K2             (K2),
        .data_in        (data_in),
        .mac_out        (mac_out),
        .done           (done),
        .ready          (ready)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_aes128_cmac_mac_gen.vcd");
        $dumpvars(0, tb_aes128_cmac_mac_gen);
    end

    // NIST SP 800-38B D.1 Constants
    localparam [127:0] NIST_KEY = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] NIST_K1  = 128'hfbeed618357133667c85e08f7236a8de;
    localparam [127:0] NIST_K2  = 128'hf7ddac306ae266ccf90bc11ee46d513b;

    // NIST Message Blocks
    localparam [127:0] M_EMPTY_PAD = 128'h80000000000000000000000000000000;
    localparam [127:0] M_BLK_0     = 128'h6bc1bee22e409f96e93d7e117393172a;
    localparam [127:0] M_BLK_1     = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
    localparam [127:0] M_BLK_2_PAD = 128'h30c81c46a35ce4118000000000000000; // 8 bytes + 10..0

    // NIST Expected Tags
    localparam [127:0] TAG_EX1_0B  = 128'hbb1d6929e95937287fa37d129b756746; // Example 1 (0 bytes)
    localparam [127:0] TAG_EX2_16B = 128'h070a16b46b4d4144f79bdd9dd04a287c; // Example 2 (16 bytes)
    localparam [127:0] TAG_EX3_40B = 128'hdfa66747de9ae63030ca32611497c827; // Example 3 (40 bytes)

    // All-Zeros Vector (16-byte complete zero message -> AES_0(0 ^ ZERO_K1))
    localparam [127:0] ZERO_KEY = 128'h00000000000000000000000000000000;
    localparam [127:0] ZERO_K1  = 128'hcdd297a9df1458771099f4b39468565c;
    localparam [127:0] ZERO_K2  = 128'h9ba52f53be28b0ee2133e96728d0ac3f;
    localparam [127:0] ZERO_TAG = 128'h763cbcde81df9131bf897712c088edad;

    integer errors;

    task init_message;
        input [127:0] t_key;
        input [127:0] t_k1;
        input [127:0] t_k2;
        begin
            wait (ready == 1'b1);
            @(negedge clk);
            key       = t_key;
            K1        = t_k1;
            K2        = t_k2;
            start_msg = 1'b1;
            @(negedge clk);
            start_msg = 1'b0;
        end
    endtask

    task feed_block;
        input [127:0] t_data;
        input         t_final;
        input         t_complete;
        begin
            wait (ready == 1'b1);
            @(negedge clk);
            data_in        = t_data;
            is_final_block = t_final;
            is_complete    = t_complete;
            process_block  = 1'b1;
            @(negedge clk);
            process_block  = 1'b0;

            if (t_final) begin
                @(posedge done);
                #1;
            end else begin
                @(posedge clk);
                wait (ready == 1'b1);
            end
        end
    endtask

    task check_mac;
        input [127:0] expected;
        input [127:0] label;
        begin
            if (mac_out !== expected) begin
                $display("[FAIL] %0s | Got: %h | Exp: %h", label, mac_out, expected);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s | MAC: %h", label, mac_out);
            end
        end
    endtask

    initial begin
        clk            = 0;
        rst            = 1;
        start_msg      = 0;
        process_block  = 0;
        is_final_block = 0;
        is_complete    = 0;
        key            = 128'h0;
        K1             = 128'h0;
        K2             = 128'h0;
        data_in        = 128'h0;
        errors         = 0;

        #20 rst = 0;
        #10;

        $display("==========================================================");
        $display(" Testing aes128_cmac_mac_gen");
        $display("==========================================================");

        // NIST Example 1: 0-byte empty message (1 padded block, K2)
        init_message(NIST_KEY, NIST_K1, NIST_K2);
        feed_block(M_EMPTY_PAD, 1'b1, 1'b0);
        check_mac(TAG_EX1_0B, "NIST EX1 (0B)");

        // NIST Example 2: 16-byte message (1 complete block, K1)
        init_message(NIST_KEY, NIST_K1, NIST_K2);
        feed_block(M_BLK_0, 1'b1, 1'b1);
        check_mac(TAG_EX2_16B, "NIST EX2 (16B)");

        // NIST Example 3: 40-byte message (2 full blocks + 1 padded block, K2)
        init_message(NIST_KEY, NIST_K1, NIST_K2);
        feed_block(M_BLK_0,     1'b0, 1'b0);
        feed_block(M_BLK_1,     1'b0, 1'b0);
        feed_block(M_BLK_2_PAD, 1'b1, 1'b0);
        check_mac(TAG_EX3_40B, "NIST EX3 (40B)");

        // All-Zeros Vector: 16-byte all-zero block
        init_message(ZERO_KEY, ZERO_K1, ZERO_K2);
        feed_block(128'h0, 1'b1, 1'b1);
        check_mac(ZERO_TAG, "ALL ZEROS (16B)");

        $display("==========================================================");
        if (errors == 0) $display(" ALL MAC GEN TESTS PASSED!");
        else             $display(" COMPLETED WITH %0d ERROR(S).", errors);
        $display("==========================================================");
        $finish;
    end

endmodule