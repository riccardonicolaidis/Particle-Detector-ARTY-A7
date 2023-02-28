module threshold_controller
#
(
    parameter N_P = 12
)
(
    input logic clk,
    input logic reset,
    input logic [3:0] sw,
    input logic [3:0] btn_db,

    output logic signed [N_P-1:0] threshold
);

localparam M = N_P - 8;


// Signal declaration
logic signed [N_P-1:0] threshold_reg;
logic [3:0] btn_db_old;

// Body
always_ff @(posedge clk) begin
    if(reset) 
        threshold_reg <= 10;
    else begin 
        if(btn_db[3] & (!btn_db_old[3]) & sw[0] == 1'b0 ) begin
            case (sw[3:1]) 
                3'b000 :    
                    threshold_reg <= threshold_reg - signed'({{M{1'b0}},8'b00000001});
                3'b001 :    
                    threshold_reg <= threshold_reg - signed'({{M{1'b0}},8'b00000010});
                3'b010 :    
                    threshold_reg <= threshold_reg - signed'({{M{1'b0}},8'b00000100});
                3'b011 :    
                    threshold_reg <= threshold_reg - signed'({{M{1'b0}},8'b00001000});
                3'b100 :        
                    threshold_reg <= threshold_reg - signed'({{M{1'b0}},8'b00010000});
                3'b101 :    
                    threshold_reg <= threshold_reg - signed'({{M{1'b0}},8'b00100000});
                3'b110 :    
                    threshold_reg <= threshold_reg - signed'({{M{1'b0}},8'b01000000});
                3'b111 :    
                    threshold_reg <= threshold_reg - signed'({{M{1'b0}},8'b10000000});
            endcase
        end
        if(btn_db[2] & (!btn_db_old[2]) & sw[0] == 1'b0 ) begin
            case (sw[3:1]) 
                3'b000 :    
                    threshold_reg <= threshold_reg + signed'({{M{1'b0}},8'b00000001});
                3'b001 :    
                    threshold_reg <= threshold_reg + signed'({{M{1'b0}},8'b00000010});
                3'b010 :    
                    threshold_reg <= threshold_reg + signed'({{M{1'b0}},8'b00000100});
                3'b011 :    
                    threshold_reg <= threshold_reg + signed'({{M{1'b0}},8'b00001000});
                3'b100 :    
                    threshold_reg <= threshold_reg + signed'({{M{1'b0}},8'b00010000});
                3'b101 :    
                    threshold_reg <= threshold_reg + signed'({{M{1'b0}},8'b00100000});
                3'b110 :    
                    threshold_reg <= threshold_reg + signed'({{M{1'b0}},8'b01000000});
                3'b111 :    
                    threshold_reg <= threshold_reg + signed'({{M{1'b0}},8'b10000000});
            endcase
        end
    end
    btn_db_old <= btn_db;
end



// Combinational output 
assign threshold = threshold_reg;





endmodule
