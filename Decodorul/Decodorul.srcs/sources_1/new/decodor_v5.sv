module decodor_v5
	(
		input logic [1:0] in,
		output logic [3:0] out 
	);

always_comb
begin
	case(in) 
		0: out = 1;
		2'd1: out = 2;
		2'b10: out = 4;
		2'h3: out = 8;
		default: out = 0;
	endcase 
end 

endmodule