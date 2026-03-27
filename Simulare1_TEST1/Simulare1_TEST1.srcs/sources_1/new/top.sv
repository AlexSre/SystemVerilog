module top(
    
    input logic in0,
    input logic in1,
    input logic in2,
    input logic in3,
    input logic[1:0] sel,
    input logic[3:0] data,
    output logic out0,
    output logic out1,
    output logic out2,
    output logic out3
    
    );
    
    logic fir_MUX4;
    logic[1:0] fir_MUX22;
    logic fir_parity;
    
    MUX4 MUX4_1(

    .in0(in0),
    .in1(in1),
    .in2(in2),
    .in3(in3),
    .sel(sel),
    .out0(fir_MUX4)

    );
    
    paritycalc paritycalc_1(

    .in(data),
    .out(fir_parity)

    );
    
     MUX22 MUX22_1(
    
    .in0(~sel),
    .in1(sel),
    .sel(fir_parity),
    .out0(fir_MUX22)
    
    );
    
    DEMUX4 DEMUX4_1(
    
    .in(fir_MUX4),
    .sel(fir_MUX22),
    .out0(out0),
    .out1(out1),
    .out2(out2),
    .out3(out3)
    
    );
    
endmodule
