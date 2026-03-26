`timescale 1ns / 1ps

module tb();

logic a_tb;
logic b_tb;
logic c_tb;
logic d_tb;
logic [1:0] sel_tb;
logic e_tb;


top dut(

    .in0(a_tb),
    .in1(b_tb),
    .in2(c_tb),
    .in3(d_tb),
    .sel(sel_tb), 
    .out0(e_tb)
    
    );
    
    initial
    begin
    
    c_tb = 1;
    
    forever #20 c_tb = ~c_tb;
    
    end
    
    initial
    begin
    
    sel_tb = 0;
    a_tb = 1;
    b_tb = 0;
    d_tb = 0;
    
    #40
    
    sel_tb = 1;
    
    #40
    
    sel_tb = 2;
    
    #40
    
    sel_tb = 3;
    
    #20
    
    d_tb = 1;
    
    #10
    
    d_tb =0;
    
    #10
    
    sel_tb = 0;
    
    #40
    
    $stop();
    end
    
endmodule
