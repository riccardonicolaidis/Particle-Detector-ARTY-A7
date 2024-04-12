/*************************************************************************************************************************************
######################################################################################################################################
  _____ ____   ____    _   _                                 _    ____ _______   __   _            _      _            _             
 |  ___|  _ \ / ___|  / \ | |_ _ __ ___   ___  ___   _ __   / \  |  _ \_   _\ \ / /__| | ___    __| | ___| |_ ___  ___| |_ ___  _ __ 
 | |_  | |_) | |  _  / _ \| __| '_ ` _ \ / _ \/ __| | '_ \ / _ \ | |_) || |  \ V / __| |/ _ \  / _` |/ _ \ __/ _ \/ __| __/ _ \| '__|
 |  _| |  __/| |_| |/ ___ \ |_| | | | | | (_) \__ \ | |_) / ___ \|  _ < | |   | | (__| |  __/ | (_| |  __/ ||  __/ (__| || (_) | |   
 |_|   |_|    \____/_/   \_\__|_| |_| |_|\___/|___/ | .__/_/   \_\_| \_\|_|   |_|\___|_|\___|  \__,_|\___|\__\___|\___|\__\___/|_|   
                                                    |_|                                                                              
######################################################################################################################################
This is my implementation of a atmospheric muon telescope using the ARTY A7 FPGA developement board by Digilent.
- Software used for synthesis, implementation and bitstream generation: Vivado 2021.1
- Hardware used: Arty A7-35T evaluation board (Digilent): Artix 7 FPGA by Xilinx
- Author: Nicolaidis Riccardo

# SOME NOTES ON THE DESIGN #

- The top module is "muon_telescope_top_module" and inside the module definition there are some parameters which hava to be set up
correctly by the user before synthesis to chosing the number of acquired channels

- If you change the number of channels in the top module, then you need to open the "XADC Wiziard" in Vivado software, change the 
"Sequenced channels" and re-run the synthesis of the component XADC. When the synthesis is finished you need to open the file "NAME_stub.v"
in the IP resources, copy the code 
        .INIT_40(16'h0000),
        .INIT_41(16'h21A0),
        .INIT_42(16'h0400),...
and replace the part contained in the file "NAME_netlist.v". This is required because the XADC module comes from an IP by Xilinx and
to set up properly the sequencer settings you need to generate the encrypted sources. In principle one could change by hand the 
registers in the instantiation (.INIT_40(1b'h...)). This procedure, however, is quite tedious since it is required to know the meaning
of all these registers. The procedure exploiting the XADC wiziard is more "user friendly" even if it is a bit longer. After generating
the correct template for the XADC module you need to "disable the source file" using the Vivado navigation menu. This because in the 
xadc_netlist.v file there are the instructions used by vivado to generate the required sources and so the IP generated via the IP
catalogue is unnecessary.

- The system is clocked using the mounted 100 MHz clock.

- The system reset is the button C2. However, this is active high. It has been generated an active low reset to prevent
misunderstanding in the design. 

- To avoid bouncing effects from the push buttons, some debouncers are placed into the design.

DISABLE TIME:
This disable time has to be computed using the following formula
disable_time = (100 MHz * #desired_sampling_times) / (2 * sampling_frequency)

Example :
 - #desired_sampling_times = 2
 - 2 channels : sampling_frequency = 480 kHz
 - disable time = 208

**************************************************************************************************************************************/


module muon_telescope_top_module
(
    input  logic clk,                     // clock
    input  logic reset_high,              // reset
    input  logic [3:0] btn,               // push buttons
    input  logic [3:0] sw,                // switches 
    output logic [3:0] led,               // leds
//  output logic [3:0] led_r,             // RGB led R
//  output logic [3:0] led_g,             // RGB led G
//  output logic [3:0] led_b,             // RGB led B
//  input  logic rx,                      // UART rx    
    output logic tx,                      // UART tx
    input  logic [8:0] adc_a_p, adc_a_n,  // 6 analog channels
    input  logic vp_in, vn_in,            // dedicated analog
    output logic [13:0] ck_io,            // Test pins OUTPUT    

    input  logic A0_in,                   // Pmod A0
    input  logic A1_in,                   // Pmod A1
    output logic o_SCK,                   // Pmod SCK
    output logic o_CS_not                 // Pmod CS_not
               
);
// #################################
// RESET  -> ACTIVE LOW DEFINITION
// #################################
wire   reset_low;               // Wire combinational 
assign reset_low = ~reset_high; // Active low reset


// This is the number of samples the DC filter skips.
wire [29:0] number_samples_to_skip;
wire [29:0] disable_time;
wire [10:0] dvsr;


/*
                ░██████╗███████╗████████╗████████╗██╗███╗░░██╗░██████╗░░██████╗
                ██╔════╝██╔════╝╚══██╔══╝╚══██╔══╝██║████╗░██║██╔════╝░██╔════╝
                ╚█████╗░█████╗░░░░░██║░░░░░░██║░░░██║██╔██╗██║██║░░██╗░╚█████╗░
                ░╚═══██╗██╔══╝░░░░░██║░░░░░░██║░░░██║██║╚████║██║░░╚██╗░╚═══██╗
                ██████╔╝███████╗░░░██║░░░░░░██║░░░██║██║░╚███║╚██████╔╝██████╔╝
                ╚═════╝░╚══════╝░░░╚═╝░░░░░░╚═╝░░░╚═╝╚═╝░░╚══╝░╚═════╝░╚═════╝░
                         ██████████████████████████████████████████████
                         █ !!!READ CAREFULLY THE DESCRIPTION ABOVE!!! █
                         ██████████████████████████████████████████████
*/                       
/********************************************************************************************/
/****/  parameter N_XADC_CH           = 2;  // Number of channels (XADC)                /****/ 
/****/  parameter N_XADC_CH_TOREAD    = 0; // Number of channels to read (XADC)         /****/
/****/  parameter N_PMOD              = 1;  // Number of Pmods                          /****/
/****/  parameter N_CH                = N_XADC_CH_TOREAD + 2*N_PMOD; // Tot channles    /****/  
/****/  parameter N_T                 = 48; // Number of bits from TIME MEASURING       /****/  
/****/  parameter N_A                 = 30; // Number of bits for Area measurement      /****/  
/****/  parameter N_P                 = 12; // Number of bits for peak detection        /****/ 
/****/  parameter N_P_PADDING         = 13; // Number of bits for peak detection PADDED /****/
/****/  parameter Size_log2           = 20; // Number of samples for average (log 2)    /****/
/****/  assign disable_time           = 30'd600;   // coincidence detection             /****/  
/****/  assign number_samples_to_skip = 30'd20;                                         /****/
/****/  assign dvsr                   = 11'd53;                                         /****/
/********************************************************************************************/

// Divisor table for UART BAUD RATE
/*
------------------------------------
|   BAUD RATE     |  DIVISOR       |
------------------------------------
|   9600          |  650           |
|   115200        |  53            |
|   76800         |  80            |
------------------------------------
*/




// ############################
// SIGNAL DECLARATIONS 
// ############################

wire         [3:0]     btn_db;     // DEBOUNCED BUTTONS 
logic                  w_tx;       // TX UART WIRE 
logic        [N_T-1:0] time_ms;    // TIME ms
logic signed [N_P-1:0] threshold;  // THRESHOLD 
wire                   w_CS_not;   // wire chip select for


// SAMPLED SIGNALS DECLARATIONS 
wire  signed [N_P-1:0] A              [N_CH-1:0];  // Sampled channels (wire bus array)
wire                   A_pulse        [N_CH-1:0];  // Sample pulses   (wire array)
wire  signed [N_P-1:0] A_peak         [N_CH-1:0];  // From DSP pipeline the Peaks (wire bus array)
wire  signed [N_A-1:0] A_area         [N_CH-1:0];  // From DSP pipeline the Areas (wire bus array)
wire                   peak_ready     [N_CH-1:0];  // From DSP pipeline "Peak is ready" (wire array)
wire                   area_ready     [N_CH-1:0];  // From DSP pipeline "Area is ready" (wire array)
wire                   coincidence_flag;           // Handshacking signal for coincidence detection
wire                   DC_subtracted  [N_CH-1:0];
wire                   posedge_flag   [N_CH-1:0];
wire                   over_threshold [N_CH-1:0];
// FROM THE DAQ SYSTEM TO THE DATA MANAGER FOR SENDING
wire         [N_T-1:0] time_event;                // Time of the event 
wire  signed [N_P-1:0] A_peak_event   [N_CH-1:0]; // Peak values array of the event
wire  signed [N_A-1:0] A_area_event   [N_CH-1:0]; // Area value array of the event
wire                   DAQ_pulse;                 // Output pulse to send data to memory or uart
    
// *************************************
//      DEBOUNCER 
// *************************************
debouncing_array
#(
    .N(4)
)           
    DEBOUNCER_BTNS
(
    .clk(clk),          // clock 
    .reset(reset_low),  // reset low
    .in_sw(btn),        // raw push buttons 
    .out_db(btn_db)     // push buttons debounced
);

// ****************************************
//      THRESHOLD CONTROLLER
// ****************************************
threshold_controller
#
(
    .N_P(N_P)             // Number of bits (same of the ADC 12 bit )
)
THRESHOLD_CONTROLLER
(
    .clk(clk),            // clock 
    .reset(reset_low),    // reset low 
    .sw(sw),              // switches (enable signal, see the module)
    .btn_db(btn_db),      // debounced buttons 
    .threshold(threshold) // output threshold 
);

   
// **************************************
//  XADC WRAPPING CIRCUIT 
// **************************************
generate
    if(N_XADC_CH_TOREAD > 0) begin
        XADC_module 
        #(
            .N_CH(N_XADC_CH),   // Number of channels (only XADC)
            .N_P(N_P)           // Number of bits 12
        )
        XADC_WRAPPING_CIRCUIT
        (
            .clk(clk),                        // clock 
            .reset(reset_low),                // reset low 
            .adc_a_p(adc_a_p),                // input analog  
            .adc_a_n(adc_a_n),                // input analog
            .vp_in(vp_in),                    // dedicated analog +
            .vn_in(vn_in),                    // dedicated analog -
            .A(A[N_XADC_CH_TOREAD-1:0]),             // A Digitalized 12-bit OUT
            .A_pulse(A_pulse[N_XADC_CH_TOREAD-1:0])  // A ready pulse 
        );
    end
endgenerate

// *****************************************
//      PMOD_ADC_WRAPPING_CIRCUIT
// *****************************************

/*
ENTITY pmod_adc_ad7476a IS
  GENERIC(
    clk_freq    :  INTEGER := 100; --system clock frequency in MHz
    spi_clk_div :  INTEGER := 3);  --spi_clk_div = clk_freq/40 (answer rounded up)
  PORT(
    clk         :  IN      STD_LOGIC;                      --system clock
    reset_n     :  IN      STD_LOGIC;                      --active low reset
    data_in_0   :  IN      STD_LOGIC;                      --channel 0 serial data from ADC
    data_in_1   :  IN      STD_LOGIC;                      --channel 1 serial data from ADC
    sck         :  BUFFER  STD_LOGIC;                      --serial clock
    cs_n        :  BUFFER  STD_LOGIC_VECTOR(0 DOWNTO 0);   --chip select
    adc_0_data  :  OUT     STD_LOGIC_VECTOR(11 DOWNTO 0);  --channel 0 ADC result
    adc_1_data  :  OUT     STD_LOGIC_VECTOR(11 DOWNTO 0)); --channel 1 ADC result
END pmod_adc_ad7476a;
*/

pmod_adc_ad7476a
#
(
    .clk_freq(32'd100),
    .spi_clk_div(32'd3)
)
WRAPPING_CIRCUIT_PMOD_AD1
(
    .clk(clk),
    .reset_n(reset_high),
    .data_in_0(A0_in),
    .data_in_1(A1_in),
    .sck(o_SCK),
    .cs_n(w_CS_not),
    .adc_0_data(A[N_CH-2]),
    .adc_1_data(A[N_CH-1])
);

// Generation of the update frequency pulse for the signals coming from the Pmod
assign A_pulse[N_CH-2] = (!w_CS_not);  // The sampling frequency Pmod is dictated by the Chip Select
assign A_pulse[N_CH-1] = (!w_CS_not);  // The sampling frequency Pmod is dictated by the Chip Select




// ****************************************
// DSP PIPELINE FOR COINCIDENCE DETECTION
// ****************************************

DSP_pipeline
#(
    .N_CH(N_CH),              // Number of channels 
    .N_P(N_P),                // Number of bits XADC 12
    .N_P_PADDING(N_P_PADDING),// Number of bits after padding with zero
    .N_A(N_A),                // Number of bits for area measurement (20 default)
    .Size_log2(Size_log2)
)
DSP_from_XADC
(
    .clk(clk),                          // clock
    .reset(reset_low),                  // reset low 
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
    .reset(reset_low),                   // reset_low
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
    .reset(reset_low),  // reset low
    .out(time_ms)       // time in millisecond BCD
);

// *******************************
// PRINT DATA 
// *******************************
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
    .reset(reset_low),             // reset low
    .dvsr(dvsr),                   // divisor for UART
    .time_event(time_event),       // Time of the event
    .A_peak_event(A_peak_event),   // Peak values array of the event
    .A_area_event(A_area_event),   // Area value array of the event
    .threshold(threshold),         // Threshold from threshold controller
    .DAQ_pulse(DAQ_pulse),         // Output pulse to send data to memory or uart
    .tx(w_tx),                     // To the physical UART pin
    .control_state(led)
);

// *************************
//  TESTING UNIT 
// *************************
test_unit 
#(
    .N_CH(N_CH),
    .N_P(N_P)
)
TEST_UNIT
(
    .clk(clk),               // clock
    .reset(reset_low),       // reset low       
    .w_tx(w_tx),             // To display what has been sent to the UART cable
    .DAQ_pulse(DAQ_pulse),
    .peak_ready(peak_ready),             // The peak is ready (0 1) OUT
    .area_ready(area_ready),             // The area is ready (0 1) OUT
    .coincidence_flag(coincidence_flag), // Coincidence detection flag OUT
    .DC_subtracted(DC_subtracted),
    .posedge_flag(posedge_flag),
    .over_threshold(over_threshold),
    .A_pulse(A_pulse),       // Sampling frequency from wrapping circuit  
    .ck_io(ck_io)            // General input output pin
);



// *************************
// COMBINATIONAL CIRCUIT OUT 
// *************************
assign tx       = w_tx;              // Physical UART TX 
assign o_CS_not = w_CS_not;          // Physical CS_not on the Pmod

endmodule
