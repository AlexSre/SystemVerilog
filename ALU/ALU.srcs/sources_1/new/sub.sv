module sub #(
    parameter data_size = 4
)
(

    input logic [data_size-1:0] in0,
    input logic [data_size-1:0] in1,
    output logic [data_size-1:0] out0
    );
    
    assign out0 = in0 -in1;
    
endmodule
