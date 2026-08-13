`timescale 1ps/1ps

module control32 (
    input[6:0] Opcode,            // 来自取指单元inst[6:0]
    input[2:0] Funct3,            // 来自取指单元inst[14:12]
    input[6:0] Funct7,            // 来自取指单元inst[31:25]
    output reg [2:0] ExtOp,          // 为1表明该指令是立即数扩展指令
    output reg RegWr,        // 为1表明该指令需要写寄存器
    output reg MemWr,        // 为1表明该指令需要写存储器
    output reg MemOp,        // 为1表明该指令是存储器操作指令
    output reg MemtoReg,     // 为1表明该指令是从存储器读取数据到寄存器
    output reg ALUASrc,      // 为1表明ALU的第一个操作数是立即数
    output reg [1:0] ALUBSrc,      // 为1表明ALU的第二个操作数是立即数
    output reg ALUctr,      // 为1表明该指令是ALU操作指令
    output reg Branch,       // 为1表明该指令是分支指令   
);


    assign ExtOp = (Opcode == 7'b0010011 || Opcode == 7'b0000011) ? 3'b000 : // I-type
                   (Opcode == 7'b0100011) ? 3'b001 : // S-type
                   (Opcode == 7'b1100011) ? 3'b010 : // B-type
                   (Opcode == 7'b0110111 || Opcode == 7'b0010111) ? 3'b011 : // U-type
                   (Opcode == 7'b1101111) ? 3'b100 : // J-type
                   3'b000; // default
    assign RegWr = (Opcode == 7'b0110011 || Opcode == 7'b0010011 || Opcode == 7'b0000011 || Opcode == 7'b1101111 || Opcode == 7'b0010111) ? 1'b1 : 1'b0;
    assign MemWr = (Opcode == 7'b0100011) ? 1'b1 : 1'b0;
    assign MemOp = (Opcode == 7'b0000011 || Opcode == 7'b0100011) ? 1'b1 : 1'b0;
    assign MemtoReg = (Opcode == 7'b0000011) ? 1'b1 : 1'b0;
    assign ALUASrc = (Opcode == 7'b0010011 || Opcode ==
        7'b0000011 || Opcode == 7'b0100011 || Opcode == 7'b1101111 || Opcode == 7'b0010111) ? 1'b1 : 1'b0;
    assign ALUBSrc = (Opcode == 7'b0010011 || Opcode == 7'b0000011 || Opcode == 7'b0100011 || Opcode == 7'b1101111 || Opcode == 7'b0010111) ? 2'b01 : // I-type, S-type, JAL, AUIPC
                     (Opcode == 7'b0110011) ? 2'b00 : // R-type
                     (Opcode == 7'b1100011) ? 2'b10 : // B-type
                     2'b00; // default
    assign ALUctr = (Opcode == 7'b0110011 || Opcode == 7'b0010011) ? 1'b1 : 1'b0;
    assign Branch = (Opcode == 7'b1100011) ? 1'b1 : 1'b0;
endmodule