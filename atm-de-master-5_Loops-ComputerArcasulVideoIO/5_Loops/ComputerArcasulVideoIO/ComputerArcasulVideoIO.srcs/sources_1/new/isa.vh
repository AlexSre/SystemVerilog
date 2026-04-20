
/**
 * ARCHITECTURE OVERVIEW:
 * 17-bit Address Bus (128KB addressable space)
 * 26-bit Instruction Width
 * 32x 32-bit General Purpose Registers
 * Memory Mapped I/O for Buttons, VSync, Random and Score
 *
 * INSTRUCTION FORMAT (ASCII ART):
 * * 25      22 21      17 16      12 11       7 6       0
 * +----------+----------+----------+----------+---------+
 * |  OPCODE  |  RDEST   |  RLEFT   |  RRIGHT  | UNUSED  |  <- Type R (Arithmetic/Logic)
 * +----------+----------+----------+----------+---------+
 * |  OPCODE  |  RDEST   |       IMMEDIATE (17 bit)      |  <- Type I (LoadC)
 * |  OPCODE  |  RDEST   |  RLEFT   |       UNUSED       |  <- Type I (Load: RDEST=MEM[RLEFT] )
 * |  OPCODE  |  RSRC    |  RLEFT   |       UNUSED       |  <- Type I (Store: MEM[RLEFT]=RSRC )
 * |  OPCODE  |  COND    |   ABSOLUTE ADDRESS(17 bit)    |  <- Type I (Jump)
 * +----------+----------+----------+----------+---------+
        
 */

// --- OPCODES ---
`define ADD   4'b0000
`define SUB   4'b0001
`define AND   4'b0010
`define OR    4'b0011
`define XOR   4'b0100
`define MUL   4'b0101

`define LOADC 4'b0110
`define LOAD  4'b0111
`define STORE 4'b1000
`define JUMP  4'b1001

`define JZ    4'b1010

`define NOP   4'b1111

// --- REGISTERS ---
// =========================================================
// DEFINIRE REGISTRE FIZICE (R0-R31)
// =========================================================
`define R0  5'd0  
`define R1  5'd1  
`define R2  5'd2
`define R3  5'd3
`define R4  5'd4
`define R5  5'd5
`define R6  5'd6
`define R7  5'd7
`define R8  5'd8
`define R9  5'd9
`define R10 5'd10
`define R11 5'd11
`define R12 5'd12
`define R13 5'd13
`define R14 5'd14
`define R15 5'd15
`define R16 5'd16
`define R17 5'd17
`define R18 5'd18
`define R19 5'd19
`define R20 5'd20
`define R21 5'd21
`define R22 5'd22
`define R23 5'd23
`define R24 5'd24
`define R25 5'd25
`define R26 5'd26
`define R27 5'd27
`define R28 5'd28
`define R29 5'd29
`define R30 5'd30 
`define R31 5'd31

`define DUMMY5b 5'd0
`define DUMMY7b 7'd0
`define DUMMY12b 12'd0
