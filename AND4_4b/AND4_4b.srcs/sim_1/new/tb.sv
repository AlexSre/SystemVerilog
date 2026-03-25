
module tb();

    logic [3:0] a_tb;
    logic [3:0] b_tb;
    logic [3:0] c_tb;
    logic [3:0] d_tb;
    logic [3:0] e_tb;
     
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
    b_tb = 0;
    c_tb = 15;
    d_tb = 7;
    
    #5
    
    d_tb = 4;
    b_tb = 3;
    
    #5
    
    a_tb = 1;
    
    #5
    
    d_tb = 9;
    
    #5
    
    a_tb = 2;
    
    #5 
    
    d_tb = 6;
    
    #5
    
    a_tb = 3;
    b_tb = 15;
    
    #5
    
    d_tb = 0;
    
    #15
    
    a_tb = 15;
    
    #20
    
    $stop();
    end
    
endmodule
