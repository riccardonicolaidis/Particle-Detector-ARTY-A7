module DAQ
#(parameter N_CH = 2,
            N_T  = 32,
            N_P  = 12,
            N_A  = 20
)
( 
    input logic                   clk,                      // Clock 
    input logic                   reset,                    // Reset
    input logic         [N_T-1:0] time_ms,                  // Time continuously flowing 
    input logic signed  [N_P-1:0] A_peak       [N_CH-1:0],  // Peak values array
    input logic signed  [N_A-1:0] A_area       [N_CH-1:0],  // Area value array
    input logic                   peak_ready   [N_CH-1:0],  // peak ready flag   (posedge)
    input logic                   area_ready   [N_CH-1:0],  // area ready flag   (posedge)
    input logic                   coincidence_flag,         // coincidence flag  (posedge)
    
    output logic        [N_T-1:0] time_event,                // Time of the event
    output logic signed [N_P-1:0] A_peak_event [N_CH-1:0],   // Peak values array of the event
    output logic signed [N_A-1:0] A_area_event [N_CH-1:0],   // Area value array of the event
    output logic DAQ_pulse                                   // Output pulse to send data to memory or uart
);
    
// Signal declarations   
logic            coincidence_flag_old;      // register to store the old coincidence flag
wire  [N_CH-1:0] peak_ready_monostable;     // peak ready flag   (posedge)
wire  [N_CH-1:0] area_ready_monostable;     // area ready flag   (posedge)
wire             all_data_ready;            // AND reduction operators
logic            time_acquired;             // Flag stating that the time has been acquired
logic [N_T:0]    time_reg;                  // Register to store time 
logic            DAQ_pulse_reg;             // DAQ_pulse for data sending 
logic            clear_pulse;               // clear_pulse for latches

// Type definition for the finite state machine 
typedef enum {IDLE, 
              WAITING_STORE, 
              SEND_PULSE, 
              RESET } acquisition_state;
acquisition_state state_reg;
// Monostable instantiation to build a signal for the finite state machine 

// Instantiation of an array of monostables 
genvar i;
generate 
    for(i=0; i<= (N_CH-1); i = i+1) begin : Data_Acquisition_pipeline_generation
        // Monostable for peak
        Monostable_rise_only MONOSTABLES_PEAK
        (
            .clk(clk),                                          // clock
            .reset(reset),                                      // reset low 
            .clear(clear_pulse),                                // clear pulse (= reset)
            .trigger_pulse(peak_ready[i]),                      // trigger input
            .handshake(peak_ready_monostable[i])                // output pulse 
        );

        // monostable for area
        Monostable_rise_only MONOSTABLES_AREA
        (
            .clk(clk),                                          // clock
            .reset(reset),                                      // reset low 
            .clear(clear_pulse),                                // clear pulse (= reset)
            .trigger_pulse(area_ready[i]),                      // trigger input 
            .handshake(area_ready_monostable[i])                // output pulse
        );

        Buffers_reg_LATCH
        #(
            .width(N_P)
        )
        LATCHES_PEAK
        (
            .clk(clk),                     // Clock
            .reset(reset),                 // Reset
            .wb_signal_in(A_peak[i]),      // Signal incoming 
            .update_flag(peak_ready[i]),   // Update signal (posedge)
            .output_latch(A_peak_event[i]) // Output of the buffer (TO OUTPUT)
        );

        Buffers_reg_LATCH
        #(
            .width(N_A)
        )
        LATCHES_AREA
        (
            .clk(clk),                     // Clock
            .reset(reset),                 // Reset
            .wb_signal_in(A_area[i]),      // Signal incoming 
            .update_flag(area_ready[i]),   // Update signal (posedge)
            .output_latch(A_area_event[i]) // Output of the buffer (TO OUTPUT)
        );
    end
endgenerate 

// COMBINATIONAL LOGIC
// REDUCTUION OPERATION
assign all_data_ready = (&area_ready_monostable) & (&peak_ready_monostable);

// Sequential acquisition with registers 

always_ff @(posedge clk, posedge reset) begin
    if(reset) begin
        state_reg       <= IDLE;
        DAQ_pulse_reg   <= 1'b0;
        clear_pulse     <= 1'b1;
        time_reg        <= 0;
        time_acquired   <= 1'b0;
    end
    else begin
        if(clear_pulse) begin 
            clear_pulse <= 1'b0;
        end
        case(state_reg)
            IDLE: begin
                DAQ_pulse_reg   <= 1'b0;
                clear_pulse     <= 1'b0;
                if(coincidence_flag & (!coincidence_flag_old))
                    state_reg <= WAITING_STORE;
            end
            WAITING_STORE: begin
                if(!time_acquired) begin
                    time_reg      <= time_ms;
                    time_acquired <= 1'b1;
                end
                if(time_acquired & all_data_ready) begin
                    DAQ_pulse_reg <= 1'b1;
                    state_reg     <= SEND_PULSE;
                end
            end
            SEND_PULSE: begin 
                state_reg <= RESET;
            end
            RESET: begin 
                state_reg     <= IDLE;
                time_acquired <= 1'b0;
                clear_pulse   <= 1'b1;
            end
            default: 
                state_reg <= IDLE;
        endcase
        coincidence_flag_old <= coincidence_flag;
    end
end

// Combinational logic for output 
assign time_event = time_reg;
assign DAQ_pulse  = DAQ_pulse_reg;

    
endmodule
