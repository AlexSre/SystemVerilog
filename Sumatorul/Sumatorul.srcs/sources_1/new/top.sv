module top(
    
    input logic [7:0] in0,
    input logic [7:0] in1,
    input carry_in,
    output carry_out,
    output logic [7:0] out0

    );
    
    logic [8:0] w0;
    assign w0 = in0 + in1 + carry_in;
    assign carry_out = w0[8];
    assign out0 = w0[7:0];
    
endmodule
