`timescale 1ns/1ps
// 译码/寄存器堆模块（RV32I 单周期）
// 功能：根据 ra/rb 组合读出操作数 rs1/rs2；
//       在 RegWr 有效且 rd!=x0 时，把写回数据写入 rd。
// 说明：
//   - RISC-V 写回地址统一为 inst[11:7]（rd），无需 MIPS 的 RegDst 选择；
//   - JAL/JALR 的链接地址 PC+4 由执行单元(ALU)计算，包含在 ALU_result 中，
//     因此本模块无需额外的 Link/PC_plus_4 通路；
//   - 立即数扩展已由 imm_gen32 完成，本模块不再做符号扩展。
module idcode32(
    input  [4:0]  ra,          // inst[19:15]  rs1 地址
    input  [4:0]  rb,          // inst[24:20]  rs2 地址
    input  [4:0]  rd,          // inst[11:7]   写回地址
    input  [31:0] ALU_result,  // 来自执行单元的运算结果
    input  [31:0] read_data,   // 来自数据存储器（load 数据）
    input         MemtoReg,    // 来自控制单元，1=写回 read_data（load）
    input         RegWr,       // 来自控制单元，寄存器写使能
    input         clock,reset, // 时钟与复位（低有效）
    output [31:0] rs1,         // 输出的第一个操作数
    output [31:0] rs2          // 输出的第二个操作数
);
    reg [31:0] register[0:31];  // 寄存器组共32个32位寄存器
    integer i;

    assign rs1 = register[ra];  // 组合读操作数1
    assign rs2 = register[rb];  // 组合读操作数2

    // 复位清零全部寄存器；RegWr 且 rd!=x0 时写回（x0 恒为 0）
    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            for (i = 0; i < 32; i = i + 1) register[i] <= 32'h0000_0000;
        end
        else if (RegWr && (rd != 5'b00000)) begin
            register[rd] <= MemtoReg ? read_data : ALU_result;
        end
    end

endmodule