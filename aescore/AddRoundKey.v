module AddRoundKey (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);

    // Apply bitwise XOR between the 128-bit state and the 128-bit round key
    assign state_out = state_in ^ round_key;

endmodule