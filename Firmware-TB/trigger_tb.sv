`timescale 1ns / 1ps

module trigger_tb();

logic clk;
logic reset;
localparam T = 20;

logic [11:0] data_in;
logic [11:0] threshold;
logic [29:0] disable_time;
logic pulse_out;

assign disable_time = 30'd10;
assign threshold = 12'd1000;

Trigger_Rise
#(
    .width(12)
)
TRIGGER_UUT
(
	.clk(clk),                           // clock 
	.reset(reset),                         // reset low 
    .data_in(data_in),    // data input to be monitored SIGNED 
	.threshold(threshold),  // threshold from threshold controller SIGNED
	.disable_time(disable_time),           // disable time from the top module  (in clock cycles)
	.pulse_out(pulse_out)                     // output pulse with disable time duration (in clock cycles)
);


// Reset

initial begin
    reset = 0;
    #(2*T);
    reset = 1;
    #(2*T);
    reset = 0;
end


always begin
    clk = 0;
    #(T/2);
    clk = 1;
    #(T/2);
end

initial begin 
    data_in = 0;
end

always begin
    data_in = data_in + 1;
    #(T);
end



endmodule
