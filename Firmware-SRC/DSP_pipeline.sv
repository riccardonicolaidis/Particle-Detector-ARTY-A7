module DSP_pipeline
#(
	parameter N_CH        = 2,   // Number of channles
			  N_A         = 20,  // Number of bits area 20
			  N_P         = 12,  // Number of bits peak 12
			  N_P_PADDING = 13,  // Number of bits peak after padding with zero
			  Size_log2   = 15   // Number of samles log_2
)
(
    input  logic                          clk,					       // clock 
    input  logic                          reset,				       // reset low 
	input  logic 		[29:0]	          number_samples_to_skip,
    input  logic signed [N_P-1:0]         A              [N_CH-1:0],  // Channels sequenced
    input  logic                          A_pulse        [N_CH-1:0],  // Update frequency
    input  logic signed [N_P-1:0]         threshold,                  // threshold from threshold controller
    input  logic        [29:0]            disable_time,               // disable time 
    output logic signed [N_P-1:0]         A_peak         [N_CH-1:0],  // peak value 
	output logic signed [N_A-1:0]         A_area         [N_CH-1:0],  // Area value 
    output logic                          peak_ready     [N_CH-1:0],  // peak is ready
    output logic                          area_ready     [N_CH-1:0],  // area is ready
    output logic                          coincidence_flag,           // there has been a coincidence
	output logic   				          DC_subtracted  [N_CH-1:0],
	output logic 				          posedge_flag   [N_CH-1:0],
	output logic 				          over_threshold [N_CH-1:0]
); 

// Signal declarations 
logic signed [N_P_PADDING-1:0]  A_AC           [N_CH-1:0];  // Channel sequenced with offset calibration
logic        [N_CH-1:0]         A_pulse_trgd;               // Trigger signal array
logic signed [N_P_PADDING-1:0]  A_peak_padded  [N_CH-1:0];  // peak value PADDED
logic signed [N_P_PADDING-1:0]  threshold_padded;           // threshold from threshold controller PADDED
logic signed [N_P_PADDING-1:0]  A_padded       [N_CH-1:0];  // Channels sequenced PADDED


// *******************************************
// THRESHOLD PADDING WITH ZEROS
// *******************************************

left_padding_zero
#(
	.N_IN(N_P),
    .N_OUT(N_P_PADDING)
)
LEFT_PADDING_ZERO_THR
(
	.signal_in(threshold),
    .signal_out(threshold_padded)
);


// *******************************************
//       GENERATE CONSTRUCT FOR PIPELINING 
// *******************************************
genvar i;
generate
	for(i=0; i<=(N_CH-1);i=i+1) begin : DSP_pipeline_generation
		// ####################################################################
		// Left zero padding 
		left_padding_zero
		#(
    		.N_IN(N_P),
            .N_OUT(N_P_PADDING)
        )
        LEFT_PADDING_ZERO_SIGNAL
        (
            .signal_in(A[i]),
            .signal_out(A_padded[i])
        );

		// ####################################################################
		// DC Block filters
		DC_Blocker
		#(
			.width(N_P_PADDING),                // Number of bits peak 
			.Size_log2(Size_log2)
		)
		DC_BLOCKERS_MODULES  // ARRAY
		(	
			.clk(clk),
			.sampl_freq(A_pulse[i]),
			.number_samples_to_skip(number_samples_to_skip), // Number of samples to skip
			.DC_subtracted(DC_subtracted[i]),
			.reset(reset),
			.data_in(A_padded[i]),
			.data_out(A_AC[i])
		);
		// #####################################################################
		// Triggers  
		Trigger_Rise    
		#(
			.width(N_P_PADDING)
		)
		TRIGGER_RISING_EDGE
		(
			.clk(clk),						   // clock
			.reset(reset),					   // reset low
			.data_in(A_AC[i]),		           // Signal without DC offset
			.threshold(threshold_padded),      // Threshold 
			.disable_time(disable_time),       // Time duration of the pulse 
			.pulse_out(A_pulse_trgd[i])        // Output pulse
		);
	    // ########################################################################
		// Peak detectors 
		Peak_Area_Detector 
		#(
			.N_P(N_P_PADDING),
			.N_A(N_A)
		)
		PEAK_AREA_DETECTORS
		(
			.clk(clk),
			.reset(reset),
			.sampl_freq(A_pulse[i]),
			.data_in(A_AC[i]),
			.threshold(threshold_padded),
			.disable_time(disable_time),
			.peak_value(A_peak_padded[i]),
			.area_value(A_area[i]),
			.top_value_flag(peak_ready[i]),
			.posedge_flag(posedge_flag[i]),
			.over_threshold(over_threshold[i]),
			.area_ready(area_ready[i])
		);

		// ############################################################################
		// Remove the extra bit to the Peak value used to avoid overflow
		assign A_peak[i] = A_peak_padded[i][N_P-1:0];

	end
endgenerate

// COINCIDENCE FLAG
// USING REDUCTION OPERATOR
assign coincidence_flag = &A_pulse_trgd;
  
endmodule
