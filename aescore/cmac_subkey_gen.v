module cmac_subkey_gen (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [127:0] key,
    output reg  [127:0] K1,
    output reg  [127:0] K2,
    output reg          done
);

    // CMAC constant for 128-bit block size
    localparam [127:0] Rb = 128'h00000000_00000000_00000000_00000087;

    // FSM States
    localparam IDLE        = 2'd0;
    localparam WAIT_CIPHER = 2'd1;
    localparam DONE        = 2'd2;

    reg [1:0] state;

    // AES Core signals
    reg          aes_start;
    wire [127:0] aes_out;
    wire         aes_done;

    // The CMAC specification requires encrypting a block of all zeros[cite: 4]
    wire [127:0] zero_block = 128'h0;

    aes128_core core_inst (
        .clk      (clk),
        .rst      (rst),
        .start    (aes_start),
        .key      (key),
        .data_in  (zero_block),
        .data_out (aes_out),
        .done     (aes_done)
    );

    // Intermediate combinational logic for K1 and K2 derivation
    wire [127:0] next_K1;
    wire [127:0] next_K2;

    // Step 2: derive K1 from L (aes_out)[cite: 4]
    assign next_K1 = (aes_out[127] == 1'b0) ? (aes_out << 1) : ((aes_out << 1) ^ Rb);
    
    // Step 3: derive K2 from K1[cite: 4]
    assign next_K2 = (next_K1[127] == 1'b0) ? (next_K1 << 1) : ((next_K1 << 1) ^ Rb);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            aes_start <= 1'b0;
            K1        <= 128'h0;
            K2        <= 128'h0;
            done      <= 1'b0;
        end else begin
            aes_start <= 1'b0;
            done      <= 1'b0;

            case (state)
                IDLE: begin
                    if (start) begin
                        aes_start <= 1'b1;
                        state     <= WAIT_CIPHER;
                    end
                end

                WAIT_CIPHER: begin
                    if (aes_done) begin
                        K1    <= next_K1;
                        K2    <= next_K2;
                        done  <= 1'b1;
                        state <= IDLE;
                    end
                end

                DONE: begin
                    // Optional holding state; can return to IDLE automatically
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule