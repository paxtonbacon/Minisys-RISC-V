`timescale 1ns/1ps
// 单周期 RV32I 处理器顶层
// 数据通路：ifetch32(取指) -> control32(控制) / imm_gen(立即数)
//           -> idcode32(寄存器堆) -> execute32(ALU/跳转) -> dmemory32(数据存储器)
// 时序约定：PC 在时钟下降沿更新；寄存器堆在上升沿写回；
//           数据存储器在反相时钟(下降沿)写。
// 说明：clock 为系统时钟（FPGA 上可接时钟管理 IP 分频后的时钟）；
//       reset 为低有效复位（FPGA 上可接复位按键）。
module minisys(
    input         clk,         // 系统时钟
    input         reset,       // 低有效复位
    output [31:0] Instruction, // 调试：当前指令
    output [31:0] PC           // 调试：当前 PC
);

    // ---------------- 内部连线 ----------------
    wire [31:0] inst;            // 指令
    wire [31:0] pc;              // 当前 PC（ifetch 输出，供 execute 用）
    wire [31:0] next_pc;         // 下一 PC（调试，未使用）
    wire [31:0] pc_plus_4;       // PC+4（来自执行单元）
    wire [31:0] Location_Result; // 跳转目标（来自执行单元）
    wire        less, lessu, zero;       // 比较结果（来自执行单元）
    wire [1:0]  branch;          // 来自控制单元
    wire [31:0] imm_out;         // 立即数
    wire [31:0] rs1, rs2;        // 寄存器读出
    wire [31:0] alu_result;      // ALU 结果
    wire [31:0] mem_rdata;       // 数据存储器读出
    wire [2:0]  ExtOp;
    wire        RegWr, MemWr, MemtoReg, ALUASrc, LUI, ALUctr;
    wire [1:0]  ALUBSrc;
    wire clock;   // 内部系统时钟（综合时来自 cpuclk 分频；仿真时直连 clk）


    // cpuclk：上板综合时用时钟管理 IP 分频（Vivado 综合会自动定义 SYNTHESIS）；
    //         仿真时不定义 SYNTHESIS，clk 直接作为内部时钟，避免依赖 IP 分频
    //         导致仿真时钟频率/相位不确定。
`ifdef SYNTHESIS
    cpuclk cpuclk(
        .clk_in1(clk),    //100MHz
        .clk_out1(clock)    //cpuclock
    );
`else
    assign clock = clk;   // 仿真：clk 直接作为内部时钟
`endif

    // ---------------- 取指 ----------------
    ifetch32 u_ifetch (
        .Instruction    (inst           ),
        .next_PC        (next_pc        ),
        .PC_out         (pc             ),
        .clock          (clock          ),
        .reset          (reset          ),
        .branch         (branch         ),
        .func3          (inst[14:12]    ),
        .less           (less           ),
        .lessu          (lessu          ),
        .zero           (zero           ),
        .Location_Result(Location_Result ),
        .PC_plus_4      (pc_plus_4      )
    );

    // ---------------- 控制单元 ----------------
    control32 u_ctrl (
        .Opcode  (inst[6:0] ),
        .ExtOp   (ExtOp     ),
        .RegWr   (RegWr     ),
        .MemWr   (MemWr     ),
        .MemtoReg(MemtoReg  ),
        .ALUASrc (ALUASrc   ),
        .ALUBSrc (ALUBSrc   ),
        .LUIcode (LUI       ),
        .ALUctr  (ALUctr    ),
        .Branch  (branch    )
    );

    // ---------------- 立即数生成 ----------------
    imm_gen u_imm (
        .imm     (inst[31:7]),
        .ExtOp   (ExtOp     ),
        .imm_out (imm_out   )
    );

    // ---------------- 寄存器堆/译码 ----------------
    idcode32 u_id (
        .ra        (inst[19:15]),
        .rb        (inst[24:20]),
        .rd        (inst[11:7] ),
        .ALU_result(alu_result ),
        .read_data (mem_rdata  ),
        .MemtoReg  (MemtoReg   ),
        .RegWr     (RegWr      ),
        .clock     (clock      ),
        .reset     (reset      ),
        .rs1       (rs1        ),
        .rs2       (rs2        )
    );

    // ---------------- 执行单元 ----------------
    execute32 u_exe (
        .branch         (branch          ),
        .func3          (inst[14:12]     ),
        .func7          (inst[31:25]     ),
        .rs1            (rs1             ),
        .rs2            (rs2             ),
        .imm            (imm_out         ),
        .PC             (pc              ),
        .ALUctr         (ALUctr          ),
        .ALUASrc        (ALUASrc         ),
        .LUI            (LUI             ),
        .ALUBSrc        (ALUBSrc         ),
        .ALU_result     (alu_result      ),
        .less           (less            ),
        .lessu          (lessu           ),
        .zero           (zero            ),
        .Location_Result(Location_Result ),
        .pc_plus_4      (pc_plus_4       )
    );

    // ---------------- 数据存储器 ----------------
    dmemory32 u_dmem (
        .clock   (clock       ),
        .MemWr   (MemWr       ),
        .MemtoReg(MemtoReg    ),
        .func3   (inst[14:12] ),
        .addr    (alu_result  ),
        .wdata   (rs2         ),
        .rdata   (mem_rdata   )
    );

    // ---------------- 调试输出 ----------------
    assign Instruction = inst;
    assign PC = pc;

endmodule