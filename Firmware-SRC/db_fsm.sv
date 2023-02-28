module db_fsm(

    logic clk, reset,
    input logic sw,
    output logic db
    );
    
    // Number of counter bits 
    localparam N = 20;
    // FSM states 
    typedef enum {
    zero, wait1_1, wait1_2, wait1_3,
    one, wait0_1, wait0_2, wait0_3
    }  state_type;
    
    
    // Signal declaration 
    state_type state_reg, state_next;
    logic [N-1:0] q_reg;
    logic [N-1:0] q_next;
    logic m_tick;
    
    
    // body   
    // **********************
    // counter 
    // **********************
    always_ff @(posedge clk)
        q_reg <= q_next; // next count
        
    assign q_next = q_reg + 1; // increment +1
    assign m_tick = (q_reg == 0)? 1'b1 : 1'b0; // output tick 
    
    // debouncing FSM 
    // state register
    always_ff @(posedge clk, posedge reset) begin
        if (reset)
            state_reg <= zero;
        else
            state_reg <= state_next;
    end
    // combinational logic for next state 
    
    always_comb begin
        // default state
        state_next = state_reg;
        db = 0;
        
        case (state_reg)
            zero: 
                if(sw)
                    state_next = wait1_1;
            wait1_1:
                if(~sw)
                    state_next = zero;
                else 
                    if(m_tick)
                        state_next = wait1_2;
            wait1_2:
                if(~sw)
                    state_next = zero;
                else 
                    if(m_tick)
                        state_next = wait1_3;
            wait1_3:
                if(~sw)
                    state_next = zero;
                else 
                    if(m_tick)
                        state_next = one;
                        
                        
            one: begin
                db = 1'b1;
                if(~sw)
                    state_next = wait0_1;
                end
            wait0_1: begin 
                db = 1'b1;
                if(sw)
                    state_next = one;
                else 
                    if(m_tick)
                        state_next = wait0_2;
                end
            wait0_2: begin
                db = 1'b1;
                if(sw)
                    state_next = one;
                else 
                    if(m_tick)
                        state_next = wait0_3;
                end
            wait0_3: begin
                db = 1'b1;
                if(sw)
                    state_next = one;
                else 
                    if(m_tick)
                        state_next = zero;
                end
            default state_next = zero;
        endcase 
    end
    
    
    
endmodule
