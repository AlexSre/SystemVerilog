module comp_gt(
    
    input logic [3:0] in0,
    input logic [3:0] in1,
    input en,
    output out0
    
    );
    
    assign out0=( in1 > in0 & en == 1 )? 1 : 0;
    
endmodule
