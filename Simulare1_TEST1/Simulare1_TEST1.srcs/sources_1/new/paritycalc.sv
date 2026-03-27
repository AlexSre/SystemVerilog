module paritycalc(

    input logic[3:0] in,
    output logic out

    );
    
    logic [4:0] w0;
    assign w0 = in[0] + in[1] + in[2] + in[3];
    assign out0 = w0[0];
    
endmodule
