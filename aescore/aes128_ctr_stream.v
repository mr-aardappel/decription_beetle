// AES-128 CTR wrapper around the iterative aes128_core (encrypt-only core;
// CTR decryption is identical to encryption).
//
// Usage:
//   1. Wait for ready, pulse load_iv with iv valid (once per message).
//   2. For each block: wait for ready, pulse start_block with data_in valid
//      (data_in is latched on that cycle, key must stay stable until done).
//   3. data_out is valid and held while done is high, and stays valid until
//      the next block completes.
// Counter is a full 128-bit increment.

module aes128_ctr_stream (
    input  wire         clk,
    input  wire         rst,
    input  wire         load_iv,     // Pulse high (while ready) to load a new initial counter block
    input  wire         start_block, // Pulse high (while ready) to process a block
    input  wire [127:0] key,
    input  wire [127:0] iv,          // Initial 128-bit counter block
    input  wire [127:0] data_in,     // Plaintext or ciphertext block (latched on start_block)
    output reg  [127:0] data_out,    // data_in ^ keystream, registered
    output reg          done,        // High for 1 cycle when data_out is valid
    output wire         ready        // High when idle: safe to pulse start_block / load_iv
);

    reg [127:0]  ctr_reg;
    reg [127:0]  data_reg;
    reg          core_start;
    reg          busy;
    wire [127:0] keystream;
    wire         core_done;

    assign ready = ~busy;

    aes128_core core_inst (
        .clk      (clk),
        .rst      (rst),
        .start    (core_start),
        .key      (key),
        .data_in  (ctr_reg),
        .data_out (keystream),
        .done     (core_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ctr_reg    <= 128'h0;
            data_reg   <= 128'h0;
            data_out   <= 128'h0;
            core_start <= 1'b0;
            busy       <= 1'b0;
            done       <= 1'b0;
        end else begin
            core_start <= 1'b0;
            done       <= 1'b0;

            // Accept a new request only when idle
            if (!busy) begin
                if (load_iv)
                    ctr_reg <= iv;

                if (start_block) begin
                    data_reg   <= data_in;
                    core_start <= 1'b1;
                    busy       <= 1'b1;
                end
            end

            // Block finished: XOR, register output, advance counter, go idle
            if (core_done) begin
                data_out <= data_reg ^ keystream;
                done     <= 1'b1;
                ctr_reg  <= ctr_reg + 1'b1;
                busy     <= 1'b0;
            end
        end
    end

endmodule