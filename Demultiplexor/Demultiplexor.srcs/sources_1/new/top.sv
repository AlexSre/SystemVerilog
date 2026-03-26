module top(

    input logic in0,
    input sel,
    output logic out0,
    output logic out1

    );
    
    assign out0 = 0;
    assign out1 = 0;
    
    always_comb
    begin 
        case(sel)
            0: out0=in0;
            1: out1=in0;
            default: out0=0;
        endcase
    end
    
endmodule
