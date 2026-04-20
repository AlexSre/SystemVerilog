module top(

input logic [7:0] data0,
input logic [7:0] data1,
input logic [15:0] instruction,
output logic zero_flag,
output logic [7:0] out0,
output logic [7:0] out1,
output logic [7:0] out2,
output logic [7:0] out3,
output logic overflow_flag

    );
    
    logic [7:0] fir_xor;
    logic[7:0] fir_and;
    logic [7:0] fir_or;
    logic [7:0] fir_shiftr;
    logic [7:0] fir_shiftl;
    logic [7:0] fir_add;
    logic [7:0] fir_sub;
    logic [7:0] fir_outmux0;
    logic [7:0] fir_outmux1;
    logic [7:0] fir_special;
    logic [7:0] w1;
    logic [7:0] w0;
    logic [7:0] w2;
    logic [7:0] fir_outmux2;
    logic fir_1b;
    logic [8:0] fir;
    
    assign fir = {fir_1b,fir_add};
    
    assign w1 = 1;
    assign w0 = 0;
    assign w2 = 0;
    
    assign fir_xor[7:0] = data0[7:0]^data1[7:0]; 
    and and0[7:0] (fir_xor[7:0], data0[7:0] ,data1[7:0]);
    or fir_or0[7:0](fir_or[7:0], data0[7:0], data1[7:0]);
    
   shift_right  #(
        .size(8)
   )
   
   
   shift_right0(

.in0(data0),
.in1(data1),
.out0(fir_shiftr)
);


   shift_left    
   shift_left0(

.in0(data0),
.in1(data1),
.out0(fir_shiftl)
);


 add add0(


.in0(data0),
.in1(data1),
.out0(fir)
    );

 sub sub0(


  .in0(data0),
  .in1(data1),
  .out0(fir_sub)
    );
 mux4 mux4_0(

.sel(instruction[11:10]),
.in0(fir_shiftr),
.in1(fir_shiftl),
.in2(fir),
.in3(fir_sub),
.out0(fir_outmux0)

);

 mux4 mux4_1(

.sel(instruction[11:10]),
.in0(fir_and),
.in1(fir_or),
.in2(fir_xor),
.in3(w1),
.out0(fir_outmux1)

);


special special0(

.in0(data0),
.in1(data1),
.sel(fir_special)

    );
    
 mux4 mux4_2(

.sel(instruction[13:12]),
.in0(fir_outmux0),
.in1(fir_outmux1),
.in2(w0),
.in3(fir_special),
.out0(fir_outmux2)

);

demux4 demux4_0(

.sel(instruction[15:14]),
.in0(fir_outmux2),
.out0(out0),
.out1(out1),
.out2(out2),
.out3(out3)


);

comp_eq comp(


.in0(fir_outmux2),
.in1(w2),
.out0(zero_flag)
    );

assign overflow_flag = fir_1b;


endmodule
