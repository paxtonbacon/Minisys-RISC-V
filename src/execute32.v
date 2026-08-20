`timescale 1ns/1ps

module execute32(
    input[1:0] branch,                // 来自控制单元：00=顺序 01=条件分支 10=JAL 11=JALR
    input[2:0] func3,                 // 表示分支类型 inst[14:12]
    input[6:0] func7,                 // 表示指令类型 inst[31:25]
    input[31:0] rs1,                  // 来自寄存器堆的操作数1
    input[31:0] rs2,                  // 来自寄存器堆
    input[31:0] imm,                  // 来自立即数生成模块的立即数
    input[31:0] PC,                   // 来自取指单元的当前PC值
    input ALUctr,                      // 来自控制单元，1=ALU操作指令
    input ALUASrc,                    // 来自控制单元，1=ALU第一个操作数是PC（AUIPC/JAL/JALR）
    input LUI,                        // 来自控制单元，1=LUI指令
    input[1:0] ALUBSrc,               // 来自控制单元，00=ALU第二个操作数是立即数 01=ALU第二个操作数是寄存器 10=ALU第二个操作数是4
    output reg[31:0] ALU_result,      // 输出ALU运算
    output reg less,                  // 输出有符号比较结果 (SLT)
    output reg lessu,                 // 输出无符号比较结果 (SLTU)
    output reg zero,                  // 输出相等比较结果
    output reg[31:0] Location_Result,     // 输出跳转地址
    output reg[31:0] pc_plus_4            // 输出PC+4的值
);

    // ALU操作数选择
    wire [6:0] eff_func7;
    wire [2:0] eff_func3;
    assign eff_func7 = (LUI || ALUASrc) ? 7'b0000000 : func7;
    assign eff_func3 = (LUI || ALUASrc) ? 3'b000     : func3;

    reg [31:0] ALU_A;   // ALU第一个操作数选择
    reg [31:0] ALU_B;   // ALU第二个操作数选择

    always @(*) begin

        // PC+4计算
        pc_plus_4 = PC + 32'd4;

        if (LUI) begin
            ALU_A = 32'd0;
        end else if (ALUASrc) begin   // ALUASrc=1 表示需要 PC（AUIPC / JAL / JALR）
            ALU_A = PC;
        end else begin
            ALU_A = rs1;
        end

        case (ALUBSrc)
            2'b00: ALU_B = imm;   // 立即数
            2'b01: ALU_B = rs2;   // 寄存器
            2'b10: ALU_B = 32'd4; // 常数4
            default: ALU_B = rs2; // 默认选择寄存器
        endcase

        
        // ALU运算
        if (ALUctr) begin
            case ({eff_func7, eff_func3})
                10'b0000000000: ALU_result = ALU_A + ALU_B;          // ADD
                10'b0100000000: ALU_result = ALU_A - ALU_B;          // SUB
                10'b0000000111: ALU_result = ALU_A & ALU_B;          // AND
                10'b0000000110: ALU_result = ALU_A | ALU_B;          // OR
                10'b0000000100: ALU_result = ALU_A ^ ALU_B;          // XOR  (新增)
                10'b0000000001: ALU_result = ALU_A << ALU_B[4:0];    // SLL  (新增，只取低5位)
                10'b0000000101: ALU_result = ALU_A >> ALU_B[4:0];    // SRL  (新增，逻辑右移)
                10'b0100000101: ALU_result = $signed(ALU_A) >>> ALU_B[4:0];   // 高位补符号位，得到0xF8000000
                10'b0000000010: ALU_result = ($signed(ALU_A) < $signed(ALU_B)) ? 32'd1 : 32'd0; // SLT
                10'b0000000011: ALU_result = (ALU_A < ALU_B) ? 32'd1 : 32'd0; // SLTU
                default:        ALU_result = 32'd0;
            endcase

            // 比较结果输出
            less   = ($signed(ALU_A) < $signed(ALU_B)) ? 1'b1 : 1'b0;
            lessu  = (ALU_A < ALU_B) ? 1'b1 : 1'b0;
            zero   = (ALU_A == ALU_B) ? 1'b1 : 1'b0;
        end else begin
            ALU_result = 32'd0;
            less   = 1'b0;
            lessu  = 1'b0;
            zero   = 1'b0;
        end

        // 跳转地址计算
        if (branch == 2'b01 || branch == 2'b10) begin
            Location_Result = PC + imm; // JAL/Branch跳转地址计算
        end else if (branch == 2'b11) begin
            Location_Result = (rs1 + imm) & ~32'd1; // JALR：目标=(rs1+imm)清零最低位
        end else begin
            Location_Result = 32'd0; // 默认值为0
        end
    end
endmodule