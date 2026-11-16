module ShiftRows (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    // AES state is mapped to a 128-bit vector in column-major order.
    // Bytes are sliced as [MSB:LSB]. 
    // Example: s_{0,0} is [127:120], s_{1,0} is [119:112], etc.
    
    assign state_out = {
        // Output Column 0 (c = 0)
        state_in[127:120], // s'_{0,0} = s_{0,0} (Row 0 unchanged)
        state_in[87:80],   // s'_{1,0} = s_{1,1} (Row 1 shifted left by 1)
        state_in[47:40],   // s'_{2,0} = s_{2,2} (Row 2 shifted left by 2)
        state_in[7:0],     // s'_{3,0} = s_{3,3} (Row 3 shifted left by 3)

        // Output Column 1 (c = 1)
        state_in[95:88],   // s'_{0,1} = s_{0,1} (Row 0 unchanged)
        state_in[55:48],   // s'_{1,1} = s_{1,2} (Row 1 shifted left by 1)
        state_in[15:8],    // s'_{2,1} = s_{2,3} (Row 2 shifted left by 2)
        state_in[103:96],  // s'_{3,1} = s_{3,0} (Row 3 shifted left by 3)

        // Output Column 2 (c = 2)
        state_in[63:56],   // s'_{0,2} = s_{0,2} (Row 0 unchanged)
        state_in[23:16],   // s'_{1,2} = s_{1,3} (Row 1 shifted left by 1)
        state_in[111:104], // s'_{2,2} = s_{2,0} (Row 2 shifted left by 2)
        state_in[71:64],   // s'_{3,2} = s_{3,1} (Row 3 shifted left by 3)

        // Output Column 3 (c = 3)
        state_in[31:24],   // s'_{0,3} = s_{0,3} (Row 0 unchanged)
        state_in[119:112], // s'_{1,3} = s_{1,0} (Row 1 shifted left by 1)
        state_in[79:72],   // s'_{2,3} = s_{2,1} (Row 2 shifted left by 2)
        state_in[39:32]    // s'_{3,3} = s_{3,2} (Row 3 shifted left by 3)
    };

endmodule