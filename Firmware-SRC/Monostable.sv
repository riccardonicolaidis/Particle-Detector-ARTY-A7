module Monostable
(
    input logic clk,
    input logic reset,
    input logic [29:0] counter,
    input logic trigger,
    output logic pulse_out
);

// Signal declaration

logic trigger_old;
logic pulse_out_reg;
logic is_disabled;
logic [29:0] counter_reg;



always_ff @(posedge clk) begin
    if(reset) begin
        pulse_out_reg <= 1'b0;
        is_disabled   <= 1'b0;
        counter_reg   <= 0;
    end else begin
        if(trigger & (!trigger_old) & (!is_disabled)) begin
            is_disabled   <= 1'b1;
            counter_reg   <= counter;
            pulse_out_reg <= 1'b1;
        end

        if(is_disabled & (counter_reg > 30'd0)) begin
            counter_reg <= counter_reg - 1;
        end

        if(is_disabled & (counter_reg == 30'd0)) begin
            pulse_out_reg <= 1'b0;
            is_disabled   <= 1'b0;
        end
    end
    trigger_old <= trigger;
end


// Combinational output 
assign pulse_out = pulse_out_reg;

endmodule
