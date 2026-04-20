module special(


input logic [7:0] in0,
input logic [7:0] in1,
output logic  [7:0]sel
    );
    
    assign sel = (in0[0]==in1[0] & 
    in0[7] == in1[7] & 
    in0[0] == in1[7]) ? 1 : 0;
    
    endmodule