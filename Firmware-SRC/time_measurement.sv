module Module_Time_Measurement (
input logic clk,
input logic reset,
output  logic [47:0] out
);

// FILI PER IL CRONOMETRO

logic  w_1e7Hz; // 3-0
logic  w_1e6Hz; // 7-4
logic  w_1e5Hz; // 11-8
logic  w_1e4Hz; // 15-12
logic  w_1e3Hz; // 19-16
logic  w_1e2Hz; // 23-20
logic  w_1e1Hz; // 27-24
logic  w_1e0Hz; // 31-28
logic  w_1m1Hz; // 35-32
logic  w_1m2Hz; // 39-36
logic  w_1m3Hz; // 43-40
logic  w_1m4Hz; // 47-44





Module_FrequencyDivider	DIVISORE_1e7Hz(
		.clk(clk), 
	.reset(reset),
	.period(30'd5), 
	.clk_out(w_1e7Hz)
);

Module_SynchroCounter_4_bit  COUNTER_1e7Hz(	
	.clk(clk),
	.clk_ref(w_1e7Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[3:0]),
	.carry(w_1e6Hz)
);


Module_SynchroCounter_4_bit  COUNTER_1e6Hz(	
	.clk(clk),
	.clk_ref(w_1e6Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[7:4]),
	.carry(w_1e5Hz)
);

Module_SynchroCounter_4_bit  COUNTER_1e5Hz(	
	.clk(clk),
	.clk_ref(w_1e5Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[11:8]),
	.carry(w_1e4Hz)
);


Module_SynchroCounter_4_bit  COUNTER_1e4Hz(	
	.clk(clk),
	.clk_ref(w_1e4Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[15:12]),
	.carry(w_1e3Hz)
);
	

Module_SynchroCounter_4_bit  COUNTER_1e3Hz(	
	.clk(clk),
	.clk_ref(w_1e3Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[19:16]),
	.carry(w_1e2Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1e2Hz(	
	.clk(clk),
	.clk_ref(w_1e2Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[23:20]),
	.carry(w_1e1Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1e1Hz(	
	.clk(clk),
	.clk_ref(w_1e1Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[27:24]),
	.carry(w_1e0Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1e0Hz(	
	.clk(clk),
	.clk_ref(w_1e0Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[31:28]),
	.carry(w_1m1Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1m1Hz(	
	.clk(clk),
	.clk_ref(w_1m1Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[35:32]),
	.carry(w_1m2Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1m2Hz(	
	.clk(clk),
	.clk_ref(w_1m2Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[39:36]),
	.carry(w_1m3Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1m3Hz(	
	.clk(clk),
	.clk_ref(w_1m3Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[43:40]),
	.carry(w_1m4Hz)
);
Module_SynchroCounter_4_bit  COUNTER_1m4Hz(	
	.clk(clk),
	.clk_ref(w_1m4Hz),
	.reset(reset),
	.limit(4'd10),
	.out(out[47:44]),
	.carry()
);

endmodule