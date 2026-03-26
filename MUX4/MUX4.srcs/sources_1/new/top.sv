module top(

    input in0,
    input in1,
    input in2,
    input in3,
    input logic [1:0] sel, 
    output out0
    
    );
    
    logic w0;
    logic w1;
    
    MUX2 MUX2_1(

    .in0(in0),
    .in1(in1),
    .sel(sel[0]),
    .out0(w0)

    );
    
    MUX2 MUX2_2(

    .in0(in2),
    .in1(in3),
    .sel(sel[0]),
    .out0(w1)

    );
    
    MUX2 MUX2_3(

    .in0(w0),
    .in1(w1),
    .sel(sel[1]),
    .out0(out0)

    );
    
endmodule
