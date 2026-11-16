module aes128_ctr (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [127:0] key,
    input  wire [127:0] nonce_counter, // 128-bit block (e.g., 96-bit nonce + 32-bit counter)
    input  wire [127:0] data_in,       // Plaintext (if encrypting) or Ciphertext (if decrypting)
    output wire [127:0] data_out,
    output wire         done
);

    // Wire to hold the AES core's output (the Keystream)
    wire [127:0] keystream;

    // Instantiate the iterative AES-128 core
    aes128_core core_inst (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .key      (key),
        // CRITICAL: In CTR mode, AES encrypts the Counter, NOT the data.
        .data_in  (nonce_counter), 
        .data_out (keystream),     
        .done     (done)
    );

    // The core of CTR mode: XOR the keystream with the input data.
    // Because the keystream is only valid when the AES core is 'done',
    // the system using this module must wait for the 'done' signal 
    // before reading 'data_out'.
    assign data_out = data_in ^ keystream;

endmodule