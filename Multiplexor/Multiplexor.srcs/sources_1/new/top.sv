
module top(

    input in0,
    input in1,
    input sel,
    output out0

    );
    
    logic w0;
    logic w1;
    
   assign w0 = ~sel & in0;
   assign w1 = sel & in1;
   assign out0 = w0 | w1;
     
    
endmodule
