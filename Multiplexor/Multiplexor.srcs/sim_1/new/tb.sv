`timescale 1ns / 1ps


module tb();

    logic a_tb;
    logic b_tb;
    logic c_tb;
    logic d_tb;

top dut(

    .in0(a_tb),
    .in1(b_tb),
    .sel(c_tb),
    .out0(d_tb)

    );
    
    initial
    begin
    
    c_tb = 0;
    b_tb = 0;
    
    #30
    
    b_tb = 1;
    
    #10 
    
    b_tb = 0;
    
    #10 
    
    b_tb = 1;
    
    #30
    
    c_tb = 1;
    
    #30
    
    b_tb = 0;
    
    #20
    
    b_tb = 1;
    
    #20
    
    $stop();
    end
    
    initial 
    begin
    a_tb = 0;
    forever #10 a_tb = ~a_tb; 
    
    end
    
endmodule
