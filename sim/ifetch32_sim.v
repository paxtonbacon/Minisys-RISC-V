`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/08/16
// Design Name:
// Module Name: ifetch32_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description: minisys_rv32 取指单元 (ifetch32) 简易仿真
//              参考 minisys2.0/sim/ifetc32_sim.v 的写法：
//              只驱动 分支/跳转 控制信号，验证 PC/next_PC 的控制流，
//              不验证 ROM 中的指令内容（寄存器、DMEM、coe 尚未准备好）
//              PC_plus_4 为来自执行单元的顺序下一地址，测试台用 PC+4 模拟
//
// Dependencies: ifetch32, prgrom（行为级 ROM 模型，见本文件末尾）
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module ifetch32_sim;

    // ---------- 输入 ----------
    reg         clock = 1'b0;
    reg         reset = 1'b0;          // 低有效复位（与 minisys2.0 相反，注意！）
    reg  [1:0]  branch = 2'b00;        // 00=顺序 01=条件分支 10=JAL 11=JALR
    reg  [2:0]  func3  = 3'b000;       // 分支类型 inst[14:12]
    reg         less   = 1'b0;         // 有符号比较结果 (SLT)
    reg         lessu  = 1'b0;         // 无符号比较结果 (SLTU)
    reg         zero   = 1'b0;         // 相等比较结果
    reg  [31:0] Location_Result = 32'h00000000;  // 跳转地址（来自执行单元）

    // ---------- 输出 ----------
    wire [31:0] Instruction;
    wire [31:0] next_PC;

    // PC_plus_4：来自执行单元的顺序下一地址，等于当前 PC+4。
    // 执行单元尚未实现，测试台用 PC_probe+4 模拟 ALU 的计算结果。
    wire [31:0] PC_plus_4;
    assign PC_plus_4 = PC_probe + 32'd4;

    // 在测试台内跟踪内部 PC（与 ifetch32 内部 PC 同步：负沿更新）
    reg [31:0] PC_probe;
    always @(negedge clock or negedge reset) begin
        if (!reset) PC_probe <= 32'h00000000;
        else        PC_probe <= next_PC;
    end

    ifetch32 Uifetch (
        .Instruction    (Instruction    ),
        .next_PC        (next_PC        ),
        .clock          (clock          ),
        .reset          (reset          ),
        .branch         (branch         ),
        .func3          (func3          ),
        .less           (less           ),
        .lessu          (lessu          ),
        .zero           (zero           ),
        .Location_Result(Location_Result),
        .PC_plus_4      (PC_plus_4      )
    );

    // 时钟：周期 100ns（负沿位于 50,150,250,...）
    always #50 clock = ~clock;

    // ---------- 测试激励（参考 ifetc32_sim.v 的简单写法） ----------
    initial begin
        $display("== ifetch32 简易仿真开始 ==");

        // 1. 复位：PC 清零
        reset = 1'b0;
        #100;                                   // t=100（负沿@50 期间仍在复位）
        reset = 1'b1;
        $display("t=%0t 复位后  PC=%h next_PC=%h  期望 next_PC=PC+4=4", $time, PC_probe, next_PC);

        // 2. 顺序取指：PC 0->4->8->12->16
        #200;                                   // 负沿@150/250
        $display("t=%0t 顺序取指  PC=%h next_PC=%h", $time, PC_probe, next_PC);   // PC=8  next=12
        #200;                                   // 负沿@350/450
        $display("t=%0t 顺序取指  PC=%h next_PC=%h", $time, PC_probe, next_PC);   // PC=16 next=20

        // 3. beq 相等 -> 跳转到 Location_Result
        branch = 2'b01; func3 = 3'b000; zero = 1'b1;
        Location_Result = 32'h00000100;
        #200;                                   // 负沿@550/650
        $display("t=%0t beq跳转   PC=%h next_PC=%h  期望 PC=0x00000100", $time, PC_probe, next_PC);

        // 4. JAL (branch=10) -> 无条件跳转
        branch = 2'b10; Location_Result = 32'h00000800;
        #200;                                   // 负沿@750/850
        $display("t=%0t JAL      PC=%h next_PC=%h  期望 PC=0x00000800", $time, PC_probe, next_PC);

        // 5. JALR (branch=11) -> 无条件跳转
        branch = 2'b11; Location_Result = 32'h00000900;
        #200;                                   // 负沿@950/1050
        $display("t=%0t JALR     PC=%h next_PC=%h  期望 PC=0x00000900", $time, PC_probe, next_PC);

        // 6. 再次复位
        reset = 1'b0;
        #100;                                   // 负沿@1150
        $display("t=%0t 复位     PC=%h  期望 PC=0", $time, PC_probe);

        $display("== 仿真结束 ==");
        $finish;
    end

endmodule


// ============================================================================
// 行为级指令存储器模型（测试用，最简版：不预置程序，指令内容不验证）
// 若工程中已例化 prgrom IP 核，请在 xsim 选项加 +define+PRGROM_IP 跳过本模型
// ============================================================================


// `ifndef PRGROM_IP
// module prgrom (
//     input         clka,     // 时钟
//     input  [13:0] addra,    // 读地址 PC[15:2]
//     output [31:0] douta     // 读数据
// );
//     reg [31:0] mem [0:16383];  // 64KB ROM = 16384 x 32bit
//     integer i;
//     initial for (i = 0; i < 16384; i = i + 1) mem[i] = 32'h00000000;  // 全部清零
//     assign douta = mem[addra];                                        // 组合读
// endmodule
// `endif
