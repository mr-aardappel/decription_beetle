module aes128_cmac_mac_gen (
    input  wire         clk,
    input  wire         rst,
    input  wire         start_msg,      // Pulse high to initialize a new MAC calculation (sets C_0 = 0)
    input  wire         process_block,  // Pulse high to process the current data_in
    input  wire         is_final_block, // High if the current data_in is the last block of the message
    input  wire         is_complete,    // High if the final block is exactly 128 bits. If low, data_in MUST be pre-padded with 10..0
    input  wire [127:0] key,
    input  wire [127:0] K1,
    input  wire [127:0] K2,
    input  wire [127:0] data_in,        // The message block M_i
    output reg  [127:0] mac_out,        // The final calculated MAC (T)
    output reg          done,           // High for 1 cycle when the final MAC is ready
    output wire         ready           // High when idle and ready to process the next block
);

    // FSM States
    localparam IDLE     = 1'b0;
    localparam WAIT_AES = 1'b1;

    reg         state;
    reg [127:0] c_reg; // Holds C_{i-1}
    reg         final_block_flag; 

    // AES Core signals
    reg          aes_start;
    wire [127:0] aes_in;
    wire [127:0] aes_out;
    wire         aes_done;

    // Determine the modified message block (M_n) for the XOR network[cite: 5, 6]
    wire [127:0] processed_data;
    
    assign processed_data = (!is_final_block) ? data_in :
                            (is_complete)     ? data_in ^ K1 :
                                                data_in ^ K2;

    // XOR the previous ciphertext with the processed message block[cite: 5, 6]
    assign aes_in = c_reg ^ processed_data;

    assign ready = (state == IDLE);

    aes128_core core_inst (
        .clk      (clk),
        .rst      (rst),
        .start    (aes_start),
        .key      (key),
        .data_in  (aes_in),
        .data_out (aes_out),
        .done     (aes_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state            <= IDLE;
            c_reg            <= 128'h0;
            mac_out          <= 128'h0;
            aes_start        <= 1'b0;
            done             <= 1'b0;
            final_block_flag <= 1'b0;
        end else begin
            aes_start <= 1'b0;
            done      <= 1'b0;

            // Step 5: C_0 = 0^b[cite: 5]
            if (start_msg && ready) begin
                c_reg <= 128'h0;
            end

            case (state)
                IDLE: begin
                    if (process_block) begin
                        aes_start        <= 1'b1;
                        final_block_flag <= is_final_block;
                        state            <= WAIT_AES;
                    end
                end

                WAIT_AES: begin
                    if (aes_done) begin
                        // Step 6: Store C_i for the next iteration[cite: 5]
                        c_reg <= aes_out;
                        
                        if (final_block_flag) begin
                            // Step 7: Output the MAC (T)[cite: 5]
                            // (If Tlen < 128 is needed, truncation can be done at the output wire)
                            mac_out <= aes_out; 
                            done    <= 1'b1;
                        end
                        
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule