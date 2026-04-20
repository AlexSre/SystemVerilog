module reverse(
    
    input logic [3:0] in0,
    output logic [3:0] out0
    
    );
    
    assign out0[0] = in0[3];
    assign out0[1] = in0[2];
    assign out0[2] = in0[1];
    assign out0[3] = in0[0];
    
endmodule
