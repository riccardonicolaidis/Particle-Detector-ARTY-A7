module tb_peak_area_detector();



logic clk;
logic reset;
localparam T = 20;

logic [11:0] data_in;
logic [11:0] threshold;
logic [29:0] disable_time;
logic [11:0] peak;
logic [19:0] area;
logic sampl_freq;

logic peak_ready;
logic area_ready;

logic posedge_flag;
logic over_threshold;


assign threshold = 12'd1000;
assign disable_time = 30'd100;

// PEAK AREA DETECTOR 
Peak_Area_Detector 
#(
	.N_P(12),
	.N_A(20)
)
PEAK_AREA_DETECTORS_UUT
(
	.clk(clk),
	.reset(reset),
	.sampl_freq(sampl_freq),
	.data_in(signed'(data_in)),
	.threshold(signed'(threshold)),
	.disable_time(disable_time),
	.peak_value(peak),
	.area_value(area),
	.top_value_flag(peak_ready),
	.posedge_flag(posedge_flag),
	.over_threshold(over_threshold),
	.area_ready(area_ready)
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

always begin
    sampl_freq = 1'b0;
    #(19*T);
    sampl_freq = 1'b1;
    #(1*T);
end

initial begin 
    data_in = 12'd0;
    #(10000*T);
    $stop;
end

always begin
    data_in = data_in + 12'd1;
    #(10*T);
end



endmodule
