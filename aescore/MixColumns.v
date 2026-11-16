// -------------------------------------------------------------------------
// Top module: Applies MixSingleColumn to all four columns of the state
// -------------------------------------------------------------------------
module MixColumns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    genvar i;
    generate
        // Loop through all 4 columns (c = 0 to 3)
        for (i = 0; i < 4; i = i + 1) begin : mix_col_array
            MixSingleColumn msc_inst (
                // Slicing 32 bits at a time. 
                // i=0 gets [127:96], i=1 gets [95:64], etc.
                .col_in  (state_in[127 - (i * 32) -: 32]),
                .col_out (state_out[127 - (i * 32) -: 32])
            );
        end
    endgenerate

endmodule