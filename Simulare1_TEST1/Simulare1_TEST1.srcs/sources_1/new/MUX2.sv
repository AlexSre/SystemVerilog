module MUX2(
    
    input logic in0,
    input logic in1,
    input logic sel,
    output logic out0
    
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
