/* verilator lint_off UNUSEDSIGNAL */

module rv32_decode_stage
import rv32_types::*;
(
    // Clk, Reset signals
    input logic clk, resetn,
    // Pipeline I/O
    input logic set_nop, stop,
    input rv32_word set_nop_pc,
    input fetch_decode_buffer_t fetch_decode_buff,
    output decode_exec_buffer_t decode_exec_buff,
    output logic stall,
    // Memory I
    input rv_instr_t instr,
    // Register file read I/O
    output rv_reg_id_t rs1, rs2,
    input rv32_word reg1, reg2,
    // Hazzard detection I/O
    input exec_mem_buffer_t exec_mem_buff
);

decode_exec_buffer_t internal_data /*verilator public*/;
decode_exec_buffer_t output_internal_data /*verilator public*/;
decoded_instr_t decoder_output;

// Small logic to support fetch bubbles
rv_instr_t internal_instr;
always_comb begin
    if (fetch_decode_buff.generate_nop) internal_instr = RV_NOP;
    else internal_instr = instr;
end

logic [1:0] use_rs /*verilator public*/;
logic hazzard_stall;
bypass_t bypass_rs[2];

rv32_decoder decoder(
    .use_rs(use_rs),
    .instr(internal_instr),
    .decoded_instr(decoder_output)
);

rv32_hazzard_detection_unit hazzard_detection(
    .use_rs(use_rs),
    .current_instr(internal_instr),
    .decode_exec_buff(decode_exec_buff),
    .exec_mem_buff(exec_mem_buff),
    .stall(hazzard_stall),
    .bypass_rs(bypass_rs)
);

// Decode logic
always_comb begin
    // Forward signals
    internal_data.pc = fetch_decode_buff.pc;
    internal_data.instr = internal_instr;

    // Register file data
    rs1 = instr.rs1;
    rs2 = instr.rs2;
    internal_data.reg1 = reg1;
    internal_data.reg2 = reg2;

    // Default decode
    internal_data.decoded_instr = decoder_output;

    // Hazard detection
    internal_data.decoded_instr.bypass_rs1 = bypass_rs[0];
    internal_data.decoded_instr.bypass_rs2 = bypass_rs[1];
    stall = hazzard_stall;
end

always_comb begin
    output_internal_data = internal_data;

    if (stall | set_nop) begin
        output_internal_data.instr = RV_NOP;
        output_internal_data.decoded_instr = create_nop_ctrl();
        if (set_nop) output_internal_data.pc = set_nop_pc;
    end

end

always_ff @(posedge clk) begin
    if (!resetn) begin
        decode_exec_buff.instr <= RV_NOP;
        decode_exec_buff.decoded_instr <= create_nop_ctrl();
        decode_exec_buff.pc <= 0;
    end
    else if (!stop) begin
        decode_exec_buff <= output_internal_data;
    end
end

endmodule
