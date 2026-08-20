`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/08/13
// Design Name:
// Module Name: control32_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description: minisys_rv32 控制单元 (control32) 仿真测试
//              依次测试 R-type / I-type / Load / Store / Branch /
//              JAL / JALR / LUI / AUIPC 各指令的解码输出
//
// Dependencies: control32
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module control32_sim;

    // 输入
    reg [6:0] Opcode = 7'b0000000;   // 来自取指单元 inst[6:0]

    // 输出
    wire [2:0] ExtOp;     // 立即数扩展方式: 000=I 001=S 010=B 011=U 100=J
    wire       RegWr;     // 写寄存器使能
    wire       MemWr;     // 写存储器使能
    wire       MemOp;     // 存储器操作指令指示
    wire       MemtoReg;  // 从存储器读数据到寄存器
    wire       ALUASrc;   // ALU 第一个操作数选择 (为1时取 PC)
    wire [1:0] ALUBSrc;   // ALU 第二个操作数选择 (00=reg/imm 01=reg 10=4)
    wire       LUI;       // 是否为 LUI 指令
    wire       ALUctr;    // 是否为 ALU 操作指令
    wire [1:0] Branch;    // 是否为分支指令

    control32 Uctrl (
        .Opcode  (Opcode  ),
        .ExtOp   (ExtOp   ),
        .RegWr   (RegWr   ),
        .MemWr   (MemWr   ),
        .MemOp   (MemOp   ),
        .MemtoReg(MemtoReg),
        .ALUASrc (ALUASrc ),
        .ALUBSrc (ALUBSrc ),
        .LUI     (LUI     ),
        .ALUctr  (ALUctr  ),
        .Branch  (Branch  )
    );

    initial begin
        $monitor($time,, "Opcode=%b  ExtOp=%b RegWr=%b MemWr=%b MemtoReg=%b ALUASrc=%b ALUBSrc=%b ALUctr=%b Branch=%b LUI=%b",
                 Opcode, ExtOp, RegWr, MemWr, MemtoReg, ALUASrc, ALUBSrc, ALUctr, Branch, LUI);

        // 初始状态（无指令）
        Opcode = 7'b0000000;
        #200;

        // R-type: ADD (opcode = 0110011)
        Opcode = 7'b0110011;
        #200;

        // I-type: ADDI (opcode = 0010011)
        Opcode = 7'b0010011;
        #200;

        // Load: LW (opcode = 0000011)
        Opcode = 7'b0000011;
        #200;

        // Store: SW (opcode = 0100011)
        Opcode = 7'b0100011;
        #200;

        // Branch: BEQ (opcode = 1100011)
        Opcode = 7'b1100011;
        #200;

        // JAL (opcode = 1101111)
        Opcode = 7'b1101111;
        #200;

        // JALR (opcode = 1100111)
        Opcode = 7'b1100111;
        #200;

        // LUI (opcode = 0110111)
        Opcode = 7'b0110111;
        #200;

        // AUIPC (opcode = 0010111)
        Opcode = 7'b0010111;
        #200;

        $finish;
    end

endmodule
