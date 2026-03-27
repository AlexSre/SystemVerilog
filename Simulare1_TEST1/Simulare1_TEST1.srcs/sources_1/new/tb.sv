`timescale 1ns / 1ps
module tb();

    logic in0_tb;
    logic in1_tb;
    logic in2_tb;
    logic in3_tb;
    logic [1:0] sel_tb;
    logic [3:0] data_tb;
    logic out0_tb;
    logic out1_tb;
    logic out2_tb;
    logic out3_tb;
    
    top dut(
    
    .in0(in0_tb),
    .in1(in1_tb),
    .in2(in2_tb),
    .in3(in3_tb),
    .sel(sel_tb),
    .data(data_tb),
    .out0(out0_tb),
    .out1(out1_tb),
    .out2(out2_tb),
    .out3(out3_tb)
    
    );
    
    initial
    begin
    
    in0_tb = 0;
    in1_tb = 0;
    in2_tb = 0;
    in3_tb = 0;
    sel_tb = 0;
    data_tb = 0;
    out0_tb = 0;
    out1_tb = 0;
    out2_tb = 0;
    out3_tb = 0;
    
    #10
    
    sel_tb = 1;
    data_tb = 1;
    
    #10
    
    in0_tb = 1;
    in1_tb = 1;
    in2_tb = 1;
    in3_tb = 1;
    sel_tb = 2;
    data_tb =2;
    out0_tb =1;
    out1_tb =1;
    out2_tb =1;
    out3_tb =1;
    
    #5
    
    sel_tb = 3;
    data_tb = 3;
    
    #5
    
    sel_tb = 2;
    data_tb = 4;
    
    #5
    
    sel_tb = 0;
    data_tb = 5;
    
    #5
    
    in0_tb = 0;
    in2_tb = 0;
    in3_tb = 0;
    data_tb = 6;
    
    #5
    
    data_tb = 7;
    
    #5
    
    data_tb = 0;
    in0_tb = 1;
    in3_tb = 1;
    
    #40
    
    $stop();
    end
    
    
endmodule
