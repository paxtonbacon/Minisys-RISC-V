`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/08/13
// Design Name:
// Module Name: imm_gen32_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description: minisys_rv32 立即数扩展单元 (imm_gen) 仿真测试
//              依次测试 I-type / S-type / B-type / U-type / J-type
//              及 default 分支的立即数扩展结果
//
// Dependencies: imm_gen32
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module imm_gen32_sim;

    // 输入
    reg [24:0] imm;              // 来自取指单元 inst[31:7]
    reg [2:0]  ExtOp;            // 来自控制单元: 000=I 001=S 010=B 011=U 100=J
    // 输出
    wire [31:0] imm_out;         // 扩展后的 32 位立即数

    // 用完整指令便于核对 (imm = inst[31:7])
    reg [31:0] inst;

    imm_gen Uimmgen (
        .imm    (inst[31:7] ),
        .ExtOp  (ExtOp      ),
        .imm_out(imm_out    )
    );

    initial begin
        $monitor($time,, "ExtOp=%b inst=%h  imm_out=%h",
                 ExtOp, inst, imm_out);

        // 1. I-type: addi x1, x2, 10    (imm = 0x00A -> 0x0000000A)
        ExtOp = 3'b000;
        inst  = 32'h00208093;
        #200;

        // 2. I-type: addi x1, x2, -10   (imm = 0xFF6 -> 0xFFFFFFF6)
        ExtOp = 3'b000;
        inst  = 32'hFF608093;
        #200;

        // 3. S-type: sw x1, 10(x2)      (imm = 0x00A -> 0x0000000A)
        ExtOp = 3'b001;
        inst  = 32'h00112523;
        #200;

        // 4. S-type: sw x1, -10(x2)     (imm = 0xFF6 -> 0xFFFFFFF6)
        ExtOp = 3'b001;
        inst  = 32'hFE112B23;
        #200;

        // 5. B-type: beq x1, x2, +8     (offset=8 -> 0x00000008)
        ExtOp = 3'b010;
        inst  = 32'h00110463;
        #200;

        // 6. B-type: beq x1, x2, -8     (offset=-8 -> 0xFFFFFFF8)
        ExtOp = 3'b010;
        inst  = 32'hFE110EE3;
        #200;

        // 7. U-type: lui x1, 0x12345    (imm<<12 -> 0x12345000)
        ExtOp = 3'b011;
        inst  = 32'h123450B7;
        #200;

        // 8. U-type: auipc x1, 0x12345  (imm<<12 -> 0x12345000)
        ExtOp = 3'b011;
        inst  = 32'h12345097;
        #200;

        // 9. J-type: jal x1, +32        (offset=32 -> 0x00000020)
        ExtOp = 3'b100;
        inst  = 32'h020010EF;
        #200;

        // 10. J-type: jal x1, -32       (offset=-32 -> 0xFFFFFFE0)
        ExtOp = 3'b100;
        inst  = 32'h801FF0EF;
        #200;

        // 11. default: 未定义扩展类型 -> 0
        ExtOp = 3'b111;
        inst  = 32'h00208093;
        #200;

        $finish;
    end

endmodule
