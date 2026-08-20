`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/08/19
// Design Name:
// Module Name: execute32_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description: minisys_rv32 执行单元 (execute32) 仿真
//              纯组合逻辑，验证 ALU 各运算(ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/
//              SLT/SLTU)、比较输出 less/lessu/zero、LUI/AUIPC、
//              JAL/JALR/Branch 跳转地址以及 pc_plus_4 输出
//
// Dependencies: execute32
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module execute32_sim;

    // ---------- 输入 ----------
    reg  [1:0]  branch = 2'b00;      // 00=顺序 01=条件分支 10=JAL 11=JALR
    reg  [2:0]  func3  = 3'b000;     // inst[14:12]
    reg  [6:0]  func7  = 7'b0000000; // inst[31:25]
    reg  [31:0] rs1 = 32'h0;
    reg  [31:0] rs2 = 32'h0;
    reg  [31:0] imm = 32'h0;
    reg  [31:0] PC  = 32'h0;
    reg         ALUctr  = 1'b0;      // 1=ALU操作指令
    reg         ALUASrc = 1'b0;      // 1=第一个操作数取PC
    reg         LUI     = 1'b0;      // 1=LUI
    reg  [1:0]  ALUBSrc = 2'b01;     // 00=imm 01=rs2 10=4

    // ---------- 输出 ----------
    wire [31:0] ALU_result;
    wire        less;
    wire        lessu;
    wire        zero;
    wire [31:0] Location_Result;
    wire [31:0] pc_plus_4;

    execute32 Uexe (
        .branch         (branch         ),
        .func3          (func3          ),
        .func7          (func7          ),
        .rs1            (rs1            ),
        .rs2            (rs2            ),
        .imm            (imm            ),
        .PC             (PC             ),
        .ALUctr         (ALUctr         ),
        .ALUASrc        (ALUASrc        ),
        .LUI            (LUI            ),
        .ALUBSrc        (ALUBSrc        ),
        .ALU_result     (ALU_result     ),
        .less           (less           ),
        .lessu          (lessu          ),
        .zero           (zero           ),
        .Location_Result(Location_Result),
        .pc_plus_4      (pc_plus_4      )
    );

    // 纯组合逻辑，无需时钟，直接按延时观察
    initial begin
        $display("== execute32 仿真开始 ==");

        // 1. ADD: rs1+rs2
        ALUctr=1'b1; ALUASrc=1'b0; LUI=1'b0; ALUBSrc=2'b01;
        func7=7'b0000000; func3=3'b000;
        rs1=32'h10; rs2=32'h05; imm=32'h0; PC=32'h100; branch=2'b00;
        #10;
        $display("t=%0t [ADD]  ALU=%h less=%b lessu=%b zero=%b  期望 ALU=0x15", $time, ALU_result, less, lessu, zero);

        // 2. SUB: rs1-rs2
        func7=7'b0100000; func3=3'b000;
        rs1=32'h10; rs2=32'h05;
        #10;
        $display("t=%0t [SUB]  ALU=%h  期望 0x0B", $time, ALU_result);

        // 3. AND
        func7=7'b0000000; func3=3'b111;
        rs1=32'h10; rs2=32'h05;
        #10;
        $display("t=%0t [AND]  ALU=%h  期望 0x00", $time, ALU_result);

        // 4. OR
        func3=3'b110;
        #10;
        $display("t=%0t [OR]   ALU=%h  期望 0x15", $time, ALU_result);

        // 5. XOR
        func3=3'b100;
        #10;
        $display("t=%0t [XOR]  ALU=%h  期望 0x15", $time, ALU_result);

        // 6. SLL: rs1<<rs2[4:0]
        func3=3'b001;
        rs1=32'h1; rs2=32'h4;
        #10;
        $display("t=%0t [SLL]  ALU=%h  期望 0x10", $time, ALU_result);

        // 7. SRL: rs1>>rs2[4:0]
        func3=3'b101; func7=7'b0000000;
        rs1=32'h10; rs2=32'h2;
        #10;
        $display("t=%0t [SRL]  ALU=%h  期望 0x04", $time, ALU_result);

        // 8. SRA: 算术右移（符号扩展）
        func7=7'b0100000;
        rs1=32'h80000000; rs2=32'h4;
        #10;
        $display("t=%0t [SRA]  ALU=%h  期望 0xF8000000", $time, ALU_result);

        // 9. SLT: 有符号比较
        func7=7'b0000000; func3=3'b010;
        rs1=32'hFFFFFFFF; rs2=32'h0;
        #10;
        $display("t=%0t [SLT]  ALU=%h less=%b  期望 ALU=1, less=1", $time, ALU_result, less);

        // 10. SLTU: 无符号比较
        func3=3'b011;
        rs1=32'hFFFFFFFF; rs2=32'h0;
        #10;
        $display("t=%0t [SLTU] ALU=%h lessu=%b  期望 ALU=0, lessu=0", $time, ALU_result, lessu);

        // 11. ADDI: rs1+imm
        func3=3'b000; ALUBSrc=2'b00;
        rs1=32'h10; imm=32'hFFFFFFF6;
        #10;
        $display("t=%0t [ADDI] ALU=%h  期望 0x06", $time, ALU_result);

        // 12. LUI: ALU_A=0, ALU_B=imm（U型已<<12）
        LUI=1'b1; ALUASrc=1'b0; ALUBSrc=2'b00;
        imm=32'h12345000; rs1=32'h0;
        #10;
        $display("t=%0t [LUI]  ALU=%h  期望 0x12345000", $time, ALU_result);

        // 13. AUIPC: PC+imm（U型已<<12）
        LUI=1'b0; ALUASrc=1'b1; ALUBSrc=2'b00;
        PC=32'h100; imm=32'h12345000;
        #10;
        $display("t=%0t [AUIPC] ALU=%h  期望 0x12345100", $time, ALU_result);

        // 14. JAL: 链接地址 ALU=PC+4，跳转目标 Loc=PC+imm
        branch=2'b10; ALUASrc=1'b1; ALUBSrc=2'b10;
        PC=32'h100; imm=32'h20;
        #10;
        $display("t=%0t [JAL]  ALU=%h Loc=%h pc+4=%h  期望 ALU=0x104, Loc=0x120", $time, ALU_result, Location_Result, pc_plus_4);

        // 15. JALR: 目标=(rs1+imm)&~1
        branch=2'b11; rs1=32'h100; imm=32'h20;
        #10;
        $display("t=%0t [JALR] Loc=%h  期望 Loc=0x120", $time, Location_Result);

        // 16. Branch(beq): 目标=PC+imm（B型已<<1）
        branch=2'b01; rs1=32'h0; PC=32'h100; imm=32'h8;
        #10;
        $display("t=%0t [BEQ]  Loc=%h  期望 Loc=0x108", $time, Location_Result);

        // 17. ALUctr=0: ALU 结果与比较输出清零
        ALUctr=1'b0; branch=2'b00;
        rs1=32'h10; rs2=32'h05;
        #10;
        $display("t=%0t [noALU] ALU=%h less=%b lessu=%b zero=%b  期望全0", $time, ALU_result, less, lessu, zero);

        $display("== 仿真结束 ==");
        $finish;
    end

endmodule
