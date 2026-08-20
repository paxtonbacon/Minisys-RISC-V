`timescale 1ns/1ps

module dmemory32(
    input clock,                      // 时钟信号
    input MemWr,                      // 来自控制单元，1=Store
    input MemtoReg,                   // 来自控制单元，1=Load（本模块未使用，可保留）
    input [2:0] func3,                // 来自指令 inst[14:12]
    input [31:0] addr,                // 来自ALU的地址
    input [31:0] wdata,               // 来自寄存器堆的写数据
    output reg [31:0] rdata           // 输出读数据
);

    // ---------- 声明内部信号 ----------
    wire clk;                         // 反相时钟
    assign clk = ~clock;              // 用于RAM时钟（原因见注释，但建议谨慎）

    wire [13:0] bram_addr = addr[15:2];   // 按字寻址，低2位丢弃
    wire [31:0] rdata_raw;                // RAM读出的原始32位数据

    // ---------- 字节写使能生成 ----------
    wire [3:0] we_mask;
    assign we_mask = (MemWr) ?
                     (func3 == 3'b010) ? 4'b1111 :                         // SW
                     (func3 == 3'b001) ? (4'b0011 << addr[1:0]) :          // SH
                     (func3 == 3'b000) ? (4'b0001 << addr[1:0]) :          // SB
                     4'b0000 : 4'b0000;

    // ---------- 写数据按字节/半字偏移对齐 ----------
    // BRAM 字节写使能按字节通道写：wea[i]=1 写 dina[8i+7:8i]。
    // 因此 SB/SH 必须把 wdata 的低位字节/半字搬到目标字节位置，否则非零偏移会写错数据。
    // 注意：移位量要用 32 位运算（addr[1:0]*8 / addr[1]*16），
    //       若写成 addr[1:0]<<3 / addr[1]<<4，结果会被截断为左操作数位宽而恒为 0。
    wire [31:0] wdata_eff;
    assign wdata_eff = (func3 == 3'b000) ? (wdata << (addr[1:0] * 32'd8)) :   // SB：字节对齐
                       (func3 == 3'b001) ? (wdata << (addr[1] * 32'd16)) :    // SH：半字对齐
                                            wdata;                            // SW/其他

    // ---------- 实例化简单双端口RAM（带字节写使能） ----------
    ram u_ram (
        .clka (clk),                // 写时钟
        .ena  (1'b1),
        .wea  (we_mask),
        .addra(bram_addr),
        .dina (wdata_eff),

        .clkb (clk),
        .enb  (1'b1),
        .addrb(bram_addr),
        .doutb(rdata_raw)
    );

    // ---------- Load 数据的符号/零扩展（考虑字节偏移） ----------
    always @(*) begin
        case (func3)
            3'b000 : begin
                // LB：根据 addr[1:0] 选择对应字节，符号扩展
                case (addr[1:0])
                    2'b00: rdata = {{24{rdata_raw[7]}},  rdata_raw[7:0]};
                    2'b01: rdata = {{24{rdata_raw[15]}}, rdata_raw[15:8]};
                    2'b10: rdata = {{24{rdata_raw[23]}}, rdata_raw[23:16]};
                    2'b11: rdata = {{24{rdata_raw[31]}}, rdata_raw[31:24]};
                endcase
            end
            3'b001 : begin
                // LH：地址低1位必须为0，取对应半字，符号扩展
                case (addr[1])
                    1'b0: rdata = {{16{rdata_raw[15]}}, rdata_raw[15:0]};
                    1'b1: rdata = {{16{rdata_raw[31]}}, rdata_raw[31:16]};
                endcase
            end
            3'b010 : rdata = rdata_raw;                               // LW：直通
            3'b100 : begin
                // LBU：选择字节，零扩展
                case (addr[1:0])
                    2'b00: rdata = {24'b0, rdata_raw[7:0]};
                    2'b01: rdata = {24'b0, rdata_raw[15:8]};
                    2'b10: rdata = {24'b0, rdata_raw[23:16]};
                    2'b11: rdata = {24'b0, rdata_raw[31:24]};
                endcase
            end
            3'b101 : begin
                // LHU：地址低1位为0，取半字，零扩展
                case (addr[1])
                    1'b0: rdata = {16'b0, rdata_raw[15:0]};
                    1'b1: rdata = {16'b0, rdata_raw[31:16]};
                endcase
            end
            default: rdata = rdata_raw;
        endcase
    end

endmodule