module rom(
    input logic [1:0] instr_addr,
    output logic [7:0] instr
);

always_comb 
begin
    case (instr_addr)
        0: instr = 8'b00_00_0000; 
        1: instr = 8'b01_00_0000; 
        2: instr = 8'b10_00_0010; 
        3: instr = 8'b11_00_1110; 
        default: instr = 8'b00_00_0000;
    endcase
end

endmodule