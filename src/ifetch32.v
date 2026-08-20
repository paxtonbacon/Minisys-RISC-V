`timescale 1ns/1ps
// 实现取指模块
// 该模块的主要功能是根据PC寄存器的值从指令存储器中取出对应的指令，并计算下一条指令的地址
module ifetch32(
    output[31:0] Instruction,			      // 输出指令到其他模块
    output[31:0] next_PC,                // 输出下一条指令的地址
    output[31:0]  PC_out,                    // 输出当前PC值
    input        clock,reset,           // 时钟与复位（reset 低有效）
    input[1:0]   branch,                // 来自控制单元：00=顺序 01=条件分支 10=JAL 11=JALR
    input[2:0]   func3,                 // 表示分支类型 inst[14:12]
    input        less,                  // 来自执行单元，有符号比较结果 (SLT)
    input        lessu,                 // 来自执行单元，无符号比较结果 (SLTU)
    input        zero,                  // 来自执行单元，表示比较结果
    input[31:0]  Location_Result,        // 地址计算结果，来自执行单元
    input[31:0]  PC_plus_4                // 来自执行单元，表示PC+4的值
);
    reg[31:0]	   PC;                    // PC寄存器（程序计数器）
    reg[31:0]    next_PC;               // 在 always 块中被赋值，必须声明为 reg

   //分配64KB ROM，编译器实际只用 64KB ROM
    prgrom instmem(
        .clka(clock),         // input wire clka
        .addra(PC[15:2]),     // input wire [13 : 0] addra
        // 这个是PC即取ROM的地址
        .douta(Instruction)         // output wire [31 : 0] douta
        // 这个是将取到的地址存在instruction中
    );

    
    always @(*) begin
        if (branch == 2'b01) begin
            case (func3)
                3'b000: next_PC = zero ? Location_Result : PC_plus_4;           // beq
                3'b001: next_PC = zero ? PC_plus_4 : Location_Result;           // bne（不等就跳）
                3'b100: next_PC = less ? Location_Result : PC_plus_4;           // blt
                3'b101: next_PC = less ? PC_plus_4 : Location_Result;           // bge（大于等于就跳）
                3'b110: next_PC = lessu ? Location_Result : PC_plus_4;          // bltu
                3'b111: next_PC = lessu ? PC_plus_4 : Location_Result;          // bgeu
                default: next_PC = PC_plus_4;
            endcase
        end
        else if (branch == 2'b10 || branch == 2'b11) begin
            next_PC = Location_Result;
        end
        else begin
            next_PC = PC_plus_4; // 默认情况下，下一条指令的地址为当前PC加4
        end
    end

    // 在时钟下降沿更新PC寄存器的值（异步复位，reset 低有效）
    always @(negedge clock or negedge reset) begin
        if (!reset) begin
            PC <= 32'h0000_0000; // 复位时将PC寄存器清零
        end
        else begin
            PC <= next_PC; // 否则更新PC寄存器的值为下一条指令的地址
        end
    end

    assign PC_out = PC; // 将当前PC值输出到其他模块

endmodule