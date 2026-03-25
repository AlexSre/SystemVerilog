module top
	(
		input logic [1:0] in,
		output logic [3:0] out_v1, 
		output logic [3:0] out_v2, 
		output logic [3:0] out_v3,
		output logic [3:0] out_v4,
		output logic [3:0] out_v5,
		output logic [3:0] out_v6
	);
	
decodor1_v1 decodor_v1_0
	(
		.in(in),
		.out(out_v1)
	);

decodor_v2 decodor_v2_0
	(
		.in(in),
		.out(out_v2)
	);
	
decodor_v3 decodor_v3_0
	(
		.in(in),
		.out(out_v3)
	);
	
decodor_v4 decodor_v4_0
	(
		.in(in),
		.out(out_v4)
	);
	
decodor_v5 decodor_v5_0
	(
		.in(in),
		.out(out_v5)
	);

decodor_v6 decodor_v6_0
	(
		.in(in),
		.out(out_v6)
	);
	
endmodule