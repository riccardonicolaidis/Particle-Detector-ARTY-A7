`timescale 1 ns/ 10 ps

module my_testbench_tb();
// This is my testbench

localparam T = 20;
logic clk;
logic [11:0] data_in;
logic [11:0] data_out;
logic reset;




Module_DC_Blocker 
DC_BLOCKER_UUT
(	
    .reset(reset),
	.clk_in(clk),                          // clock 
	.data_in(data_in),   // data input 
	.data_out(data_out)  // data output 
);

// Reset
initial begin
    reset = 1'b0;
    #(T);
    reset = 1'b1;
    #(3* T);
    reset = 1'b0;
end


// clock generator 
always begin
    clk = 1'b1;
    #(T/2);
    clk = 1'b0;
    #(T/2);
end

initial begin
    data_in = 0;
end

always begin 
    data_in = data_in + 1;
    #(700*T);
end







endmodule 