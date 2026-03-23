module top (

    input in0,
    input in1,
    input in2,
    input in3,
    output out0

);

logic w0, w1, w2;

NAND2 NAND2_1(

    .i0(i0),
    .i1(i1),
    .out0(w0)

    );
    
    NAND2 NAND2_2(

    .i0(i1),
    .i1(i2),
    .out0(w1)

    );
    
    NAND2 NAND2_3(

    .i0(w0),
    .i1(w1),
    .out0(w2)

    );
    
    NAND2 NAND2_4(

    .i0(w2),
    .i1(w2),
    .out0(out0)

    );

endmodule