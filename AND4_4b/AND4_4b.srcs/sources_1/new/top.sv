
module top(

    input logic [3:0] in0,
    input logic [3:0] in1,
    input logic [3:0] in2,
    input logic [3:0] in3,
    output logic [3:0] out0    
    );
    
    AND4_1b AND4_1b_1(
    
    .in0(in0[0]),
    .in1(in1[0]),
    .in2(in2[0]),
    .in3(in3[0]),
    .out0(out0[0])    
    );
    
    AND4_1b AND4_1b_2(
    
    .in0(in0[1]),
    .in1(in1[1]),
    .in2(in2[1]),
    .in3(in3[1]),
    .out0(out0[1])    
    );
    
    AND4_1b AND4_1b_3(
    
    .in0(in0[2]),
    .in1(in1[2]),
    .in2(in2[2]),
    .in3(in3[2]),
    .out0(out0[2])    
    );
    
    AND4_1b AND4_1b_4(
    
    .in0(in0[3]),
    .in1(in1[3]),
    .in2(in2[3]),
    .in3(in3[3]),
    .out0(out0[3])    
    );
    
    
endmodule
