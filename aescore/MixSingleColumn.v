// -------------------------------------------------------------------------
// Sub-module: Mixes a single 32-bit column (4 bytes)
// -------------------------------------------------------------------------
module MixSingleColumn (
    input  wire [31:0] col_in,
    output wire [31:0] col_out
);

    wire [7:0] s0, s1, s2, s3;
    wire [7:0] s0_prime, s1_prime, s2_prime, s3_prime;

    // Break the 32-bit column into four individual bytes
    assign s0 = col_in[31:24];
    assign s1 = col_in[23:16];
    assign s2 = col_in[15:8];
    assign s3 = col_in[7:0];

    // The xTimes function: Multiplies a polynomial by x in GF(2^8) modulo 0x11b
    function automatic [7:0] xTimes;
        input [7:0] b;
        begin
            xTimes = (b << 1) ^ (b[7] ? 8'h1b : 8'h00);
        end
    endfunction

    // Equation 5.8 calculations
    // Note: {03} * x is computed as xTimes(x) ^ x
    assign s0_prime = xTimes(s0)      ^ (xTimes(s1) ^ s1) ^ s2                ^ s3;
    assign s1_prime = s0              ^ xTimes(s1)        ^ (xTimes(s2) ^ s2) ^ s3;
    assign s2_prime = s0              ^ s1                ^ xTimes(s2)        ^ (xTimes(s3) ^ s3);
    assign s3_prime = (xTimes(s0)^s0) ^ s1                ^ s2                ^ xTimes(s3);

    // Concatenate the calculated bytes back into a 32-bit column
    assign col_out = {s0_prime, s1_prime, s2_prime, s3_prime};

endmodule


