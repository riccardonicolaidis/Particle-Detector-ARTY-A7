

module debouncing_array
#(
    parameter N = 4
)
(
input logic clk,
input logic reset,
input logic  [N-1:0] in_sw,
output logic [N-1:0] out_db
);

logic [N-1: 0] clk_array;
logic [N-1: 0] reset_array;

genvar i;
generate
    for(i=0; i < N; i = i+1) begin
        assign clk_array[i] = clk;
        assign reset_array[i] = reset;
    end
endgenerate



db_fsm DEBOUNCING_MODULES[N-1:0]
(
.clk(clk_array),
.reset(reset_array),
.sw(in_sw),
.db(out_db)
);

endmodule
