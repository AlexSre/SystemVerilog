module comp_eq(


input logic [7:0] in0,
input logic [7:0] in1,
output logic out0
    );
    
    
    assign out0 = (in0 == in1) ? 1 : 0;
    
    
    endmodule