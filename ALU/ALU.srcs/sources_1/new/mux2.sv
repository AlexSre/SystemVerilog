module mux2(

    input logic[3:0] in0,
    input logic[3:0] in1,
    input logic sel,
    output logic[3:0] out0
    
    );
    
    always_comb
    begin
    
        case(sel)
            0: out0 = in0;
            1: out0 = in1;
            default: out0 = in0;
        endcase
    
    end
    
endmodule
