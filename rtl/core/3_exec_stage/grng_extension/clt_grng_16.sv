/* verilator lint_off UNUSEDSIGNAL */

module clt_grng_16 
import rv32_types::*;
(
    input logic clk, resetn,
    input grng_ctrl_t ctrl,
    input logic[31:0] seed,
    output logic[31:0] sample
);

const logic [150:0] RESET_SEED = 151'b0111001100100100110011101101000111101000001000100001000111001100011000101110010111111111011101101110110110110000100001000010010110001101000011111001000;

// Control logic
logic [2:0] current_state, next_state;
logic uc_enable, uc_set, state_change;
logic [150:0] uc_seed;

always_comb begin 
    uc_set = 0;
    uc_enable = 0;
    state_change = 0;
    uc_seed = RESET_SEED;
    next_state = current_state;

    if (!resetn) begin 
        state_change = 1;
        next_state = 4;
        uc_set = 1;
    end
    else if (ctrl.set_seed) begin
        state_change = 1;
        next_state = 4;
        uc_set = 1;
        uc_seed[150:32] = RESET_SEED[150:32];
        uc_seed[31:0] = seed;
    end
    else if (current_state > 0) begin
        state_change = 1;
        next_state = current_state - 1;
        uc_enable = 1;
    end 
    else begin 
        uc_enable = ctrl.enable;
    end
end
always_ff @(posedge clk) begin
    if (state_change) begin
        current_state <= next_state;
    end
end

logic [150:0] urng_state;
lfsr_151_144 urng(
    .clk(clk), .enable(uc_enable),
    .set(uc_set), .seed(uc_seed),
    .current_state(urng_state)
);

logic [15:0] tree_result;
adder_tree_12_12 adder_tree(
    .clk(clk), .data(urng_state[143:0]),
    .enable(uc_enable),
    .result(tree_result)
);

const logic [15:0] C6 = 6;

always_comb begin
    sample[15:0] = 0;
    sample[31:16] = $signed(tree_result) - $signed(C6);
end

endmodule
