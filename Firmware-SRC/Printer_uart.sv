module Printer_uart
#(
    parameter N_T = 48,
              N_P = 12,
              N_A = 20,
              N_CH = 6
)
(
    input logic                  clk,
    input logic                  reset,
    input logic        [10:0]    dvsr,
    input logic        [N_T-1:0] time_event,                // Time of the event
    input logic signed [N_P-1:0] A_peak_event [N_CH-1:0],   // Peak values array of the event
    input logic signed [N_P-1:0] threshold,
    input logic signed [N_A-1:0] A_area_event [N_CH-1:0],   // Peak values array of the event
    input logic                  DAQ_pulse,                 // Output pulse to send data to memory or uart
    output logic                 tx,
    output logic                 [3:0] control_state
);

// Registri che servono per le conversioni da binario a BCD
// Parametri
localparam N_BIT_IN_PEAK    = N_P; 
localparam N_BIT_IN_AREA    = N_A; 
localparam N_DIGIT_OUT_PEAK = 5  ;
localparam N_DIGIT_OUT_AREA = 9  ;


// Signal declarations
// Important ASCII CODES
wire  [7:0] wb_SPACE_ASCII;
wire  [7:0] wb_DOT_ASCII;
wire  [7:0] wb_NEW_LINE;
assign wb_SPACE_ASCII = 8'd32;
assign wb_DOT_ASCII   = 8'd46;
assign wb_NEW_LINE    = 8'd10;


// Regs necessay for the monitoring of the FIFO buffers
wire empty_fifo;

// Wires to connect the output of fifo buffers
wire [N_T-1:0] time_event_fifo;                // Time of the event
wire [N_P-1:0] A_peak_event_fifo [N_CH-1:0];   // Peak values array of the event
wire [N_A-1:0] A_area_event_fifo [N_CH-1:0];   // Peak values array of the event


// Wires to monitor the full status of the FIFO buffers
wire [N_CH-1:0] wb_FullFifo_Peak;               // Wire bus with fifo full signal Peak
wire [N_CH-1:0] wb_FullFifo_Area;               // Wire bus with fifo full signal Area
wire            w_FullFifo_Time;                // Wire with fifo full signal Time
wire [N_CH-1:0] wb_EmptyFifo_Peak;              // Wire bus with fifo empty signal Peak
wire [N_CH-1:0] wb_EmptyFifo_Area;              // Wire bus with fifo empty signal Area
wire            w_EmptyFifo_Time;               // Wire with fifo empty signal Time

wire w_AllEmptyFifo_Peak;
wire w_AllEmptyFifo_Area;

assign w_AllEmptyFifo_Peak = &wb_EmptyFifo_Peak;
assign w_AllEmptyFifo_Area = &wb_EmptyFifo_Area;
assign empty_fifo = w_EmptyFifo_Time & w_AllEmptyFifo_Peak & w_AllEmptyFifo_Area;

wire w_AtLeastOneFullFifo_Peak;
wire w_AtLeastOneFullFifo_Area;
wire w_AtLeastOneFullFifo;

assign w_AtLeastOneFullFifo_Peak = |wb_FullFifo_Peak;
assign w_AtLeastOneFullFifo_Area = |wb_FullFifo_Area;
assign w_AtLeastOneFullFifo = w_AtLeastOneFullFifo_Peak | w_AtLeastOneFullFifo_Area | w_FullFifo_Time;

// Segnali che pilotano il fifo_controller 
logic read_pulse_reg;               // reg

// Contatore per inviare i byte correttamente
logic [7:0] counter_digit;      // Conta le cifre reg
logic [7:0] counter_channel;    // Conta i canali reg

// Registro che contiene i dati da inviare 1 BYTE
logic [7:0]     Printer;         // Registro reg
logic           Print_pulse;     // Segnale  reg

// Registri
logic                            DAQ_pulse_old;
logic                            start_conversion_peak;         // reg
logic                            start_conversion_area;         // reg
logic                            Converter_peak_assigned;       // reg
logic                            Converter_area_assigned;       // reg
logic [7:0]                      counter_pause_peak_BCD;        // reg
logic [7:0]                      counter_pause_area_BCD;        // reg
wire                             BCD_peak_ready;                // wire
wire                             BCD_area_ready;                // wire
logic [N_P-1:0]                  Converter_peak;                // reg
logic [N_A-1:0]                  Converter_area;                // reg
wire  [4*(N_DIGIT_OUT_PEAK)-1:0] BCD_peak;                      // wire bus
wire  [4*(N_DIGIT_OUT_AREA)-1:0] BCD_area;                      // wire bus
logic [4*(N_DIGIT_OUT_PEAK)-1:0] A_peak_event_BCD [N_CH-1:0];   // Peak values array of the event BCD
logic [4*(N_DIGIT_OUT_AREA)-1:0] A_area_event_BCD [N_CH-1:0];   // Peak values array of the event BCD
logic [4*(N_DIGIT_OUT_PEAK)-1:0] threshold_BCD_reg;             // Peak values array of the event BCD

logic [N_T-1:0]                  time_event_reg;                // REG MODIFICABILE
logic [N_P-1:0]                  A_peak_event_reg [N_CH-1:0];   // REG MODIFICABILE 
logic [N_A-1:0]                  A_area_event_reg [N_CH-1:0];   // REG MODIFICABILE 

logic [3:0]                      CONTROL_STATE;                 // reg Stato di controllo 


// #######################################################################################################

// Now I need to define a FSM for managing the fifo buffers
// If the fifos are fulls I need to wait until they are empty
// Then, I reenamble the DAQ_pulse signal

typedef enum {FIFO_READ_ENABLED,
              FIFO_READ_DISABLED} state_FSM_FIFO;

state_FSM_FIFO state_reg_FIFO;    // reg state
logic          FIFO_enabled_reg;  // reg



always_ff @(posedge clk, posedge reset) begin
    if(reset) begin
        state_reg_FIFO <= FIFO_READ_DISABLED;     // If reset go to idle
    end
    else begin
        case (state_reg_FIFO)         // Now I explain the behaviour of the finite state machine 
            FIFO_READ_ENABLED : begin
                if(w_AtLeastOneFullFifo) begin
                    state_reg_FIFO <= FIFO_READ_DISABLED;
                end
            end
            FIFO_READ_DISABLED : begin
                if(empty_fifo) begin
                    state_reg_FIFO <= FIFO_READ_ENABLED;
                end
            end
            default: begin 
                state_reg_FIFO <= FIFO_READ_DISABLED;
            end
        endcase
    end
end

assign FIFO_enabled_reg = (state_reg_FIFO == FIFO_READ_ENABLED);



// #######################################################################################################

// FIFO FOR TIME STORAGE
fifo_generator_time FIFO_TIME       
(
  .clk(clk),                                                    // input wire clk
  .srst(reset),                                                 // input wire srst
  .din(time_event),                                             // input wire [11 : 0] din
  .wr_en(DAQ_pulse &(!DAQ_pulse_old)& FIFO_enabled_reg),        // input wire wr_en
  .rd_en(read_pulse_reg),                                       // input wire rd_en
  .dout(time_event_fifo),                                       // output wire [11 : 0] dout
  .full(w_FullFifo_Time),                                       // output wire full
  .empty(w_EmptyFifo_Time)                                      // output wire empty
);


// FIFO PEAK DATA
genvar i;     // generation variable 
generate      // Generate construct to parallelise the structure
    for(i=0; i<=(N_CH-1);i=i+1) begin : fifo_peak_generation
        fifo_generator_peak FIFO_PEAK
        (
            .clk(clk),                                                  // input wire clk
            .srst(reset),                                               // input wire srst
            .din(A_peak_event[i]),                                      // input wire [11 : 0] din
            .wr_en(DAQ_pulse &(!DAQ_pulse_old) & FIFO_enabled_reg),     // input wire wr_en
            .rd_en(read_pulse_reg),                                     // input wire rd_en
            .dout(A_peak_event_fifo[i]),                                // output wire [11 : 0] dout
            .full(wb_FullFifo_Peak[i]),                                 // output wire full
            .empty(wb_EmptyFifo_Peak[i])                                // output wire empty
        );

        fifo_generator_area FIFO_AREA
        (
            .clk(clk),                                              // input wire clk
            .srst(reset),                                           // input wire srst
            .din(A_area_event[i]),                                  // input wire [11 : 0] din
            .wr_en(DAQ_pulse&(!DAQ_pulse_old)& FIFO_enabled_reg),   // input wire wr_en
            .rd_en(read_pulse_reg),                                 // input wire rd_en
            .dout(A_area_event_fifo[i]),                            // output wire [11 : 0] dout
            .full(wb_FullFifo_Area[i]),                             // output wire full
            .empty(wb_EmptyFifo_Area[i])                            // output wire empty
        );

    end
endgenerate





// Now I need to define the states of the FSMs
// 1) Send time 
// 2) Binary to BCD peak
// 3) Send peak
// 4) repeat for all peaks
// 5) Repeat for all areas
// 6) Read <= 1'b1;
// 7) read <= 1'b0;

typedef enum {IDLE,
              SEND_TIME,
              FILL_TIME,
              FILL_PEAKS,
              FILL_AREAS, 
              BCD_PEAK,
              BCD_AREA,
              BCD_THRESHOLD, 
              SEND_PEAK,
              SEND_AREA,
              SEND_THRESHOLD,
              FINAL_STATE} state_FSM;

state_FSM state_reg;    // reg state


// Finite state machine
always_ff @(posedge clk, posedge reset) begin
    if(reset) begin
        state_reg              <= IDLE;     // If reset og to idle
        Printer                <= 0; 
        Print_pulse            <= 0;        
        time_event_reg         <= 0; 
        read_pulse_reg         <= 0; 
        counter_digit          <= 0; 
        counter_channel        <= 0; 
        Converter_peak         <= 0; 
        Converter_area         <= 0; 
        counter_pause_area_BCD <= 0;
        counter_pause_peak_BCD <= 0;
    end
    else begin
        case (state_reg)         // Now I explain the behaviour of the finite state machine 
            IDLE : begin
                Print_pulse               <= 1'b0;
                Printer                   <= 0;
                counter_channel           <= 0;
                start_conversion_peak     <= 1'b0;
                Converter_peak_assigned   <= 1'b0;
                start_conversion_area     <= 1'b0;
                Converter_area_assigned   <= 1'b0;
                read_pulse_reg            <= 1'b0;
                time_event_reg            <= 0;
                counter_pause_peak_BCD    <= 0;
                counter_pause_area_BCD    <= 0;
                CONTROL_STATE             <= 4'd0;
                if(!empty_fifo) begin           // If fifo is not empty anymore 
                    state_reg             <= FILL_TIME;
                    counter_digit         <= 8'd12;
                    CONTROL_STATE         <= 4'd1;
                end else begin
                    counter_digit         <= 8'd0;
                end
            end
            FILL_TIME : begin
                time_event_reg   <= time_event_fifo;
                state_reg        <= FILL_PEAKS;
                CONTROL_STATE    <= 4'd2;
                counter_channel  <= 0;
            end
            FILL_PEAKS : begin 
                if(counter_channel <= (N_CH-1)) begin 
                    A_peak_event_reg[counter_channel] <= A_peak_event_fifo[counter_channel];
                    counter_channel                   <= counter_channel + 1;
                end else begin 
                    counter_channel  <= 0;
                    state_reg        <= FILL_AREAS;
                end
            end
            FILL_AREAS : begin 
                if(counter_channel <= (N_CH-1)) begin 
                    A_area_event_reg[counter_channel] <= A_area_event_fifo[counter_channel];
                    counter_channel                   <= counter_channel + 1;
                end else begin 
                    read_pulse_reg   <= 1'b1;
                    state_reg        <= SEND_TIME;
                end
            end
            SEND_TIME : begin
                if(read_pulse_reg) begin
                    read_pulse_reg <= 1'b0;    // I need that the read pulse has the duration of a clock cycle
                end 
                if( (counter_digit >= 8'd2) & (!Print_pulse) ) begin
                                  Printer        <= {4'b0011,time_event_reg[(N_T-1) -: 4]};
                                  time_event_reg <= (time_event_reg << 4);
                                  Print_pulse    <= 1'b1;
                                  counter_digit  <= counter_digit - 8'd1;
                                  CONTROL_STATE  <= 4'd3;
                end else if ((counter_digit == 8'd1) & (!Print_pulse) ) begin
                                  Printer       <= wb_SPACE_ASCII;
                                  Print_pulse   <= 1'b1;
                                  counter_digit <= counter_digit - 8'd1;
                                  CONTROL_STATE <= 4'd4;
                end else if((counter_digit == 8'd0) & (!Print_pulse)) begin
                                  state_reg               <= BCD_PEAK;
                                  counter_channel         <= 0;
                                  Converter_peak          <= 0;
                                  start_conversion_peak   <= 1'b0;
                                  Converter_peak_assigned <= 1'b0;
                                  CONTROL_STATE           <= 4'd5;
                end
                if (Print_pulse) begin
                    Print_pulse <= 1'b0;
                end
            end
            BCD_PEAK : begin
                if (counter_channel <= (N_CH - 1)) begin
                    if((!start_conversion_peak) & (!Converter_peak_assigned)) begin
                        Converter_peak          <= A_peak_event_reg[counter_channel];
                        Converter_peak_assigned <= 1'b1;
                        counter_pause_peak_BCD  <= 8'd10;
                        CONTROL_STATE           <= 4'd6;
                    end else if((!start_conversion_peak) & (Converter_peak_assigned)) begin 
                        if( counter_pause_peak_BCD  == 8'd0) begin 
                            Converter_peak_assigned <= 1'b0;
                            start_conversion_peak   <= 1'b1;
                        end else begin 
                            counter_pause_peak_BCD <= counter_pause_peak_BCD - 8'd1;
                        end 
                    end else if(start_conversion_peak & BCD_peak_ready) begin
                        A_peak_event_BCD[counter_channel] <= BCD_peak;
                        start_conversion_peak             <= 1'b0;
                        counter_channel                   <= counter_channel + 1;
                        CONTROL_STATE                     <= 4'd7;
                    end
                end else begin
                    state_reg       <= BCD_AREA;
                    counter_channel <= 0;
                    counter_digit   <= 0;
                    Print_pulse     <= 1'b0;
                    CONTROL_STATE   <= 4'd8;
                end
            end 
            BCD_AREA : begin
                if (counter_channel <= (N_CH - 1)) begin
                    if((!start_conversion_area) & (!Converter_area_assigned)) begin
                        Converter_area          <= A_area_event_reg[counter_channel];
                        Converter_area_assigned <= 1'b1;
                        counter_pause_area_BCD  <= 8'd10;
                        CONTROL_STATE           <= 4'd6;
                    end else if((!start_conversion_area) & (Converter_area_assigned)) begin 
                        if( counter_pause_area_BCD  == 8'd0) begin 
                            Converter_area_assigned <= 1'b0;
                            start_conversion_area   <= 1'b1;
                        end else begin 
                            counter_pause_area_BCD <= counter_pause_area_BCD - 8'd1;
                        end 
                    end else if(start_conversion_area & BCD_area_ready) begin
                        A_area_event_BCD[counter_channel] <= BCD_area;
                        start_conversion_area             <= 1'b0;
                        counter_channel                   <= counter_channel + 1;
                        CONTROL_STATE                     <= 4'd7;
                    end
                end else begin
                    state_reg               <= BCD_THRESHOLD;
                    counter_channel         <= 0;
                    start_conversion_peak   <= 1'b0;
                    Converter_peak_assigned <= 1'b0;
                    counter_digit           <= 0;
                    Print_pulse             <= 1'b0;
                    CONTROL_STATE           <= 4'd8;
                end
            end 
            BCD_THRESHOLD : begin
                    if((!start_conversion_peak) & (!Converter_peak_assigned)) begin
                        Converter_peak          <= threshold;
                        Converter_peak_assigned <= 1'b1;
                        counter_pause_peak_BCD  <= 8'd10;
                        CONTROL_STATE           <= 4'd6;
                    end else if((!start_conversion_peak) & (Converter_peak_assigned)) begin 
                        if( counter_pause_peak_BCD  == 8'd0) begin 
                            Converter_peak_assigned <= 1'b0;
                            start_conversion_peak   <= 1'b1;
                        end else begin 
                            counter_pause_peak_BCD <= counter_pause_peak_BCD - 8'd1;
                        end 
                    end else if(start_conversion_peak & BCD_peak_ready) begin
                        threshold_BCD_reg      <= BCD_peak;
                        start_conversion_peak  <= 1'b0;
                        CONTROL_STATE          <= 4'd7;
                        state_reg              <= SEND_PEAK;
                        counter_channel <= 0;
                        counter_digit   <= 0;
                        Print_pulse     <= 1'b0;
                        CONTROL_STATE   <= 4'd8;
                    end
            end
            SEND_PEAK : begin
                if(Print_pulse) begin
                    Print_pulse <= 1'b0;
                end
                if (counter_channel <= (N_CH - 1) ) begin
                    if(counter_digit <= (N_DIGIT_OUT_PEAK - 1) ) begin 
                        if(!Print_pulse) begin 
                            Printer                           <= {4'b0011, A_peak_event_BCD[counter_channel][(4*(N_DIGIT_OUT_PEAK)-1) -: 4 ]};
                            A_peak_event_BCD[counter_channel] <= ( A_peak_event_BCD[counter_channel] << 4);
                            Print_pulse                       <= 1'b1;
                            counter_digit                     <= counter_digit + 1;
                            CONTROL_STATE                     <= 4'd9;
                        end
                    end else begin
                        if(!Print_pulse) begin 
                            Printer         <= wb_SPACE_ASCII;
                            Print_pulse     <= 1'b1;
                            counter_channel <= counter_channel + 1;
                            counter_digit   <= 0;
                            CONTROL_STATE   <= 4'd10;
                        end
                    end
                end else begin
                    if(!Print_pulse) begin 
                        Printer               <= 0;
                        Print_pulse           <= 1'b0;
                        state_reg             <= SEND_AREA;
                        counter_digit         <= 0;
                        counter_channel       <= 0;
                        start_conversion_peak <= 1'b0;
                        CONTROL_STATE         <= 4'd11;
                    end
                end
            end
            SEND_AREA : begin
                if(Print_pulse) begin
                    Print_pulse <= 1'b0;
                end
                if (counter_channel <= (N_CH - 1) ) begin
                    if(counter_digit <= (N_DIGIT_OUT_AREA - 1) ) begin
                        if(!Print_pulse) begin 
                            Printer                           <= {4'b0011, A_area_event_BCD[counter_channel][(4*(N_DIGIT_OUT_AREA)-1) -: 4 ]};
                            A_area_event_BCD[counter_channel] <= ( A_area_event_BCD[counter_channel] << 4);
                            Print_pulse                       <= 1'b1;
                            counter_digit                     <= counter_digit + 1;
                            CONTROL_STATE                     <= 4'd9;
                        end
                    end else begin
                        if(!Print_pulse) begin 
                            Printer         <= wb_SPACE_ASCII;
                            Print_pulse     <= 1'b1;
                            counter_channel <= counter_channel + 1;
                            counter_digit   <= 0;
                            CONTROL_STATE   <= 4'd10;
                        end
                    end
                end else begin
                    if(!Print_pulse) begin 
                        Printer               <= 0;
                        state_reg             <= SEND_THRESHOLD;
                        Print_pulse           <= 1'b0;
                        counter_digit         <= 0;
                        counter_channel       <= 0;
                        start_conversion_area <= 1'b0;
                        CONTROL_STATE         <= 4'd11;
                    end
                end
            end
            SEND_THRESHOLD : begin
                if(Print_pulse) begin
                    Print_pulse <= 1'b0;
                end
                if(counter_digit <= (N_DIGIT_OUT_PEAK - 1) ) begin 
                    if(!Print_pulse) begin 
                        Printer                <= {4'b0011, threshold_BCD_reg[(4*(N_DIGIT_OUT_PEAK)-1) -: 4 ]};
                        threshold_BCD_reg      <= ( threshold_BCD_reg << 4);
                        Print_pulse            <= 1'b1;
                        counter_digit          <= counter_digit + 1;
                        CONTROL_STATE          <= 4'd9;
                    end
                end else begin
                    if(!Print_pulse) begin 
                        Printer               <= wb_NEW_LINE;
                        Print_pulse           <= 1'b1;
                        counter_digit         <= 0;
                        counter_channel       <= 0;
                        CONTROL_STATE         <= 4'd10;
                        start_conversion_peak <= 1'b0;
                        state_reg             <= FINAL_STATE;
                    end
                end                
            end
            FINAL_STATE : begin
                state_reg             <= IDLE;
                Print_pulse           <= 1'b0;
                start_conversion_peak <= 1'b0;
                counter_channel       <= 0;
                counter_digit         <= 0;
                CONTROL_STATE         <= 4'd12;
            end
            default: begin 
                state_reg <= IDLE;
            end
        endcase
    end
end


// ********************************
// DAQ pulse positive edge detection
// ********************************

always_ff @(posedge clk, posedge reset) begin
    if(reset) begin 
        DAQ_pulse_old <= 1'b0;
    end else begin 
        DAQ_pulse_old <= DAQ_pulse;
    end
end



// ******************************
//      BCD MODULES 
// ******************************

Binary_to_BCD 
#(
      .INPUT_WIDTH(N_BIT_IN_PEAK),
      .DECIMAL_DIGITS(N_DIGIT_OUT_PEAK)
)
BINARY_BCD_PEAK
(
   .i_Clock(clk),
   .i_Binary(Converter_peak),
   .i_Start(start_conversion_peak),
   .o_BCD(BCD_peak),
   .o_DV(BCD_peak_ready)
);

Binary_to_BCD 
#(
      .INPUT_WIDTH(N_BIT_IN_AREA),
      .DECIMAL_DIGITS(N_DIGIT_OUT_AREA)
)
BINARY_BCD_AREA
(
   .i_Clock(clk),
   .i_Binary(Converter_area),
   .i_Start(start_conversion_area),
   .o_BCD(BCD_area),
   .o_DV(BCD_area_ready)
);



// Modulo uart per invio dei dati
uart
#(
    .DBIT(8),      // # data bits
    .SB_TICK(16),  // # 16 ticks for 1 stop bit
    .FIFO_W(5)     // # addr bits of FIFO
)
UART_MODULE
(
    .clk(clk), 
    .reset(reset),
    .rd_uart(1'b0), 
    .wr_uart(Print_pulse),
    .rx(1'b1),
    .w_data(Printer),
    .dvsr(dvsr),
    .tx_full(),
    .rx_empty(), 
    .tx(tx),
    .r_data()
);


assign control_state = CONTROL_STATE;

endmodule
