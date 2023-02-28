module left_padding_zero
#(
    parameter N_IN = 12,
    parameter N_OUT = 13
)
(
    input  logic signed [N_IN-1:0]  signal_in,
    output logic signed [N_OUT-1:0] signal_out
);

localparam DELTA_N = N_OUT - N_IN;
// ATTENTION!!
// Be sure that N_OUT > N_IN

assign signal_out = {{DELTA_N{1'b0}},signal_in};

endmodule
