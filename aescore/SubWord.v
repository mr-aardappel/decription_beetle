module SubWord (
    input  wire [31:0] in_word,
    output wire [31:0] out_word
);

    // Applies the S-Box to each of the four bytes in the word[cite: 7]
    SBox sbox_0 (.in_byte(in_word[31:24]), .out_byte(out_word[31:24]));
    SBox sbox_1 (.in_byte(in_word[23:16]), .out_byte(out_word[23:16]));
    SBox sbox_2 (.in_byte(in_word[15:8]),  .out_byte(out_word[15:8]));
    SBox sbox_3 (.in_byte(in_word[7:0]),   .out_byte(out_word[7:0]));

endmodule