`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/08/16
// Design Name:
// Module Name: idcode32_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description: minisys_rv32 译码/寄存器堆 (idcode32) 仿真
//              验证 复位清零、ALU/load 两种写回数据（JAL 链接地址由
//              ALU_result 提供）、x0 恒0保护、RegWr=0 不写、组合读
//
// Dependencies: idcode32
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module idcode32_sim;

    // ---------- 输入 ----------
    reg  [4:0]  ra = 5'b00001;        // rs1 地址
    reg  [4:0]  rb = 5'b00010;        // rs2 地址
    reg  [4:0]  rd = 5'b00000;        // 写回地址
    reg  [31:0] ALU_result = 32'h0;   // 执行单元结果（含 JAL 的 PC+4）
    reg  [31:0] read_data  = 32'h0;   // load 数据
    reg         MemtoReg = 1'b0;      // 1=写回 read_data
    reg         RegWr    = 1'b0;      // 写使能
    reg         clock = 1'b0;
    reg         reset = 1'b0;         // 低有效复位

    // ---------- 输出 ----------
    wire [31:0] rs1;
    wire [31:0] rs2;

    idcode32 Uid (
        .ra        (ra        ),
        .rb        (rb        ),
        .rd        (rd        ),
        .ALU_result(ALU_result),
        .read_data (read_data ),
        .MemtoReg  (MemtoReg  ),
        .RegWr     (RegWr     ),
        .clock     (clock     ),
        .reset     (reset     ),
        .rs1       (rs1       ),
        .rs2       (rs2       )
    );

    // 时钟：周期 100ns（正沿位于 50,150,250,...）
    always #50 clock = ~clock;

    // ---------- 测试激励 ----------
    initial begin
        $display("== idcode32 仿真开始 ==");

        // 1. 复位：全部寄存器清零，rs1/rs2 应为 0
        reset = 1'b0;
        #100;                                   // posedge@50 期间复位，t=100 释放
        reset = 1'b1;
        $display("t=%0t [复位]      rs1=%h rs2=%h  期望 rs1=rs2=0", $time, rs1, rs2);

        // 2. 写 R 型结果（MemtoReg=0）：rd=1 <- ALU_result=0x10
        rd = 5'd1; RegWr = 1'b1; MemtoReg = 1'b0;
        ALU_result = 32'h00000010; read_data = 32'h0;
        #100;                                   // posedge@150 写寄存器1
        $display("t=%0t [R型写回]   rs1=%h  期望 0x10", $time, rs1);

        // 3. 写 load 数据（MemtoReg=1）：rd=2 <- read_data=0x7B
        rd = 5'd2; MemtoReg = 1'b1;
        ALU_result = 32'h54; read_data = 32'h0000007B;
        #100;                                   // posedge@250 写寄存器2
        $display("t=%0t [load写回]  rs2=%h  期望 0x7B", $time, rs2);

        // 4. JAL 链接地址由 ALU 算出，经 ALU_result 写回：rd=3 <- ALU_result=0x20
        rb = 5'd3; rd = 5'd3; MemtoReg = 1'b0;
        ALU_result = 32'h00000020; read_data = 32'h0;
        #100;                                   // posedge@350 写寄存器3
        $display("t=%0t [JAL写回]   rs2=%h  期望 0x20", $time, rs2);

        // 5. 写 x0 被屏蔽：rd=0, RegWr=1 -> register[0] 恒 0
        ra = 5'd0; rd = 5'd0;
        ALU_result = 32'h000000FF;
        #100;                                   // posedge@450（不应写 x0）
        $display("t=%0t [x0屏蔽]    rs1=%h  期望 0", $time, rs1);

        // 6. RegWr=0 不写：rd=1 保持 0x10 不变
        ra = 5'd1; rd = 5'd1; RegWr = 1'b0;
        ALU_result = 32'h00000099;
        #100;                                   // posedge@550（不写）
        $display("t=%0t [RegWr=0]   rs1=%h  期望 0x10（不变）", $time, rs1);

        $display("== 仿真结束 ==");
        $finish;
    end

endmodule
