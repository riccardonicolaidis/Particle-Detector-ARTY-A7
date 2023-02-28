`timescale 1ns / 1ps
module Trigger_Rise
#(
    parameter width = 12
)
(
	input logic clk,                           // clock 
	input logic reset,                         // reset low 
    input logic signed [width-1:0] data_in,    // data input to be monitored SIGNED 
	input logic signed [width-1:0] threshold,  // threshold from threshold controller SIGNED
	input logic [29:0] disable_time,           // disable time from the top module  (in clock cycles)
	output logic pulse_out                     // output pulse with disable time duration (in clock cycles)
);

// I need SIGNED since I want that 000 > 111
// This because in the DC blocker circuit I am going to make subtractions

 // Signal declarations 
logic  pulse_out_reg;      // Register for pulse out  
logic  [29:0] counter;     // register for counter
logic  disableFlag;        // If 1 the device goes to disable state
logic  start_trigger;      // If 1 it means that data_in > threshold 
logic  start_trigger_old;  // Old value to be sensitive to the positive edge

// Combinatorial assignment
assign start_trigger = (signed'(data_in) > signed'(threshold)); // Comparator 


// FINITE STATE MACHINE 
// BODY 
always_ff @(posedge clk, posedge reset ) begin
    if(reset) begin
        counter           <= 30'd0;
        disableFlag       <= 1'b0;
        pulse_out_reg     <= 1'b0;
        start_trigger_old <= 1'b0;
    end else begin
        if(!disableFlag) begin
            if((start_trigger)&(!start_trigger_old)) begin
                pulse_out_reg <= 1'b1;
                disableFlag   <= 1'b1;
                counter       <= disable_time;
            end
	   end else if(disableFlag) begin
	        if(counter > 30'd0) begin
			    counter <= counter - 30'd1;
		    end else if(counter == 30'd0) begin
			    pulse_out_reg <= 1'b0;
			    disableFlag   <= 1'b0;
		    end
	   end
    end
    start_trigger_old <= start_trigger;
end

// COMBINATIONAL LOGIC FOR OUTPUT 
assign pulse_out = pulse_out_reg;

endmodule


