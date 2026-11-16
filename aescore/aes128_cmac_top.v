module aes128_cmac_top (
    input  wire         clk,
    input  wire         rst,
    
    // Control signals
    input  wire         init_key,       // Pulse high to generate K1/K2 for a new key
    input  wire         start_msg,      // Pulse high to clear C_0 and start a new message
    input  wire         process_block,  // Pulse high to process data_in
    input  wire         is_final_block, // High if the current block is the last one
    input  wire         is_complete,    // High if the final block is exactly 128 bits (no padding needed)
    
    // Data inputs
    input  wire [127:0] key,
    input  wire [127:0] data_in,        // Message block M_i
    input  wire [127:0] received_mac,   // T' for verification
    
    // Outputs
    output wire [127:0] mac_out,        // Generated MAC T
    output wire         mac_valid,      // High during mac_done when mac_out == received_mac
    output wire         mac_done,       // High for 1 cycle when MAC generation completes
    output wire         ready           // High when ready to accept start_msg or process_block
);

    // Internal wires for subkeys
    wire [127:0] K1;
    wire [127:0] K2;
    wire         subkey_done;
    
    // State management to prevent starting MAC gen before subkeys are ready
    reg subkeys_valid;

    // Subkey Generation Module
    cmac_subkey_gen subkey_inst (
        .clk   (clk),
        .rst   (rst),
        .start (init_key),
        .key   (key),
        .K1    (K1),
        .K2    (K2),
        .done  (subkey_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            subkeys_valid <= 1'b0;
        end else begin
            if (init_key) begin
                subkeys_valid <= 1'b0;
            end else if (subkey_done) begin
                subkeys_valid <= 1'b1;
            end
        end
    end

    // MAC Generation Module
    wire mac_gen_ready;
    
    aes128_cmac_mac_gen mac_gen_inst (
        .clk            (clk),
        .rst            (rst),
        .start_msg      (start_msg),
        .process_block  (process_block),
        .is_final_block (is_final_block),
        .is_complete    (is_complete),
        .key            (key),
        .K1             (K1),
        .K2             (K2),
        .data_in        (data_in),
        .mac_out        (mac_out),
        .done           (mac_done),
        .ready          (mac_gen_ready)
    );

    // Top-level ready implies subkeys are generated and MAC generator is idle
    assign ready = subkeys_valid & mac_gen_ready;

    // Combinational verification aligned directly with mac_done
    assign mac_valid = mac_done & (mac_out == received_mac);

endmodule