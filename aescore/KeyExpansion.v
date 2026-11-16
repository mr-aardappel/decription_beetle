module KeyExpansion (
    input  wire [127:0]  key,
    output wire [1407:0] w    // 11 round keys * 128 bits = 1408 bits
);

    // Array to hold the 44 32-bit words (w[0] to w[43])[cite: 7]
    wire [31:0] word [0:43];

    // Initialize the first Nk (4) words with the original key[cite: 8]
    assign word[0] = key[127:96];
    assign word[1] = key[95:64];
    assign word[2] = key[63:32];
    assign word[3] = key[31:0];

    // Function to retrieve the Round Constant (Rcon) based on Table 5[cite: 7]
    function automatic [31:0] get_rcon;
        input integer j;
        begin
            case(j)
                1:  get_rcon = 32'h01000000;
                2:  get_rcon = 32'h02000000;
                3:  get_rcon = 32'h04000000;
                4:  get_rcon = 32'h08000000;
                5:  get_rcon = 32'h10000000;
                6:  get_rcon = 32'h20000000;
                7:  get_rcon = 32'h40000000;
                8:  get_rcon = 32'h80000000;
                9:  get_rcon = 32'h1b000000;
                10: get_rcon = 32'h36000000;
                default: get_rcon = 32'h00000000;
            endcase
        end
    endfunction

    // Main expansion loop for w[4] to w[43][cite: 8]
    genvar i;
    generate
        for (i = 4; i < 44; i = i + 1) begin : key_expansion_loop
            if (i % 4 == 0) begin : gen_subword
                wire [31:0] rot_word;
                wire [31:0] sub_word_out;
                
                // RotWord: cyclic shift [a0, a1, a2, a3] -> [a1, a2, a3, a0][cite: 7]
                assign rot_word = {word[i-1][23:0], word[i-1][31:24]};
                
                // SubWord
                SubWord sub_word_inst (
                    .in_word  (rot_word),
                    .out_word (sub_word_out)
                );
                
                // Combine w[i-Nk] ^ SubWord(RotWord(w[i-1])) ^ Rcon[i/Nk][cite: 7]
                assign word[i] = word[i-4] ^ sub_word_out ^ get_rcon(i/4);
                
            end else begin : gen_simple
                
                // Standard case: w[i-Nk] ^ w[i-1][cite: 8]
                assign word[i] = word[i-4] ^ word[i-1];
                
            end
        end
    endgenerate

    // Pack the 44 words into the 11 consecutive 128-bit round keys
    // Round key 0 gets word[0..3], round key 1 gets word[4..7], etc.
    genvar r;
    generate
        for (r = 0; r < 11; r = r + 1) begin : pack_round_keys
            assign w[r*128 +: 128] = {word[r*4], word[r*4+1], word[r*4+2], word[r*4+3]};
        end
    endgenerate

endmodule

