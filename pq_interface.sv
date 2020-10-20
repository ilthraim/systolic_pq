`timescale 1ns / 1ps
//Ethan Miller
//Interface between AXI Bus and systolic priority queue


module pq_interface #(parameter KW=8, VW=4)(
    input logic clk, rst,
    input logic [KW+VW-1:0] idata_in,
    input logic ivalid_in, irdy_in,
    output logic [KW+VW-1:0] idata_out,
    output logic ivalid_out,
    output logic [1:0] state_out
    );
    
    logic [KW+VW-1:0] holdReg;
    
    typedef enum logic [1:0] {inputWait = 1, PQWait = 2, write = 3} states_t;
    
    states_t state, next;
    
    assign state_out = state;
    
    always_ff @(posedge clk)
    begin
        if (rst)
        begin
            state <= inputWait;
            idata_out <= 0;
            ivalid_out <= 0;
            holdReg <= 0;
        end
        else
        begin
            state <= next;
            
            case(state)
                inputWait:
                begin
                    ivalid_out <= 0;
                    idata_out <= '0;
                    if (ivalid_in && (idata_in != holdReg))
                        holdReg <= idata_in;
                end
                write:
                begin
                    ivalid_out <= 1;
                    idata_out <= holdReg;
                end
            endcase
        end
    end
    
    always_comb
    begin
        case(state)
            inputWait:
            begin
                if (ivalid_in && (idata_in != holdReg) && irdy_in)
                    next = write;
                else if (ivalid_in && (idata_in != holdReg))
                    next = PQWait;
                else
                    next = inputWait;
            end
            PQWait:
            begin
                if (irdy_in)
                    next = write;
                else
                    next = PQWait;
            end
            write:
                next = inputWait;
            default:
                next = inputWait;
         endcase   
    end
    
endmodule
