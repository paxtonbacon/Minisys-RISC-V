`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/08/19
// Design Name:
// Module Name: minisys_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 单周期 RV32I 整机 (minisys) 仿真
//              测试程序：
//                0:  addi x1,x0,5     # x1=5
//                4:  addi x2,x0,3     # x2=3
//                8:  add  x3,x1,x2    # x3=8
//                12: sw   x3,0(x0)    # mem[0]=8
//                16: lw   x4,0(x0)    # x4=8
//                20: beq  x3,x4,8     # 相等 -> 跳到 28
//                24: addi x5,x0,100   # 被跳过
//                28: jal  x0,8        # 跳到 36
//                32: addi x6,x0,200   # 被跳过
//                36: sub  x7,x4,x1    # x7=3
//                40: jal  x0,0        # 死循环
//              期望：x1=5 x2=3 x3=8 x4=8 x5=0 x6=0 x7=3 PC=40（mem[0]=8 由 x4 验证）
//
// Dependencies: minisys 及其所有子模块；prgrom/ram 使用工程内的 Xilinx IP
//               （行为级模型已注释；如需用行为模型请恢复并用宏切换）
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module minisys_sim;

    // ---------- 输入 ----------
    reg         clk = 1'b0;
    reg         reset = 1'b1;       // 低有效复位，先无效
    // ---------- 输出 ----------
    wire [31:0] Instruction;
    wire [31:0] PC;

    integer cnt;   // 轮询/超时计数

    minisys Uminisys (
        .clk        (clk),
        .reset      (reset),
        .Instruction(Instruction),
        .PC         (PC)
    );

    // 时钟：周期 100ns（PC 在负沿更新，寄存器堆在正沿写回）
    always #50 clk = ~clk;

    // ---------- 主激励 ----------
    initial begin
        // 复位：断言(低) -> 保持 -> 释放
        #5;
        reset = 1'b0;    // 断言复位（负沿触发 PC/寄存器堆异步清零）
        #10;
        reset = 1'b1;    // 释放复位

        // 等待程序跑到死循环 PC=0x28（含超时保护，避免 IP 时序差异导致死等）
        cnt = 0;
        while (Uminisys.PC !== 32'h28 && cnt < 4000) begin
            #5;
            cnt = cnt + 1;
        end
        if (cnt >= 4000)
            $display(">>> 超时：PC 未到 0x28，当前 PC=%h <<<", Uminisys.PC);

        // 多等几拍让最后一个写回（x7=3）稳定
        #300;

        // 打印最终状态（寄存器堆是纯 Verilog，可用层次引用；存储器经 x4 验证）
        $display("--- 最终状态 ---");
        $display("x1=%h x2=%h x3=%h   (期望 5 3 8)",
                 Uminisys.u_id.register[1], Uminisys.u_id.register[2], Uminisys.u_id.register[3]);
        $display("x4=%h x5=%h x6=%h x7=%h   (期望 8 0 0 3；mem[0]=8 由 x4 经 lw 验证)",
                 Uminisys.u_id.register[4], Uminisys.u_id.register[5],
                 Uminisys.u_id.register[6], Uminisys.u_id.register[7]);
        $display("PC=%h   (期望 0x28=40)", PC);

        // 自动校验（不再直读 IP 内部存储器）
        if (Uminisys.u_id.register[1] == 32'h5 &&
            Uminisys.u_id.register[2] == 32'h3 &&
            Uminisys.u_id.register[3] == 32'h8 &&
            Uminisys.u_id.register[4] == 32'h8 &&
            Uminisys.u_id.register[5] == 32'h0 &&
            Uminisys.u_id.register[6] == 32'h0 &&
            Uminisys.u_id.register[7] == 32'h3)
            $display(">>> PASS：整机指令执行正确（x4=8 验证 mem[0]=8）<<<");
        else
            $display(">>> FAIL：结果有误，请检查 <<<");

        $finish;
    end

    // ---------- 打印 PC/指令执行流（复位释放后再开始） ----------
    initial begin
        #40;
        $monitor("t=%0t  PC=%h  Inst=%h", $time, Uminisys.PC, Uminisys.Instruction);
    end

endmodule


// ============================================================================
// 行为级指令存储器 prgrom（测试用，装载测试程序）
// 实际工程中为 Xilinx Block Memory Generator IP；使用 IP 时加 +define+PRGROM_IP
// ============================================================================


//`ifndef PRGROM_IP
//module prgrom (
//    input         clka,     // 时钟
//    input  [13:0] addra,    // 读地址 PC[15:2]
//    output [31:0] douta     // 读数据
//);
//    reg [31:0] mem [0:16383];  // 64KB ROM = 16384 x 32bit

//    initial begin
//        mem[0]  = 32'h00500093; // addi x1,x0,5
//        mem[1]  = 32'h00300113; // addi x2,x0,3
//        mem[2]  = 32'h002081B3; // add  x3,x1,x2
//        mem[3]  = 32'h00302023; // sw   x3,0(x0)
//        mem[4]  = 32'h00002203; // lw   x4,0(x0)
//        mem[5]  = 32'h00418263; // beq  x3,x4,8  -> 28
//        mem[6]  = 32'h06400293; // addi x5,x0,100（被跳过）
//        mem[7]  = 32'h0080006F; // jal  x0,8     -> 36
//        mem[8]  = 32'h0C800313; // addi x6,x0,200（被跳过）
//        mem[9]  = 32'h401203B3; // sub  x7,x4,x1
//        mem[10] = 32'h0000006F; // jal  x0,0（死循环）
//    end

//    assign douta = mem[addra];  // 组合读
//endmodule
//`endif


// ============================================================================
// 行为级数据存储器 ram（测试用，A 口同步字节写 + 组合读）
// 实际工程中为 Xilinx Block Memory Generator IP；使用 IP 时加 +define+RAM_IP
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
//     reg [31:0] wd;
//     initial for (i = 0; i < 16384; i = i + 1) mem[i] = 32'h00000000;

//     // A 口：同步写（读-改-写，保证与字节使能兼容）
//     always @(posedge clka) begin
//         if (|wea) begin
//             wd = mem[addra];
//             if (wea[0]) wd[7:0]   = dina[7:0];
//             if (wea[1]) wd[15:8]  = dina[15:8];
//             if (wea[2]) wd[23:16] = dina[23:16];
//             if (wea[3]) wd[31:24] = dina[31:24];
//             mem[addra] <= wd;
//         end
//     end

//     // 组合读
//     assign douta = mem[addra];
//     assign doutb = mem[addrb];
// endmodule
// `endif
