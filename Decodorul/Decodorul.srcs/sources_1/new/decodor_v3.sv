module decodor_v3
	(
		input logic [1:0] in,
		output logic [3:0] out 
	);


assign out = (in==0) ? 
				1 : 
				(in==1) ? 
					2 : (in==2) ? 4 : 8; 

endmodule