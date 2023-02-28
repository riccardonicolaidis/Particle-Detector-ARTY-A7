module Peak_Area_Detector 
#(parameter N_P = 12,    // Number of bits for peak detection 
            N_A = 20     // Number of bits for area detection
)
(
	input logic clk,                           // clock
	input logic reset,                         // reset low 
	input logic sampl_freq,                    // sampling update frequency
	input logic signed [N_P-1:0] data_in,      // Data coming from the DC blocker 
	input logic signed [N_P-1:0] threshold,    // Threshold coming from the threshold controller
	input logic [29:0] disable_time,           // Hold time 

	output logic signed [N_P-1:0] peak_value,  // Value of the peak (valid only if top_value_flag goes up)
	output logic signed [N_A-1:0] area_value,  // Value of the area (valid only at posedge area_ready)
	output logic top_value_flag,               // peak has reached the maximum value 
	output logic posedge_flag,                 // Becomes 1 if a positive edge is detected
	output logic over_threshold,               // If signal is over threshold this goes to 1
	output logic area_ready                    // The area is ready to be acquired 
);

// Signal declaration 
localparam Delta_N = N_A - N_P;   // Local parameter 20 - 12 = 8

// Peak detector signals 
logic signed [N_P-1:0] peak_value_reg;       // register containing the value of the peak 
logic  			       top_value_flag_reg;   // register for top value of the peak 
logic  		           posedge_flag_reg;     // positive edge detected
logic        [29:0]    counter;              // counter 

// Area detector signals 
logic signed [N_A-1:0] area_value_reg;    // Value of the area
logic           over_threshold_old;       // Old value to be sensitive to the positive edge
logic           sampl_freq_old;           // old update pulse to be sensitive to the positive edge
logic           area_ready_reg;           // register which goes to 1 of the area is ready to be acquired

// ********************************************
// SEQUENTIAL LOGIC CIRCUIT FOR PEAK DETECTOR 
// ********************************************
always_ff @(posedge clk, posedge reset) begin
    if(reset) begin                  // If reset then:
        peak_value_reg     <= signed'({N_P{1'b0}});     // peak value is put to 0
        top_value_flag_reg <= 1'b0;  // the flag for the maximum value goes to 0
        posedge_flag_reg   <= 1'b0;  // positive edge flag goes to zero
        counter            <= 30'd0;     // counter goes to zero
    end 
    else begin
        if((signed'(data_in) > signed'(threshold)) & !posedge_flag_reg ) begin   // If data > threshold but I have no positive edge
            posedge_flag_reg <= 1'b1;                           // Set the flag to 1 (posedge detected)
	    end
	    if(posedge_flag_reg) begin                              // If positive edge detected 
	       if(signed'(data_in) > signed'(peak_value_reg)) begin                   // Follow the signal untill it go below the threshold 
		      peak_value_reg     <= signed'(data_in);
		      top_value_flag_reg <= 1'b0;
		   end else if ( (signed'(data_in) < signed'(threshold)) & !top_value_flag_reg) begin 
		      top_value_flag_reg <= 1'b1;
		      counter <= disable_time;
		   end
	    end 
	    if(posedge_flag_reg & (counter > 30'd0) & top_value_flag_reg) begin
            counter <= counter - 1;
	    end
        if(posedge_flag_reg & (counter == 30'd0) & top_value_flag_reg) begin
			posedge_flag_reg   <= 1'b0;
			peak_value_reg     <= signed'({N_P{1'b0}});
			top_value_flag_reg <= 1'b0;
	    end
    end
end

typedef enum {IDLE,
              INTEGRATE,
              SIGNAL_INTEGRATED_READY,
              RESET} areay_detector_state;
    
areay_detector_state state_reg;
logic [29:0] counter_area_detector;

always_ff @(posedge clk, posedge reset) begin
    if(reset) begin
        area_value_reg        <= 0;
        area_ready_reg        <= 1'b0;
        over_threshold_old    <= 1'b0;
        sampl_freq_old        <= 1'b0;
        counter_area_detector <= 0;
    end else begin 
        case(state_reg) 
            IDLE: begin 
                area_ready_reg <= 1'b0;
                area_value_reg <= 0;
                if(over_threshold & (!over_threshold_old)) begin
                    state_reg <= INTEGRATE;
                end
            end
            INTEGRATE: begin 
                if((!over_threshold)& over_threshold_old) begin 
                    state_reg             <= SIGNAL_INTEGRATED_READY;
                    area_ready_reg        <= 1'b0;
                    counter_area_detector <= disable_time;
                end else if(sampl_freq & (!sampl_freq_old) & (!area_ready_reg)) begin
                    area_value_reg <= area_value_reg + signed'(data_in);
                end 
            end
            SIGNAL_INTEGRATED_READY : begin 
                area_ready_reg <= 1'b1;
                if (counter_area_detector > 30'd0) begin
                    counter_area_detector <= counter_area_detector - 1;
                end else begin  
                    state_reg <= RESET;
                end
            end
            RESET : begin
                area_ready_reg <= 1'b0;
                area_value_reg <= 0;
                state_reg      <= IDLE;
            end
            default : begin 
                state_reg <= IDLE;
            end
        endcase
    end
    sampl_freq_old     <= sampl_freq;
    over_threshold_old <= over_threshold;
end


assign over_threshold = (signed'(data_in) > signed'(threshold));       // Equal to 1 if data_in is greater than threshold            

// Combinational logic to connect regs to output 
assign peak_value     = signed'(peak_value_reg);
assign posedge_flag   = posedge_flag_reg;
assign top_value_flag = top_value_flag_reg;
assign area_value     = area_value_reg;
assign area_ready     = area_ready_reg;

endmodule

