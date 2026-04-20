module shift_left#(

    parameter size = 8

)
(

input logic [size-1:0] in0,
input logic [size-1:0] in1,
output logic [size-1:0] out0
);

assign out0 = in0 << in1;



endmodule