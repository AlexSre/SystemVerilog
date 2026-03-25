module decodor_v4
	(
		input logic [1:0] in,
		output logic [3:0] out
	);						 

always_comb 
begin	
	if(in == 0)
		begin 
		out = 1; 
		end
	else
		begin
		if(in == 1)
			out = 2;	
		else
			begin	
			if(in == 2)
				begin
				out = 4;
				end
			else
				begin
				out = 8;
				end
			end
		end
end

endmodule