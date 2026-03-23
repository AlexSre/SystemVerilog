
module top(

    input in0,
    input in1,
    input in2,
    input in3,
    output out0

    );
    
    logic w0,w1;
    
    AND2 AND2_1(

    .in0(in0),
    .in1(in1),
    .out0(w0)

);

AND2 AND2_2(

    .in0(w0),
    .in1(in2),
    .out0(w1)

);

AND2 AND2_3(

    .in0(w1),
    .in1(in3),
    .out0(out0)

);
    
endmodule
