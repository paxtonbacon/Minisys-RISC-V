`timescale 1ps/1ps

module control32 (
    input[6:0] Opcode,            // 来自取指单元inst[6:0]
    output [2:0] ExtOp,          // 为1表明该指令是立即数扩展指令
    output RegWr,        // 为1表明该指令需要写寄存器
    output MemWr,        // 为1表明该指令需要写存储器
    // output MemOp,        // 为1表明该指令是存储器操作指令
    output MemtoReg,     // 为1表明该指令是从存储器读取数据到寄存器
    output ALUASrc,      // 为1表明ALU的第一个操作数是立即数
    output [1:0] ALUBSrc,      // 00=立即数 01=寄存器 10=常数4
    output LUIcode,         // 为1表明该指令是LUI指令
    output ALUctr,      // 为1表明该指令是ALU操作指令
    output [1:0] Branch      // 为1表明该指令是分支指令
);
    localparam [6:0] R_TYPE = 7'b0110011;
    localparam [6:0] I_TYPE = 7'b0010011;
    localparam [6:0] LOAD = 7'b0000011;
    localparam [6:0] STORE = 7'b0100011;
    localparam [6:0] BRANCH = 7'b1100011;
    localparam [6:0] JAL = 7'b1101111;
    localparam [6:0] JALR = 7'b1100111;
    localparam [6:0] LUI = 7'b0110111;
    localparam [6:0] AUIPC = 7'b0010111;

    assign ExtOp = (Opcode == I_TYPE || Opcode == LOAD || Opcode == JALR) ? 3'b000 : // I-type
                   (Opcode == STORE) ? 3'b001 : // S-type
                   (Opcode == BRANCH) ? 3'b010 : // B-type
                   (Opcode == LUI || Opcode == AUIPC) ? 3'b011 : // U-type
                   (Opcode == JAL) ? 3'b100 : // J-type
                   3'b000; // default
    assign RegWr = (Opcode == R_TYPE || Opcode == I_TYPE || Opcode == LOAD || Opcode == JAL || 
                    Opcode == JALR || Opcode == LUI || Opcode == AUIPC) ? 1'b1 : 1'b0;
    assign MemWr = (Opcode == STORE) ? 1'b1 : 1'b0;
    // assign MemOp = (Opcode == LOAD || Opcode == STORE) ? 1'b1 : 1'b0;  //如果不在这里进行func3译码，那么其实没有必要有这个
    assign MemtoReg = (Opcode == LOAD) ? 1'b1 : 1'b0;
    assign ALUASrc = (Opcode == JAL || Opcode == JALR || Opcode == AUIPC) ? 1'b1 : 1'b0; //（取1时是PC作为第一个操作数）
    assign ALUBSrc = (Opcode == I_TYPE || Opcode == LOAD || Opcode == STORE || Opcode == LUI || Opcode == AUIPC) ? 2'b00 : // 00=立即数
                     (Opcode == R_TYPE || Opcode == BRANCH) ? 2'b01 : // 01=寄存器
                     (Opcode == JAL || Opcode == JALR) ? 2'b10 : // 10=常数4（jal/jalr 算 PC+4）
                     2'b00; // default
    assign LUIcode = (Opcode == LUI) ? 1'b1 : 1'b0;
    assign ALUctr = (Opcode == R_TYPE || Opcode == I_TYPE || Opcode == LOAD
                    || Opcode == STORE || Opcode == BRANCH || Opcode == JAL  
                    ||  Opcode == JALR || Opcode == LUI || Opcode == AUIPC) ? 1'b1 : 1'b0; //所有需要调用ALU的指令都需要ALUctr为1
    assign Branch = (Opcode == BRANCH) ? 2'b01 :
                    (Opcode == JAL) ? 2'b10 : // jal
                    (Opcode == JALR) ? 2'b11 : // jalr
                     2'b00; // default
endmodule