`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/08/19
// Design Name:
// Module Name: dmemory32_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description: minisys_rv32 数据存储器 (dmemory32) 仿真
//              验证 SW/LW 往返、SB/LB/LBU、SH/LH/LHU 的字节/半字
//              读写与符号/零扩展，以及写数据按偏移对齐（修复后）
//
// Dependencies: dmemory32, ram（行为级 RAM 模型，见本文件末尾）
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module dmemory32_sim;

    // ---------- 输入 ----------
    reg         clock = 1'b0;
    reg         MemWr = 1'b0;         // 1=Store
    reg         MemtoReg = 1'b0;      // 本模块未使用
    reg  [2:0]  func3 = 3'b000;       // 000=LB/SB 001=LH/SH 010=LW/SW 100=LBU 101=LHU
    reg  [31:0] addr  = 32'h0;
    reg  [31:0] wdata = 32'h0;

    // ---------- 输出 ----------
    wire [31:0] rdata;

    dmemory32 Udmem (
        .clock   (clock  ),
        .MemWr   (MemWr  ),
        .MemtoReg(MemtoReg),
        .func3   (func3  ),
        .addr    (addr   ),
        .wdata   (wdata  ),
        .rdata   (rdata  )
    );

    // 时钟：周期 100ns（写发生在 clk=~clock 的正沿 = clock 的负沿 100,200,300,...）
    always #50 clock = ~clock;

    // ---------- 测试激励 ----------
    initial begin
        $display("== dmemory32 仿真开始 ==");

        // 1. SW: 写整个字 0x11223344 到 0x100
        MemWr = 1'b1; func3 = 3'b010; addr = 32'h00000100; wdata = 32'h11223344;
        #100;                                   // t=100：clk 正沿写入
        // LW: 读回整个字
        MemWr = 1'b0; func3 = 3'b010; addr = 32'h00000100;
        #10;
        $display("t=%0t [SW+LW] rdata=%h  期望 0x11223344", $time, rdata);

        // 2. SB: 写字节 0xAB 到 0x103（最高字节）
        MemWr = 1'b1; func3 = 3'b000; addr = 32'h00000103; wdata = 32'h000000AB;
        #100;                                   // t=210：写入 byte3
        // LBU: 零扩展读回
        MemWr = 1'b0; func3 = 3'b100; addr = 32'h00000103;
        #10;
        $display("t=%0t [SB+LBU] rdata=%h  期望 0x000000AB", $time, rdata);
        // LB: 符号扩展读回
        func3 = 3'b000; addr = 32'h00000103;
        #10;
        $display("t=%0t [LB]     rdata=%h  期望 0xFFFFFFAB", $time, rdata);

        // 3. SH: 写半字 0xCDEF 到 0x102（上半字，验证偏移对齐）
        MemWr = 1'b1; func3 = 3'b001; addr = 32'h00000102; wdata = 32'h0000CDEF;
        #100;                                   // t=330：写入 bytes2-3
        // LHU: 零扩展读回
        MemWr = 1'b0; func3 = 3'b101; addr = 32'h00000102;
        #10;
        $display("t=%0t [SH+LHU] rdata=%h  期望 0x0000CDEF", $time, rdata);
        // LH: 符号扩展读回
        func3 = 3'b001; addr = 32'h00000102;
        #10;
        $display("t=%0t [LH]     rdata=%h  期望 0xFFFFCDEF", $time, rdata);

        // 4. LW: 读回整个字（应为 0xCDEF3344：byte0=44 byte1=33 byte2=EF byte3=CD）
        func3 = 3'b010; addr = 32'h00000100;
        #10;
        $display("t=%0t [LW]     rdata=%h  期望 0xCDEF3344", $time, rdata);

        // 5. SH: 写负数半字 0xFFFF(-1) 到 0x100（下半字）
        MemWr = 1'b1; func3 = 3'b001; addr = 32'h00000100; wdata = 32'h0000FFFF;
        #100;                                   // t=450：写入 bytes0-1
        // LH: 符号扩展读回
        MemWr = 1'b0; func3 = 3'b001; addr = 32'h00000100;
        #10;
        $display("t=%0t [SH(-1)]  rdata=%h  期望 0xFFFFFFFF", $time, rdata);
        // LHU: 零扩展读回
        func3 = 3'b101; addr = 32'h00000100;
        #10;
        $display("t=%0t [LHU]     rdata=%h  期望 0x0000FFFF", $time, rdata);

        $display("== 仿真结束 ==");
        $finish;
    end

endmodule


// ============================================================================
// 行为级 RAM 模型（测试用，简单双端口：A 口同步写+字节使能，B 口组合读）
// 实际工程中 ram 为 Xilinx Block Memory Generator IP 核。
// 若使用 IP 核，请在 xsim 选项加 +define+RAM_IP 跳过本模型。
// ============================================================================


// `ifndef RAM_IP
// module ram (
//     input         clka,     // A 口时钟（写）
//     input         ena,      // A 口使能
//     input  [3:0]  wea,      // A 口字节写使能
//     input  [13:0] addra,    // A 口地址
//     input  [31:0] dina,     // A 口写数据
//     output [31:0] douta,    // A 口读数据
//     input         clkb,     // B 口时钟（读）
//     input         enb,      // B 口使能
//     input  [13:0] addrb,    // B 口地址
//     output [31:0] doutb     // B 口读数据
// );
//     reg [31:0] mem [0:16383];  // 64KB RAM = 16384 x 32bit
//     integer i;
//     initial for (i = 0; i < 16384; i = i + 1) mem[i] = 32'h00000000;

//     // A 口：同步写（带字节写使能）
//     always @(posedge clka) begin
//         if (wea[0]) mem[addra][7:0]   <= dina[7:0];
//         if (wea[1]) mem[addra][15:8]  <= dina[15:8];
//         if (wea[2]) mem[addra][23:16] <= dina[23:16];
//         if (wea[3]) mem[addra][31:24] <= dina[31:24];
//     end

//     // 组合读（便于仿真观察）
//     assign douta = mem[addra];
//     assign doutb = mem[addrb];
// endmodule
// `endif
