module hazard_detection_unit (

    input id_ex_mem_read,

    input [4:0] id_ex_rd,

    input [4:0] if_id_rs1,
    input [4:0] if_id_rs2,

    output reg pc_write,
    output reg if_id_write,
    output reg control_mux_sel

);

always @(*) begin

    // Default: normal execution
    pc_write = 1'b1;
    if_id_write = 1'b1;
    control_mux_sel = 1'b0;

    // =====================================================
    // Load-use hazard detection
    // =====================================================

    if (id_ex_mem_read &&
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2))) begin

        // Stall pipeline
        pc_write = 1'b0;

        // Freeze IF/ID register
        if_id_write = 1'b0;

        // Insert bubble
        control_mux_sel = 1'b1;

    end

end

endmodule