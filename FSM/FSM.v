`timescale 1 ns / 1 ps

module FSM 
    (
    input clk,
    input reset,
    
    // Auxiliars from DATAPATH
    input [11:0] codif,
    
    // Inputs from DATAPATH
    input busy_mem, 
    input done_mem,
    input aligned_mem,
    input done_exec,
    input is_exec,
    
    // Outputs to DATAPATH
    output reg [1:0] W_R_mem,
    output [1:0] wordsize_mem,
    output     sign_mem,
    output reg en_mem,
    output reg enable_exec,
    output reg enable_exec_mem,
    output reg trap,
    output     enable_pc
    );
    
    // MEMORY INTERFACE Auxiliar determination
    wire write_mem;
    wire is_mem;
    wire is_illisn;
    assign write_mem = ~codif[5];    // This is the only bit differs write/read
    assign is_mem = codif[6:0] == 7'b0100011 || codif[6:0] == 7'b0000011 ? 1'b1 : 1'b0;    // OPCODE detection
    assign sign_mem = ~codif[9];    // This is the only bit differs signed/unsigned
    assign wordsize_mem = codif[8:7];    // This is the only bit differs wordsize
    assign is_illisn = &codif || (codif == 12'b000011110011); // FIXME: Also is illegal if ebreak
    
    // CHANGE PC Auxiliar determination
    reg enable_pc_aux, enable_pc_fsm;
    always @ (posedge clk) begin
        if (reset == 1'b0)
            enable_pc_aux <= 1'b0;
        else
            enable_pc_aux <= enable_pc_fsm;
    end
    assign enable_pc = enable_pc_aux == 1'b0 && enable_pc_fsm == 1'b1 ? 1'b1 : 1'b0;
    
    // ERROR Auxiliar determination
    wire err;
    assign err = ~aligned_mem;    // TODO: ILLISN
    
    // Declare state register
    reg        [3:0] state;
    
    // Declare states
    parameter S0_fetch = 0, S1_decode = 1, S2_exec = 2, S3_memory = 3, S4_trap = 4,
              SW0_fetch_wait = 5, SW3_mem_wait = 6;
    
    // Output depends only on the state (transition)
    // Determine the next state (Moore state machine)
    always @ (posedge clk) begin
        if (reset == 1'b0) begin
            state <= S0_fetch;
            
            en_mem <= 1'b0;
            W_R_mem <= 2'b00;
            enable_exec <= 1'b0;
            enable_exec_mem <= 1'b0;
            enable_pc_fsm <= 1'b0;
            trap <= 1'b0;
        end else
            if(err) begin
                state <= S4_trap;
                trap <= 1'b1;
            end else
                case (state)
                    S0_fetch: begin
                        if(!en_mem) begin
                            en_mem <= 1'b1;
                            W_R_mem <= 2'b11;                // For instruction fetching
                        end else if (en_mem && !done_mem) begin
                            state <= SW0_fetch_wait;
                            en_mem <= 1'b0;
                        end else if (en_mem && done_mem) begin
                            state <= S1_decode;
                            W_R_mem <= 2'b00;
                            en_mem <= 1'b0;
                        end
                        
                        
                    end
                    SW0_fetch_wait: begin
                        if (done_mem) begin
                            state <= S1_decode;
                            W_R_mem <= 2'b00;
                            en_mem <= 1'b0;
                        end 
                    end
                    S1_decode: begin
                        if ( is_illisn ) begin
                            state <= S4_trap;
                        end else begin
                            state <= S2_exec;
                            enable_exec <= 2'b11;
                            enable_pc_fsm <= 1'b1;
                        end
                    end
                    S2_exec:
                        if (is_mem) begin
                            state <= S3_memory;
                            enable_exec <= 2'b00;
                            enable_pc_fsm <= 1'b0;
                        end else if (done_exec) begin
                            state <= S0_fetch;
                            enable_exec <= 2'b00;
                            enable_pc_fsm <= 1'b0;
                        end else
                            state <= S2_exec;
                    S3_memory: begin
                        if(!en_mem) begin
                            en_mem <= 1'b1;
                            enable_exec_mem <= write_mem;
                            W_R_mem <= {1'b0, write_mem};                // For reading/writting
                        end else if (en_mem && !done_mem) begin
                            state <= SW3_mem_wait;
                            en_mem <= 1'b0;
                        end else if (en_mem && done_mem) begin
                            state <= S0_fetch;
                            W_R_mem <= 2'b00;
                            en_mem <= 1'b0;
                            enable_exec_mem <= 1'b0;
                        end
                    end
                    SW3_mem_wait: begin
                        if (done_mem) begin
                            state <= S0_fetch;
                            
                            W_R_mem <= 2'b00;
                            enable_exec_mem <= 1'b0;
                            en_mem <= 1'b0;
                        end else
                            state <= SW3_mem_wait;
                    end
                    S4_trap: begin
                        state <= S4_trap;
                        trap <= 1'b1;
                    end
                endcase
    end
    

endmodule
