/* verilator lint_off UNUSEDSIGNAL */

`include "rtl/rv32_types"

module rv32_core (
    // Clk, Reset signals
    input logic clk, resetn,

    // Instructions memory port
    output rv32_word instr_addr,
    input rv_instr_t instr_bus,
    input logic instr_ready
);

rv32_word pc;
fetch_buffer_data_t instr_buff_data /*verilator public*/;
decoded_buffer_data_t decoded_buff_data /*verilator public*/;
exec_buffer_data_t exec_buff_data /*verilator public*/;
mem_buffer_data_t mem_buff_data /*verilator public*/;

// PC/Jump logic
logic exec_jump, jump_set_nop;
rv32_word exec_jump_addr, jump_nop_pc;
rv32_word next_pc /*verilator public*/;
always_comb begin
    jump_set_nop = 0;
    jump_nop_pc = decoded_buff_data.pc;

    if(exec_jump) begin
        next_pc = exec_jump_addr;
        jump_set_nop = 1;
    end else begin
        next_pc = pc + 4;
    end

    if (!resetn) begin
        next_pc = 0;
    end
end

always_ff @(posedge clk) begin
    pc <= next_pc;
end

// Register file
rv_reg_id_t dec_rs1, dec_rs2, wb_rd;
rv32_word dec_reg1, dec_reg2, wb_data;
logic wb_we;
rv32_register_file rf(
    .clk(clk), .resetn(resetn),
    // Decode interface
    .r1(dec_rs1), .o1(dec_reg1),
    .r2(dec_rs2), .o2(dec_reg2),
    // Writeback interface
    .write(wb_we), .d(wb_data), .rw(wb_rd)
);

// FETCH STAGE
logic fetch_stall;
rv32_fetch_stage fetch_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .set_nop(jump_set_nop),
    .set_nop_pc(jump_nop_pc),
    .pc(pc),
    .stall(fetch_stall), .fetch_data(instr_buff_data),
    // INSTR MEM I/O
    .addr(instr_addr), .instr(instr_bus),
    .ready(instr_ready)
);

// DECODE STAGE
logic dec_stall;
rv32_decode_stage decode_stage(
    .clk(clk), .resetn(resetn),
    // Pipeline I/O
    .set_nop(jump_set_nop),
    .set_nop_pc(jump_nop_pc),
    .instr_data(instr_buff_data),
    .decode_data(decoded_buff_data),
    .stall(dec_stall),
    // Register file read I/O
    .rs1(dec_rs1), .rs2(dec_rs2),
    .reg1(dec_reg1), .reg2(dec_reg2)
);

// EXECUTION STAGE
rv32_exec_stage exec_stage(
    .clk(clk), .resetn(resetn),
    .decoded_data(decoded_buff_data),
    .exec_data(exec_buff_data),
    .do_jump(exec_jump),
    .jump_addr(exec_jump_addr)
);

// MEMORY STAGE
logic mem_stall;
rv32_mem_stage mem_stage(
    .clk(clk), .resetn(resetn),
    .exec_data(exec_buff_data),
    .mem_data(mem_buff_data),
    .stall(mem_stall)
);

// WRITEBACK STAGE
rv32_wb_stage wb_stage(
    .mem_data(mem_buff_data),
    .reg_write(wb_we), .rd(wb_rd), .wb_data(wb_data)
);

endmodule
