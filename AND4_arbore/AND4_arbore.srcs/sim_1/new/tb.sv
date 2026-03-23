`timescale 1ns / 1ps
module tb();
    
    logic a_tb, b_tb, c_tb, d_tb, e_tb;
    
    top dut(
        
        .in0(a_tb),
        .in1(b_tb),
        .in2(c_tb),
        .in3(d_tb),
        .out0(e_tb)
        
    );
    
    initial
    begin
    
    a_tb = 0;
    b_tb = 1;
    c_tb = 0;
    d_tb = 0;
    
    #40
    
    a_tb = 1;
    c_tb = 1;
    
    #15
    
    a_tb = 0;
    c_tb = 0;
    
    #15 
    
    c_tb = 1;
    
    #10
    
    $stop();
    end
    
    initial
    begin
    forever #5 d_tb= ~d_tb;
    end
    
endmodule
