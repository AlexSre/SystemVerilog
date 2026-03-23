
module top(

    input in0,
    input in1,
    input in2,
    input in3,
    output out0

    );
    
    logic w0,w1;
    
    OR2 OR2_1(

    .in0(in0),
    .in1(in1),
    .out0(w0)

);

OR2 OR2_2(

    .in0(in2),
    .in1(in3),
    .out0(w1)

);

OR2 OR2_3(

    .in0(w0),
    .in1(w1),
    .out0(out0)

);
    
endmodule
