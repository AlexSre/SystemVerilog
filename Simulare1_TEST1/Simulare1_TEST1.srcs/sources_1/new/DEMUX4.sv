module DEMUX4(
    
    input logic in,
    input logic[1:0] sel,
    output logic out0,
    output logic out1,
    output logic out2,
    output logic  out3
    
    );
    
    assign out0 = 0;
    assign out1 = 0;
    assign out2 = 0;
    assign out3 = 0;
    
    always_comb
    begin
    
        case(sel)
            
            0: out0 = in;
            1: out1 = in;
            2: out2 = in;
            3: out3 = in;
            
        endcase
    
    end
    
endmodule
