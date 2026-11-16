`timescale 1ns / 1ps

module tb_aes128_ctr_stream;

    reg          clk;
    reg          rst;
    reg          load_iv;
    reg          start_block;
    reg  [127:0] key;
    reg  [127:0] iv;
    reg  [127:0] data_in;
    wire [127:0] data_out;
    wire         done;
    wire         ready;

    // Instantiate the Unit Under Test (UUT)
    aes128_ctr_stream uut (
        .clk         (clk),
        .rst         (rst),
        .load_iv     (load_iv),
        .start_block (start_block),
        .key         (key),
        .iv          (iv),
        .data_in     (data_in),
        .data_out    (data_out),
        .done        (done),
        .ready       (ready)
    );

    // 100 MHz clock generation
    always #5 clk = ~clk;

    // NIST SP 800-38A F.5.1 CTR-AES128 Vector
    localparam [127:0] NIST_KEY   = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] NIST_IV    = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;

    reg [127:0] nist_pt [0:3];
    reg [127:0] nist_ct [0:3];

    // All-Zeros Test Vector (Key=0, IV=0, PT=0 -> CT = AES128_ECB(Key=0, Block))
    localparam [127:0] ZERO_KEY   = 128'h00000000000000000000000000000000;
    localparam [127:0] ZERO_IV    = 128'h00000000000000000000000000000000;
    localparam [127:0] ZERO_PT    = 128'h00000000000000000000000000000000;
    localparam [127:0] ZERO_CT_0  = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e; // AES_0(0)
    localparam [127:0] ZERO_CT_1  = 128'h58e2fccefa7e3061367f1d57a4e7455a; // AES_0(1)

    integer i;
    integer errors;

    // Task to load initial counter block
    task set_stream_iv;
        input [127:0] t_key;
        input [127:0] t_iv;
        begin
            wait (ready == 1'b1);
            @(negedge clk);
            key     = t_key;
            iv      = t_iv;
            load_iv = 1'b1;

            @(negedge clk);
            load_iv = 1'b0;
        end
    endtask

    // Task to process one streaming block and verify registered output
    task process_stream_block;
        input [127:0] t_data_in;
        input [127:0] t_expected;
        input [127:0] label;
        begin
            wait (ready == 1'b1);
            @(negedge clk);
            data_in     = t_data_in;
            start_block = 1'b1;

            @(negedge clk);
            start_block = 1'b0;
            data_in     = 128'h0; // Clear input to verify internal latching

            // Wait for 1-cycle done pulse
            @(posedge done);
            #1; // Sample registered output just after clock edge

            if (data_out !== t_expected) begin
                $display("[FAIL] %0s | Got: %h | Expected: %h", 
                         label, data_out, t_expected);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s | Out: %h", 
                         label, data_out);
            end
        end
    endtask
    
    initial begin
        $dumpfile("tb_aes128_ctr_stream.vcd");
        $dumpvars(0, tb_aes128_ctr_stream);
    end

    initial begin
        // Initialize NIST plaintext & expected ciphertext blocks
        nist_pt[0] = 128'h6bc1bee22e409f96e93d7e117393172a;
        nist_pt[1] = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
        nist_pt[2] = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
        nist_pt[3] = 128'hf69f2445df4f9b17ad2b417be66c3710;

        nist_ct[0] = 128'h874d6191b620e3261bef6864990db6ce;
        nist_ct[1] = 128'h9806f66b7970fdff8617187bb9fffdff;
        nist_ct[2] = 128'h5ae4df3edbd5d35e5b4f09020db03eab;
        nist_ct[3] = 128'h1e031dda2fbe03d1792170a0f3009cee;

        // Initialize signals
        clk         = 0;
        rst         = 1;
        load_iv     = 0;
        start_block = 0;
        key         = 128'h0;
        iv          = 128'h0;
        data_in     = 128'h0;
        errors      = 0;

        // Release reset
        #20;
        rst = 0;
        #10;

        $display("==========================================================");
        $display(" Testing aes128_ctr_stream - NIST SP 800-38A Encryption");
        $display("==========================================================");
        set_stream_iv(NIST_KEY, NIST_IV);
        for (i = 0; i < 4; i = i + 1) begin
            process_stream_block(nist_pt[i], nist_ct[i], "NIST ENC");
        end

        $display("==========================================================");
        $display(" Testing aes128_ctr_stream - NIST SP 800-38A Decryption");
        $display("==========================================================");
        set_stream_iv(NIST_KEY, NIST_IV);
        for (i = 0; i < 4; i = i + 1) begin
            process_stream_block(nist_ct[i], nist_pt[i], "NIST DEC");
        end

        $display("==========================================================");
        $display(" Testing aes128_ctr_stream - All-Zeros Vector (2 Blocks)");
        $display("==========================================================");
        set_stream_iv(ZERO_KEY, ZERO_IV);
        process_stream_block(ZERO_PT, ZERO_CT_0, "ZERO ENC 0");
        process_stream_block(ZERO_PT, ZERO_CT_1, "ZERO ENC 1");

        set_stream_iv(ZERO_KEY, ZERO_IV);
        process_stream_block(ZERO_CT_0, ZERO_PT, "ZERO DEC 0");
        process_stream_block(ZERO_CT_1, ZERO_PT, "ZERO DEC 1");

        $display("==========================================================");
        if (errors == 0)
            $display(" ALL TESTS PASSED!");
        else
            $display(" TESTS COMPLETED WITH %0d ERROR(S).", errors);
        $display("==========================================================");
        $finish;
    end

endmodule