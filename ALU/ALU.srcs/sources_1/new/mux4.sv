module mux4(
    
    input logic[3:0] in0,
    input logic[3:0] in1,
    input logic[3:0] in2,
    input logic[3:0] in3,
    input logic[1:0] sel,
    output logic[3:0] out0
    
    );
    
    always_comb
    begin
    
        case(sel)
            0: out0 = in0;
            1: out0 = in1;
            2: out0 = in2;
            3: out0 = in3;
            default: out0 = in0;
        endcase
    
    end
    
endmodule
