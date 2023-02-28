module Data_acquisition_tb();


localparam N_CH      = 2;
localparam N_P       = 12;
localparam N_A       = 20; 
localparam N_T       = 32;
localparam Size_log2 = 15;
localparam T         = 20;


logic clk, reset;
wire [29:0] number_samples_to_skip;
wire [29:0] disable_time;
assign disable_time           = 30'd600; 
assign number_samples_to_skip = 30'd20;    

wire signed [N_P-1:0] threshold;  // THRESHOLD 
assign threshold = 12'd1000;


// SAMPLED SIGNALS DECLARATIONS 
logic signed [N_P-1:0] A              [N_CH-1:0];  // Sampled channels (wire bus array)
logic                  A_pulse        [N_CH-1:0];  // Sample pulses   (wire array)
wire  signed [N_P-1:0] A_peak         [N_CH-1:0];  // From DSP pipeline the Peaks (wire bus array)
wire  signed [N_A-1:0] A_area         [N_CH-1:0];  // From DSP pipeline the Areas (wire bus array)
wire                   peak_ready     [N_CH-1:0];  // From DSP pipeline "Peak is ready" (wire array)
wire                   area_ready     [N_CH-1:0];  // From DSP pipeline "Area is ready" (wire array)
wire                   coincidence_flag;       // Handshacking signal for coincidence detection
wire                   DC_subtracted  [N_CH-1:0];
wire                   posedge_flag   [N_CH-1:0];
wire                   over_threshold [N_CH-1:0];
// FROM THE DAQ SYSTEM TO THE DATA MANAGER FOR SENDING
wire         [N_T-1:0] time_event;                // Time of the event 
wire  signed [N_P-1:0] A_peak_event   [N_CH-1:0];   // Peak values array of the event
wire  signed [N_A-1:0] A_area_event   [N_CH-1:0];   // Area value array of the event
wire                   DAQ_pulse;                 // Output pulse to send data to memory or uart
logic        [N_T-1:0] time_ms;    // TIME ms
logic                  tx;

DSP_pipeline
#(
    .N_CH(N_CH),          // Number of channels 
    .N_P(N_P),            // Number of bits XADC 12
    .N_A(N_A),            // Number of bits for area measurement (20 default)
    .Size_log2(Size_log2)
)
DSP_from_XADC
(
    .clk(clk),                          // clock
    .reset(reset),                  // reset low 
    .number_samples_to_skip(number_samples_to_skip),
    .A(A),                              // Input from XADC wrapping circuit 
    .A_pulse(A_pulse),                  // Sampling frequency from wrapping circuit 
    .threshold(threshold),              // threshold from threshold controller
    .disable_time(disable_time),        // disable time (SEE SETTING SECTION)
    .A_peak(A_peak),                    // OUT Values of the peak
    .A_area(A_area),                    // OUT Values of the area
    .peak_ready(peak_ready),            // The peak is ready (0 1) OUT
    .area_ready(area_ready),            // The area is ready (0 1) OUT
    .coincidence_flag(coincidence_flag), // Coincidence detection flag OUT
    .DC_subtracted(DC_subtracted),
    .posedge_flag(posedge_flag),
    .over_threshold(over_threshold)
);  



// *********************************
// DATA ACQUISITION SYSTEM 
// *********************************
DAQ
#(
    .N_CH(N_CH),   // Number of channels 
    .N_T(N_T),     // Number of bits destinated to the time 
    .N_A(N_A),     // Number of bits for area measurement 20
    .N_P(N_P)      // Number of bits for peak detection 12
)
DAQ_system
(
    .clk(clk),                           // clock 
    .reset(reset),                   // reset_low
    .time_ms(time_ms),                   // time in millisecond BCD
    .A_peak(A_peak),                     // Peak values from DSP
    .A_area(A_area),                     // Area values from DSP                   
    .peak_ready(peak_ready),             // peak ready flag (0 1)
    .area_ready(area_ready),             // area ready flag (0 1)
    .coincidence_flag(coincidence_flag), // coincidence flag (0 1)
    .time_event(time_event),             // Time of the event in millisecond BCD
    .A_peak_event(A_peak_event),         // Peak values array of the event
    .A_area_event(A_area_event),         // Area value array of the event
    .DAQ_pulse(DAQ_pulse)                // Output pulse to send data to memory or uart
);

// ***************************
// TIME MEASUREMENT UNIT 
// ***************************
Module_Time_Measurement TIME_MEASUREMENT
(
    .clk(clk),          // clock 
    .reset(reset),  // reset low
    .out(time_ms)       // time in millisecond BCD
);



Printer_uart
#(
    .N_T(N_T),     // Number of bits destinated to time
    .N_P(N_P),     // Number of bits peak detection 12
    .N_A(N_A),     // Number of bits area detection 20
    .N_CH(N_CH)    // Number of channels 
)
PRINT_DATA_VIA_UART_CABLE
(
    .clk(clk),                     // clock
    .reset(reset),             // reset low
    .dvsr(11'd80),                   // divisor for UART
    .time_event(time_event),       // Time of the event
    .A_peak_event(A_peak_event),   // Peak values array of the event
    .A_area_event(A_area_event),   // Area value array of the event
    .threshold(threshold),         // Threshold from threshold controller
    .DAQ_pulse(DAQ_pulse),         // Output pulse to send data to memory or uart
    .tx(tx),                     // To the physical UART pin
    .control_state()
);







always begin
    clk = 1;
    #(T/2);
    clk = 0;
    #(T/2);
end

initial begin
    A[0] = 12'd0;
    A[1] = 12'd0;
    reset = 0;
    #(5*T);
    reset = 1;
    #(3*T);
    reset = 0;
end


always begin 
    A[0] = A[0] + 2;
    A[1] = A[1] - 1;
    #(10*T);
end


always begin 
    A_pulse[0] = 0;
    A_pulse[1] = 0;
    #(9*T);
    A_pulse[0] = 1;
    A_pulse[1] = 1;
    #(1*T);
end


endmodule
