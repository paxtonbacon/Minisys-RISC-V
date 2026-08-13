`timescale 1ps/1ps

module imm_gen (
    input[24:0] imm,            // 来自取指单元inst[31:7]
    input[2:0] ExtOp,            // 来自控制单元
    output reg[31:0] imm_out     // 输出立即数
);
    
    always @(*) begin
        case (ExtOp)
            3'b000: imm_out = {21{imm[24]}, imm[23:13]}; // I-type
            3'b001: imm_out = {21{imm[24]}, imm[23:18], imm[4:0]}; // S-type
            3'b010: imm_out = {20{imm[24]}, imm[0],imm[23:18], imm[4:1], 1'b0}; // B-type
            3'b011: imm_out = {imm[24], imm[23:5],12{1'b0}}; // U-type
            3'b100: imm_out = {12{imm[24]}, imm[12:5], imm[13], imm[23:14], 1'b0}; // J-type
            default: imm_out = 32'b0;
        endcase
    end
    
endmodule