module decodor1_v1
	(
		input logic [1:0] in,	
		output logic [3:0] out 	
	);
	
logic in_0_inv;
logic in_1_inv;
logic in_0_nat;
logic in_1_nat;

not not_gate_0(in_0_inv,in[0]);

not not_gate_1(in_1_inv,in[1]); 

not not_gate_2(in_0_nat,in_0_inv);

not not_gate_3(in_1_nat,in_1_inv);

and and_gate_0(out[0],in_1_inv,in_0_inv);

and and_gate_1(out[1],in_1_inv,in_0_nat);

and and_gate_2(out[2],in_1_nat,in_0_inv);

and and_gate_3(out[3],in_1_nat,in_0_nat);
	
endmodule