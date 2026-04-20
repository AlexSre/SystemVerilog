module demux4(

input logic [1:0] sel,
input logic [7:0] in0,
output logic [7:0] out0,
output logic [7:0] out1,
output logic [7:0] out2,
output logic [7:0] out3


);

always_comb
begin
if(sel==2'b00)
begin
 out0 = in0;
 out1 = 0;
 out2 = 0;
 out3 = 0;
end else 
    begin
        if(sel==2'b01)
        begin
         out0 = 0;
         out1 = in0;
         out2 = 0;
         out3 = 0;
        end else
        if (sel==2'b10)
        begin
         out0 = 0;
         out1 = 0;
         out2 = in0;
         out3 = 0;
        end 
        else
        if (sel==2'b11)
        begin
         out0 = 0;
         out1 = 0;
         out2 = 0;
         out3 = in0;
        end 
    end


end


endmodule