module threshold_contr_tb();

localparam T = 20;


logic clk;
logic reset;
logic [3:0] sw;
logic [3:0] btn_db;

logic signed [11:0] threshold;


threshold_controller
#
(
    .N_P(12)
)
Threshold_contr (.*);



always  begin
    clk = 0;
    #(T/2);
    clk = 1;
    #(T/2);
end



initial begin
    btn_db = 0;
    sw = 0;
    reset = 0;
    #(T);
    reset = 1;
    #(3*T);
    reset = 0;
    #(10*T);
    sw = 4'b0000;
    #(T);
    btn_db[2] = 1;
    #(3*T);
    btn_db[2] = 0;
    #(T);
    btn_db[2] = 1;
    #(3*T);
    btn_db[2] = 0;
    sw = 4'b1000;
    #(T);
    btn_db[2] = 1;
    #(3*T);
    btn_db[2] = 0;
    sw = 4'b0100;
    #(T);
    btn_db[3] = 1;
    #(3*T);
    btn_db[3] = 0;
     #(T);
    btn_db[3] = 1;
    #(3*T);
    btn_db[3] = 0;
     #(T);
    btn_db[3] = 1;
    #(3*T);
    btn_db[3] = 0;
    $stop();
end




endmodule
