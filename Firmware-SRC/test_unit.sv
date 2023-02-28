module test_unit
#(
    parameter N_CH = 6,
              N_P = 12
)
(
    input logic clk, reset,
    input logic w_tx,
    input logic A_pulse        [N_CH-1:0],      // Update frequency
    input logic DAQ_pulse,
    input logic peak_ready     [N_CH-1:0],      // peak is ready
    input logic area_ready     [N_CH-1:0],      // area is ready
    input logic coincidence_flag,               // there has been a coincidence
    input logic DC_subtracted  [N_CH-1:0],
    input logic posedge_flag   [N_CH-1:0],
    input logic over_threshold [N_CH-1:0],

    output logic [13:0] ck_io
);
// Signal declaration 
logic                  w_1e3Hz;
logic                  sampl_freq_div10;
logic signed [N_P-1:0] A_AC [N_CH-1:0];  // Channel sequenced with offset calibration
logic           [10:0] wb_ck_io;

// ******************************
// FREQUENCY DIVIDER FOR CLOCK MONITORING 
// ******************************
Module_FrequencyDivider f_1HZ_DIVIDER
(	
.clk(clk),  
.period(30'd50000),    
.clk_out(w_1e3Hz)
);
// ******************************
// Measuring sampling frequency 
// ******************************
Module_FrequencyDivider SAMPLING_FREQ_X10
(	
.clk(A_pulse[0]),  
.period(30'd5),
.reset(reset),    
.clk_out(sampl_freq_div10)
);

genvar i;

generate
    for(i=0; i<= 10; i=i+1) begin : CK_pulse_generation
        Monostable VISIBLE_PULSE_OUT_CK_IO
        (
            .clk(clk),
            .reset(reset),
            .counter(30'd100_000_000),
            .trigger(wb_ck_io[i]),
            .pulse_out(ck_io[i])
        );
    end
endgenerate







// Combinational output 
assign ck_io[11]  = w_1e3Hz;
assign ck_io[12]  = sampl_freq_div10;  // SAMPLING FREQUENCY DIVIDED BY 2
assign ck_io[13]  = w_tx;              // UART OUTPUT CHECK

assign wb_ck_io[0]  = peak_ready[0];
assign wb_ck_io[1]  = peak_ready[1];
assign wb_ck_io[2]  = area_ready[0];
assign wb_ck_io[3]  = area_ready[1];
assign wb_ck_io[4]  = coincidence_flag;
assign wb_ck_io[5]  = DC_subtracted[0];
assign wb_ck_io[6]  = DC_subtracted[1];
assign wb_ck_io[7]  = posedge_flag[0];
assign wb_ck_io[8]  = posedge_flag[1];
assign wb_ck_io[9]  = over_threshold[0];
assign wb_ck_io[10] = over_threshold[1];


endmodule
