module DSP_pipeline_tb();

parameter T = 20;

logic clk;					       // clock 
logic reset;					       // reset low 
logic sample_freq;
logic signed [11:0] data_in;
logic signed [11:0] data_out;


always begin
    clk = 1;
    #(T/2);
    clk = 0;
    #(T/2);
end

always begin 
    sample_freq = 1;
    #(10*T);
    sample_freq = 0;
    #(10*T);
end


initial begin
    data_in = 12'b010000000000;
    reset = 0;
    #(2*T);
    reset = 1;
    #(2*T);
    reset = 0;
    #(5*T);
end



always begin 
   data_in = data_in + 1;
   #(4*T); 
end



DC_Blocker 
#(
    .width(12)               // width of the input data bus 
)
Blocker
(	
	.clk(clk),                          // clock 
	.reset(reset),                        // reset low 
	.sampl_freq(sample_freq),                   // update frequency
	.data_in(data_in),   // data input 
	.data_out(data_out)                  
);



endmodule
