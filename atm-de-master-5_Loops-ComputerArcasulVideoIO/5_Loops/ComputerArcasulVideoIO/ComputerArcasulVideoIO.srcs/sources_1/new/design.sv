`timescale 1ns / 1ps
`include "isa.vh"
`include "config.vh"

// --- I/O MAPPING ---
`define IO_BTNS   17'h1FFFF
`define IO_VSYNC  17'h1FFFE
`define IO_SCORE  17'h1FFFD
`define IO_RAND   17'h1FFFC

// =========================================================
// TOP MODULE
// =========================================================
module Top_Game_NexysA7(
    input  logic CLK100MHZ,     // Pin E3
    input  logic CPU_RESETN,    // Pin C12
    input  logic BTNU, BTND, BTNC, 
    output logic [7:0] SEG, AN,      
    output logic [3:0] VGA_R, VGA_G, VGA_B, 
    output logic VGA_HS, VGA_VS  
);

    // --- 1. GENERARE CEAS PIXEL (25 MHz din 100 MHz) ---
    wire clk_vga;
    wire clk_vga_mmcm;
    wire clkfb;
    wire clkfb_buf;
    wire clk_locked;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(10.0),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(10.0),
        .CLKOUT0_DIVIDE_F(40.0),
        .CLKOUT0_PHASE(0.0),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT1_DIVIDE(1),
        .CLKOUT2_DIVIDE(1),
        .CLKOUT3_DIVIDE(1)
    ) pixel_clk_mmcm (
        .CLKIN1(CLK100MHZ),
        .RST(!CPU_RESETN),
        .PWRDWN(1'b0),
        .CLKFBIN(clkfb_buf),
        .CLKFBOUT(clkfb),
        .CLKOUT0(clk_vga_mmcm),
        .CLKOUT1(),
        .CLKOUT2(),
        .CLKOUT3(),
        .LOCKED(clk_locked)
    );

    BUFG clkfb_bufg (
        .I(clkfb),
        .O(clkfb_buf)
    );

    BUFG clk_vga_bufg (
        .I(clk_vga_mmcm),
        .O(clk_vga)
    );
    
    logic [1:0] btnu_ff = 2'b0;
    logic [1:0] btnd_ff = 2'b0;
    logic [1:0] btnc_ff = 2'b0;

    always_ff @(posedge clk_vga) begin
        if (!CPU_RESETN || !clk_locked) begin
            btnu_ff <= 2'b0;
            btnd_ff <= 2'b0;
            btnc_ff <= 2'b0;
        end else begin
            btnu_ff <= {btnu_ff[0], BTNU};
            btnd_ff <= {btnd_ff[0], BTND};
            btnc_ff <= {btnc_ff[0], BTNC};
        end
    end
    
    logic [16:0] pc_out;
    logic [25:0] instruction;
    logic [16:0] cpu_addr;
    logic [31:0] cpu_data_to_ram, cpu_data_from_bus;
    logic ram_we, zero_flag;
    
    logic [15:0] score_reg = 16'd0;
    logic [15:0] logo_reg = 16'hC112;
    logic [16:0] lfsr_reg = 17'h1ACE1;
    
    // Random Number Generator (LFSR)
    always_ff @(posedge clk_vga)
        lfsr_reg <= {lfsr_reg[15:0], lfsr_reg[16] ^ lfsr_reg[13]};

    // Subsystems
    PMEM_26bit pmem_inst(.addr(pc_out), .instr(instruction));

    CPU_17bit core(
        .clk(clk_vga), .rst(!CPU_RESETN || !clk_locked || !vram_init_done),
        .instr(instruction), .pc(pc_out),
        .addr_bus(cpu_addr), .data_in(cpu_data_from_bus), .data_out(cpu_data_to_ram),
        .we(ram_we), .z_flag(zero_flag)
    );

    // Memory Mapped I/O Logic
    always_comb begin
        case(cpu_addr)
            `IO_BTNS:  cpu_data_from_bus = {29'b0, btnc_ff[1], btnd_ff[1], btnu_ff[1]}; 
            `IO_VSYNC: cpu_data_from_bus = {31'b0, VGA_VS};           
            `IO_RAND:  cpu_data_from_bus = lfsr_reg[15:0];           
            default:   cpu_data_from_bus = 32'b0;
        endcase
    end

    // Score Register Update
    always_ff @(posedge clk_vga) begin
        if (ram_we && cpu_addr == `IO_SCORE) score_reg <= cpu_data_to_ram;
    end 
    
    // --- GRAPHICS SUBSYSTEM ---
    logic [1:0] vram_pixel;
    logic [1:0] vram_write_data;
    logic [16:0] vga_addr_vram;
    logic [16:0] vram_write_addr;
    logic [16:0] vram_init_addr = 17'd0;
    logic [10:0] vga_x, vga_y;
    logic video_on;
    logic vram_write_en;
    logic vram_init_done = 1'b0;

    always_ff @(posedge clk_vga) begin
        if (!CPU_RESETN || !clk_locked) begin
            vram_init_done <= 1'b0;
            vram_init_addr <= 17'd0;
        end else if (!vram_init_done) begin
            if (vram_init_addr == 17'd76799)
                vram_init_done <= 1'b1;
            else
                vram_init_addr <= vram_init_addr + 17'd1;
        end
    end

    assign vram_write_en   = !vram_init_done || (ram_we && (cpu_addr < 76800));
    assign vram_write_addr = !vram_init_done ? vram_init_addr : cpu_addr;
    assign vram_write_data = !vram_init_done ? 2'b00 : cpu_data_to_ram[1:0];

    VRAM_DualPort vram(
        .clk(clk_vga),
        .we_cpu(vram_write_en),
        .addr_cpu(vram_write_addr), .din_cpu(vram_write_data),
        .addr_vga(vga_addr_vram), .dout_vga(vram_pixel)
    );

    vga_sync_1440x900 vga_ctrl(
        .clk(clk_vga), .rst(!CPU_RESETN || !clk_locked), 
        .hsync(VGA_HS), .vsync(VGA_VS),
        .video_on(video_on), .x(vga_x), .y(vga_y)
    );

    assign vga_addr_vram = ((vga_y >> 1) * 320) + (vga_x >> 1);

    always_comb begin
        if (!video_on) {VGA_R, VGA_G, VGA_B} = `COLOR_BLACK;
        else if (!vram_init_done) {VGA_R, VGA_G, VGA_B} = `COLOR_WHITE;
        else case(vram_pixel)
            2'b01: {VGA_R, VGA_G, VGA_B} = `COLOR_BLUE; // Blue (Archer)
            2'b10: {VGA_R, VGA_G, VGA_B} = `COLOR_RED; // Red (Balloon)
            2'b11: {VGA_R, VGA_G, VGA_B} = `COLOR_BLACK; // Black (Arrow)
            default: {VGA_R, VGA_G, VGA_B} = `COLOR_WHITE; // White (Background)
        endcase
    end

    SevenSeg_Driver display(.clock(clk_vga), .data({logo_reg, score_reg}), .seg(SEG), .an(AN));
endmodule

// =========================================================
// CPU CORE
// =========================================================
module CPU_17bit(
    input logic clk, rst, [25:0] instr,
    output logic [16:0] pc, output logic [16:0] addr_bus,
    input logic [31:0] data_in, output logic [31:0] data_out,
    output logic we, z_flag
);
    logic [31:0] regs [0:31];
    logic [31:0] alu_out;
    
    // Decoding fields
    logic [3:0]  opcode;
    logic [4:0]  rdest; 
    logic [4:0]  rleft;
    logic [4:0]  rright;
    logic [16:0] imm;

    assign opcode = instr[25:22];
    assign rdest  = instr[21:17];
    assign rleft  = instr[16:12]; 
    assign rright = instr[11:7];
    assign imm    = instr[16:0];
    
    assign z_flag = (alu_out == 0);
    
    
    // PC Logic
    // JZ is encoded as "jump if register is zero", which matches the game program.
    always_ff @(posedge clk) begin
        if (rst) pc <= 0;
        else if (opcode == `JUMP) pc <= imm;
        else if (opcode == `JZ && regs[rdest] == 0) pc <= imm;
        else pc <= pc + 1;
    end

    // Bus Logic
    assign addr_bus = (opcode == `LOAD || opcode == `STORE) ? regs[rleft] : imm;
    assign data_out = regs[rdest];
    assign we = (opcode == `STORE);

    // ALU Logic
    always_ff @(posedge clk) begin
        $display("R[0]=%d, R[1]=%d, R[2]=%d, R[3]=%d, R[4]=%d, R[5]=%d, R[6]=%d, R[7]=%d, addr_bus=%h, data_out=%h\n", 
            regs[0], regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7], addr_bus, data_out);
    
        case(opcode)
            `ADD:   begin 
                        $display("R[%d] = R[%d] + R[%d]", rdest, rleft, rright);
                        alu_out = regs[rleft] + regs[rright];                        
                    end
            `SUB:   begin 
                        alu_out = regs[rleft] - regs[rright];
                        $display("R[%d] = R[%d] - R[%d]", rdest, rleft, rright);
                    end
            `AND:   begin 
                        alu_out = regs[rleft] & regs[rright];
                        $display("R[%d] = R[%d] & R[%d]", rdest, rleft, rright);
                    end
            `OR:    begin 
                        alu_out = regs[rleft] | regs[rright];
                        $display("R[%d] = R[%d] | R[%d]", rdest, rleft, rright);
                    end
            `XOR:   begin
                        alu_out = regs[rleft] ^ regs[rright];
                        $display("R[%d] = R[%d] ^ R[%d]", rdest, rleft, rright);
                    end
            `MUL:   begin 
                        alu_out = regs[rleft] * regs[rright];
                        $display("R[%d] = R[%d] * R[%d] = %d", rdest, rleft, rright, alu_out);
                    end                    
            `LOADC: begin 
                        alu_out = imm;
                        $display("R[%d] = %d", rdest, imm);
                    end
            `LOAD:  begin 
                        alu_out = data_in;
                        $display("R[%d] = MEM[R[%d]] = MEM[%d] = %d", rdest, rleft, regs[rleft], data_in);
                    end
            `STORE:  begin 
                        $display("MEM[R[%d]] = R[%d] : MEM[%d]=%d", rleft, rdest, regs[rleft], regs[rdest]);
                    end
            `NOP: begin
                  end        
            default:alu_out = 0;
        endcase
        if (opcode < `STORE) regs[rdest] <= alu_out;
    end
endmodule
/*
module PMEM_26bit (input logic [16:0] addr, output logic [25:0] instr);
    always_comb begin
        case(addr)
            // --- INITIALIZARE ---
            0: instr = {`LOADC, `R0,   17'd0};      // R0 = Pointer VRAM (pixelul curent)
            1: instr = {`LOADC, `R1,   17'd1};      // R1 = Increment constant
            2: instr = {`LOADC, `R2,   17'd2};      // R2 = Culoare ROSU
            3: instr = {`LOADC, `R10,  17'd81000};  // R10 = Limita ecranului
            4: instr = {`LOADC, `R4,   `IO_SCORE};  // R4 = 17'h1FFFD

            // --- BUCLA DE UMPLERE ---
            5: instr = {`STORE, `R2,   `R0, 12'd0}; 
            6: instr = {`LOADC, `R5,   `IO_BTNS};
            7: instr = {`LOAD, `R6,   `R5, 12'd0}; // read buttons into R6 from address stored into R5 

            // 6. Pauză (pentru a vedea progresul pe afișaj)
            8: instr = {`NOP,  22'd0};

            // 10. Increment adresa pixel: R0 = R0 + 1
            9: instr = {`ADD,   `R0,   `R0, `R1, 7'd0}; 

            // TRIMITE LA AFIȘAJ: IO_SCORE[R4] = R0 (Adresa pixelului curent)
            // Acum R4 conține 17'h1FFFD, deci scrierea se duce la I/O
            10: instr = {`STORE, `R6,   `R4, 12'd0}; 
            11: instr = {`NOP,  22'd0};

            // 12. Verifică limita
            12: instr = {`SUB,   `R3,   `R0, `R10, 7'd0};
            13: instr = {`JZ,    `R3,   17'd15};     // Dacă e gata, sari la HALT
            14: instr = {`JUMP,  `RZERO, 17'd5};      // Salt înapoi la STORE pixel

            // --- FINAL ---
            15: instr = {`JUMP,  `RZERO, 17'd15};    

            default: instr = {`JUMP, `RZERO, 17'd15};
        endcase
    end
endmodule
*/

/*
module PMEM_26bit (input logic [16:0] addr, output logic [25:0] instr);
    always_comb begin
        case(addr)
            // --- INITIALIZARE ---
            0: instr = {`LOADC, `R1,   17'd1};      // Constantă 1
            1: instr = {`LOADC, `R4,   `IO_SCORE};  // Adresa afișaj (17'h1FFFD)
            2: instr = {`LOADC, `R5,   `IO_BTNS};   // Adresa butoane (17'h1FFFF)

            // --- BUCLA INFINITĂ DE CITIRE ---
            // 3. Citește starea butoanelor în R6
            3: instr = {`LOAD,  `R6,   `R5, 12'd0}; 

            // 4. Trimite starea citită (R6) la afișajul cu 7 segmente
            4: instr = {`STORE, `R6,   `R4, 12'd0}; 

            // 5. NOP pentru stabilitatea magistralei
            5: instr = {`NOP,   22'd0};

            // 6. Sari înapoi la pasul 3 pentru a citi din nou
            6: instr = {`JUMP,  `RZERO, 17'd3};

            default: instr = {`JUMP, `RZERO, 17'd3};
        endcase
    end
endmodule*/

/*
module PMEM_26bit (input logic [16:0] addr, output logic [25:0] instr);
    always_comb begin
        case(addr)
            // --- 1. INITIALIZARE ---
            0:  instr = {`LOADC, `R10,  17'd10};      // X = 10
            1:  instr = {`LOADC, `R11,  17'd100};     // Y = 100
            2:  instr = {`LOADC, `R21,  17'd360};     // Latime
            3:  instr = {`LOADC, `R1,   17'd1};       // Constant 1
            4:  instr = {`LOADC, `R4,   `IO_SCORE};   // Port 7-Seg

            // --- 2. CITIRE BUTOANE ---
            5:  instr = {`LOADC, `R5,   `IO_BTNS};
            6:  instr = {`LOAD,  `R6,   `R5, 12'd0};  
            7:  instr = {`NOP,   22'd0};

            // --- 3. TEST AFISARE (Debug) ---
            // Trimitem butoanele pe afisaj. 
            // Daca apesi UP, trebuie sa vezi 1. Daca apesi DOWN, trebuie sa vezi 2.
            8:  instr = {`STORE, `R6,   `R4, 12'd0};  
            9:  instr = {`NOP,   22'd0};

            // --- 4. LOGICA SIMPLIFICATA (FARA STERGERE MOMENTAN) ---
            // Testam DOAR daca Y se modifica corect
            10: instr = {`AND,   `R7,   `R6, `R1, 7'd0}; // Izolam Bit 0 (UP)
            11: instr = {`JZ,    `R7,   17'd14};         // Daca nu e UP, sari la 14
            12: instr = {`SUB,   `R11,  `R11, `R1, 7'd0}; // Y = Y - 1
            13: instr = {`JUMP,  `RZERO, 17'd18};        // Sari la desenare

            14: instr = {`LOADC, `R8,   17'd2};          // Izolam Bit 1 (DOWN)
            15: instr = {`AND,   `R7,   `R6, `R8, 7'd0}; 
            16: instr = {`JZ,    `R7,   17'd18};         // Daca nu e DOWN, sari la 18
            17: instr = {`ADD,   `R11,  `R11, `R1, 7'd0}; // Y = Y + 1

            // --- 5. DESENARE PUNCT (Un singur pixel, nu dreptunghi) ---
            18: instr = {`MUL,   `R12,  `R11, `R21, 7'd0}; 
            19: instr = {`ADD,   `R12,  `R12, `R10, 7'd0}; 
            20: instr = {`LOADC, `R2,   17'd1};           // Albastru
            21: instr = {`STORE, `R2,   `R12, 12'd0};     // Deseneaza 1 pixel
            22: instr = {`NOP,   22'd0};

            // --- 6. DELAY ---
            23: instr = {`LOADC, `R23,  17'd100000}; 
            24: instr = {`SUB,   `R23,  `R23, `R1, 7'd0}; 
            25: instr = {`JZ,    `R23,  17'd5}; 
            26: instr = {`JUMP,  `RZERO, 17'd24};

            default: instr = {`JUMP, `RZERO, 17'd5};
        endcase
    end
endmodule
*/
/*
module PMEM_26bit (input logic [16:0] addr, output logic [25:0] instr);
    always_comb begin
        case(addr)
            // --- 1. INITIALIZARE (0-9) ---
            0:  instr = {`LOADC, `R10,  17'd10};      // X Archer
            1:  instr = {`LOADC, `R11,  17'd100};     // Y Archer
            2:  instr = {`LOADC, `R21,  17'd360};     // Latime ecran
            3:  instr = {`LOADC, `R1,   17'd1};       // Constant 1
            4:  instr = {`LOADC, `R16,  17'd0};       // X_Arrow (0=inactiva)
            5:  instr = {`LOADC, `R18,  17'd200};     // X_Balloon
            6:  instr = {`LOADC, `R19,  17'd0};       // Y_Balloon
            7:  instr = {`LOADC, `R20,  17'd0};       // Scor
            8:  instr = {`LOADC, `R4,   `IO_SCORE};   // Port Scor
            9:  instr = {`LOADC, `R26,  `IO_RAND};    // Port LFSR

            // --- 2. LOOP START & INPUT (10-14) ---
            10: instr = {`LOADC, `R5,   `IO_BTNS};
            11: instr = {`LOAD,  `R6,   `R5, 12'd0};  
            12: instr = {`NOP,   22'd0};
            13: instr = {`STORE, `R20,  `R4, 12'd0};  // Update Scor
            14: instr = {`JZ,    `R6,   17'd10};      // Asteapta butoane

            // --- 3. STERGERE (15-32) ---
            15: instr = {`LOADC, `R2,   17'd0};       // Culoare fundal
            16: instr = {`MUL,   `R12,  `R11, `R21, 7'd0}; 
            17: instr = {`ADD,   `R12,  `R12, `R10, 7'd0}; 
            18: instr = {`LOADC, `R14,  17'd16};      // Inaltime arcas
            19: instr = {`LOADC, `R15,  17'd8};       // Latime arcas
            20: instr = {`STORE, `R2,   `R12, 12'd0}; 
            21: instr = {`ADD,   `R12,  `R12, `R1, 7'd0}; 
            22: instr = {`SUB,   `R15,  `R15, `R1, 7'd0};
            23: instr = {`JZ,    `R15,  17'd25};
            24: instr = {`JUMP,  `RZERO, 17'd20};
            25: instr = {`LOADC, `R24,  17'd352};     // Re-aliniere (360-8)
            26: instr = {`ADD,   `R12,  `R12, `R24, 7'd0}; 
            27: instr = {`SUB,   `R14,  `R14, `R1, 7'd0};
            28: instr = {`JZ,    `R14,  17'd30};
            29: instr = {`JUMP,  `RZERO, 17'd19};
            30: instr = {`MUL,   `R12,  `R19, `R21, 7'd0}; // Sterge Balon (colt)
            31: instr = {`ADD,   `R12,  `R12, `R18, 7'd0};
            32: instr = {`STORE, `R2,   `R12, 12'd0}; 

            // --- 4. LOGICA MISCARE SI COLIZIUNE (33-47) ---
            33: instr = {`ADD,   `R19,  `R19, `R1, 7'd0}; // Balonul cade
            34: instr = {`LOADC, `R9,   17'd220};
            35: instr = {`SUB,   `R3,   `R19, `R9, 7'd0};
            36: instr = {`JZ,    `R3,   17'd58};      // Respawn la pamant (58)
            37: instr = {`JZ,    `R16,  17'd48};      // Daca nu e sageata, sari la Archer
            38: instr = {`SUB,   `R3,   `R16, `R18, 7'd0}; // Distanta X
            39: instr = {`LOADC, `R25,  17'd12};      // Toleranta
            40: instr = {`SUB,   `R3,   `R3, `R25, 7'd0};
            41: instr = {`JZ,    `R3,   17'd43};      
            42: instr = {`JUMP,  `RZERO, 17'd48};
            43: instr = {`ADD,   `R20,  `R20, `R1, 7'd0}; // HIT: Scor++
            44: instr = {`JUMP,  `RZERO, 17'd58};     // Respawn (58)

            // --- 5. LOGICA ARCAS SI SAGEATA (45-57) ---
            45: instr = {`AND,   `R7,   `R6, `R1, 7'd0}; // UP
            46: instr = {`JZ,    `R7,   17'd49};
            47: instr = {`SUB,   `R11,  `R11, `R1, 7'd0};
            48: instr = {`JUMP,  `RZERO, 17'd52};
            49: instr = {`LOADC, `R8,   17'd2};          // DOWN
            50: instr = {`AND,   `R7,   `R6, `R8, 7'd0};
            51: instr = {`ADD,   `R11,  `R11, `R1, 7'd0};
            52: instr = {`LOADC, `R8,   17'd4};          // BTNC
            53: instr = {`AND,   `R7,   `R6, `R8, 7'd0};
            54: instr = {`JZ,    `R7,   17'd63};         // Sari la Randare
            55: instr = {`ADD,   `R16,  `R10, `RZERO, 7'd0}; // Launch X
            56: instr = {`ADD,   `R17,  `R11, `RZERO, 7'd0}; // Launch Y
            57: instr = {`JUMP,  `RZERO, 17'd63};

            // --- 6. RESPAWN (58-62) ---
            58: instr = {`LOAD,  `R18,  `R26, 12'd0};    // X nou
            59: instr = {`LOADC, `R27,  17'h00FF};       
            60: instr = {`AND,   `R18,  `R18, `R27, 7'd0}; 
            61: instr = {`LOADC, `R19,  17'd0};          // Y = 0
            62: instr = {`LOADC, `R16,  17'd0};          // Reset sageata

            // --- 7. RANDARE (63-83) ---
            63: instr = {`LOADC, `R2,   17'd2};          // Balon Rosu
            64: instr = {`MUL,   `R12,  `R19, `R21, 7'd0};
            65: instr = {`ADD,   `R12,  `R12, `R18, 7'd0};
            66: instr = {`LOADC, `R14,  17'd8};          // Balon H=8
            67: instr = {`STORE, `R2,   `R12, 12'd0}; 
            68: instr = {`ADD,   `R12,  `R12, `R21, 7'd0};
            69: instr = {`SUB,   `R14,  `R14, `R1, 7'd0};
            70: instr = {`JZ,    `R14,  17'd72};
            71: instr = {`JUMP,  `RZERO, 17'd67};
            72: instr = {`LOADC, `R2,   17'd1};          // Arcas Albastru
            73: instr = {`MUL,   `R12,  `R11, `R21, 7'd0};
            74: instr = {`ADD,   `R12,  `R12, `R10, 7'd0};
            75: instr = {`LOADC, `R14,  17'd16};         // Arcas H=16
            76: instr = {`STORE, `R2,   `R12, 12'd0}; 
            77: instr = {`ADD,   `R12,  `R12, `R21, 7'd0};
            78: instr = {`SUB,   `R14,  `R14, `R1, 7'd0};
            79: instr = {`JZ,    `R14,  17'd81};
            80: instr = {`JUMP,  `RZERO, 17'd76};
            81: instr = {`JZ,    `R16,  17'd86};         // Sageata?
            82: instr = {`ADD,   `R16,  `R16, `R1, 7'd0}; 
            83: instr = {`MUL,   `R12,  `R17, `R21, 7'd0};
            84: instr = {`ADD,   `R12,  `R12, `R16, 7'd0};
            85: instr = {`STORE, `R2,   17'd3, 12'd0};    // Pixel Negru

            // --- 8. DELAY & LOOP (86-89) ---
            86: instr = {`LOADC, `R23,  17'd85000};
            87: instr = {`SUB,   `R23,  `R23, `R1, 7'd0};
            88: instr = {`JZ,    `R23,  17'd10};         // Back to IDLE
            89: instr = {`JUMP,  `RZERO, 17'd87};

            default: instr = {`JUMP, `RZERO, 17'd10};
        endcase
    end
endmodule
*/

/*
module PMEM_26bit (input logic [16:0] addr, output logic [25:0] instr);
    always_comb begin
        case(addr)
            // --- 1. INITIALIZARE ---
            0:  instr = {`LOADC, `REG_ARCHER_X,      17'd10};     
            1:  instr = {`LOADC, `REG_ARCHER_Y,      17'd50};    
            2:  instr = {`LOADC, `REG_ARCHER_W,      17'd20};      // Lățime mică
            3:  instr = {`LOADC, `REG_ARCHER_H,      17'd20};     // Înălțime mare (Portrait)
            4:  instr = {`LOADC, `REG_ARCHER_COLOR,  17'd1};       // Albastru
            
            5:  instr = {`LOADC, `REG_CONST_1,       17'd1};      
            6:  instr = {`LOADC, `REG_SCR_WIDTH,     17'd360};     
            // IMPORTANT: Offset-ul trebuie să fie Lățime_Ecran - Lățime_Obiect
            // 360 - 20 = 340. Dacă acest număr e greșit, desenul se "înclină" sau se întinde.
            7:  instr = {`LOADC, `REG_OFFSET_LINE,   17'd340}; 

            8:  instr = {`LOADC, `REG_ADDR_BTNS,     17'h1FFFF}; 
            9:  instr = {`LOADC, `REG_ADDR_SCORE,    17'h1FFFD}; 

            // --- 2. CALCUL ADRESĂ START ---
            10: instr = {`MUL,   `REG_VRAM_PTR, `REG_ARCHER_Y, `REG_SCR_WIDTH, `DUMMY7b}; 
            11: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_ARCHER_X, `DUMMY7b}; 

            // --- 3. RUTINA DESENARE PORTRAIT ---
            12: instr = {`ADD,   `REG_CNT_H, `REG_ARCHER_H, `REG_RZERO, `DUMMY7b}; // Rămane 100

            // Bucla Verticală (Rânduri)
            13: instr = {`ADD,   `REG_CNT_W, `REG_ARCHER_W, `REG_RZERO, `DUMMY7b}; // Rămâne 20
            
            // Bucla Orizontală (Pixeli în rând)
            14: instr = {`STORE, `REG_ARCHER_COLOR, `REG_VRAM_PTR, `DUMMY12b}; 
            15: instr = {`NOP,   22'd0};                                
            16: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_CONST_1, `DUMMY7b}; 
            17: instr = {`SUB,   `REG_CNT_W, `REG_CNT_W, `REG_CONST_1, `DUMMY7b};    
            18: instr = {`JZ,    `REG_CNT_W, 17'd20};          // Dacă am terminat cei 20 de pixeli, sari la 20
            19: instr = {`JUMP,  `REG_RZERO, 17'd14};          // Altfel, continuă rândul

            // Salt la începutul rândului următor
            20: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_OFFSET_LINE, `DUMMY7b}; 
            21: instr = {`SUB,   `REG_CNT_H, `REG_CNT_H, `REG_CONST_1, `DUMMY7b};           
            22: instr = {`JZ,    `REG_CNT_H, 17'd24};          // Dacă am terminat cele 100 de rânduri, gata
            23: instr = {`JUMP,  `REG_RZERO, 17'd13};          // Altfel, reîncarcă W și fă rând nou

            // --- 4. DEBUG ȘI INPUT ---
            24: instr = {`LOAD,  `REG_BTN_VAL, `REG_ADDR_BTNS, 12'd0}; 
            25: instr = {`STORE, `REG_BTN_VAL, `REG_ADDR_SCORE, 12'd0}; 
            26: instr = {`JUMP,  `REG_RZERO, 17'd24}; // Buclă de monitorizare butoane

            default: instr = {`NOP, 22'd0};
        endcase
    end
endmodule
*/

module PMEM_26bit (input logic [16:0] addr, output logic [25:0] instr);
    always_comb begin
        case(addr)
            // --- INITIALIZARE ---
            0:   instr = {`LOADC, `REG_ARCHER_X,      17'd10};
            1:   instr = {`LOADC, `REG_ARCHER_Y,      17'd100};
            2:   instr = {`LOADC, `REG_ARCHER_W,      17'd20};
            3:   instr = {`LOADC, `REG_ARCHER_H,      17'd20};
            4:   instr = {`LOADC, `REG_ARCHER_COLOR,  17'd1};
            5:   instr = {`LOADC, `REG_CONST_1,       17'd1};
            6:   instr = {`LOADC, `REG_SCR_WIDTH,     17'd320};
            7:   instr = {`LOADC, `REG_OFFSET_LINE,   17'd300};
            8:   instr = {`LOADC, `REG_ADDR_BTNS,     `IO_BTNS};
            9:   instr = {`LOADC, `R23,               `IO_VSYNC};
            10:  instr = {`LOADC, `REG_ADDR_RAND,     `IO_RAND};
            11:  instr = {`LOADC, `REG_ADDR_SCORE,    `IO_SCORE};
            12:  instr = {`LOADC, `R28,               17'd0};
            13:  instr = {`LOADC, `REG_LIMIT_Y,       17'd220};
            14:  instr = {`LOADC, `R29,               17'd2};
            15:  instr = {`LOADC, `REG_SCORE_VAL,     17'd0};
            16:  instr = {`LOADC, `REG_ARROW_X,       17'd0};
            17:  instr = {`LOADC, `REG_ARROW_Y,       17'd0};
            18:  instr = {`LOADC, `REG_ARROW_W,       17'd4};
            19:  instr = {`LOADC, `REG_ARROW_COLOR,   17'd3};
            20:  instr = {`LOADC, `REG_BALLOON_X,     17'd200};
            21:  instr = {`LOADC, `REG_BALLOON_Y,     17'd80};
            22:  instr = {`LOADC, `REG_BALLOON_W,     17'd8};
            23:  instr = {`LOADC, `REG_BALLOON_COLOR, 17'd2};
            24:  instr = {`JUMP,  `REG_RZERO,         17'd150};

            // --- WAIT FOR NEXT FRAME ---
            30:  instr = {`LOAD,  `R30, `R23, `DUMMY12b};
            31:  instr = {`JZ,    `R30, 17'd30};
            32:  instr = {`LOAD,  `R30, `R23, `DUMMY12b};
            33:  instr = {`SUB,   `R30, `R30, `REG_CONST_1, `DUMMY7b};
            34:  instr = {`JZ,    `R30, 17'd32};

            // --- ERASE ARCHER ---
            35:  instr = {`MUL,   `REG_VRAM_PTR, `REG_ARCHER_Y, `REG_SCR_WIDTH, `DUMMY7b};
            36:  instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_ARCHER_X, `DUMMY7b};
            37:  instr = {`ADD,   `REG_CNT_H,    `REG_ARCHER_H, `R28,           `DUMMY7b};
            38:  instr = {`ADD,   `REG_CNT_W,    `REG_ARCHER_W, `R28,           `DUMMY7b};
            39:  instr = {`STORE, `R28,          `REG_VRAM_PTR, `DUMMY12b};
            40:  instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_CONST_1,   `DUMMY7b};
            41:  instr = {`SUB,   `REG_CNT_W,    `REG_CNT_W,    `REG_CONST_1,   `DUMMY7b};
            42:  instr = {`JZ,    `REG_CNT_W,    17'd44};
            43:  instr = {`JUMP,  `REG_RZERO,    17'd39};
            44:  instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_OFFSET_LINE, `DUMMY7b};
            45:  instr = {`SUB,   `REG_CNT_H,    `REG_CNT_H,    `REG_CONST_1,     `DUMMY7b};
            46:  instr = {`JZ,    `REG_CNT_H,    17'd48};
            47:  instr = {`JUMP,  `REG_RZERO,    17'd38};

            // --- ERASE ARROW ---
            48:  instr = {`JZ,    `REG_ARROW_X,  17'd57};
            49:  instr = {`MUL,   `REG_VRAM_PTR, `REG_ARROW_Y, `REG_SCR_WIDTH, `DUMMY7b};
            50:  instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_ARROW_X, `DUMMY7b};
            51:  instr = {`ADD,   `REG_CNT_W,    `REG_ARROW_W, `R28,          `DUMMY7b};
            52:  instr = {`STORE, `R28,          `REG_VRAM_PTR, `DUMMY12b};
            53:  instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_CONST_1,  `DUMMY7b};
            54:  instr = {`SUB,   `REG_CNT_W,    `REG_CNT_W,    `REG_CONST_1,  `DUMMY7b};
            55:  instr = {`JZ,    `REG_CNT_W,    17'd57};
            56:  instr = {`JUMP,  `REG_RZERO,    17'd52};

            // --- ERASE TARGET ---
            57:  instr = {`JZ,    `REG_BALLOON_X, 17'd72};
            58:  instr = {`MUL,   `REG_VRAM_PTR, `REG_BALLOON_Y, `REG_SCR_WIDTH, `DUMMY7b};
            59:  instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_BALLOON_X, `DUMMY7b};
            60:  instr = {`ADD,   `REG_CNT_H,    `REG_BALLOON_W, `R28,           `DUMMY7b};
            61:  instr = {`ADD,   `REG_CNT_W,    `REG_BALLOON_W, `R28,           `DUMMY7b};
            62:  instr = {`STORE, `R28,          `REG_VRAM_PTR, `DUMMY12b};
            63:  instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_CONST_1,   `DUMMY7b};
            64:  instr = {`SUB,   `REG_CNT_W,    `REG_CNT_W,    `REG_CONST_1,   `DUMMY7b};
            65:  instr = {`JZ,    `REG_CNT_W,    17'd67};
            66:  instr = {`JUMP,  `REG_RZERO,    17'd62};
            67:  instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_SCR_WIDTH, `DUMMY7b};
            68:  instr = {`SUB,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_BALLOON_W, `DUMMY7b};
            69:  instr = {`SUB,   `REG_CNT_H,    `REG_CNT_H,    `REG_CONST_1,   `DUMMY7b};
            70:  instr = {`JZ,    `REG_CNT_H,    17'd72};
            71:  instr = {`JUMP,  `REG_RZERO,    17'd61};

            // --- READ INPUT + MOVE ARCHER ---
            72:  instr = {`LOAD,  `REG_BTN_VAL, `REG_ADDR_BTNS, `DUMMY12b};
            73:  instr = {`AND,   `R30, `REG_BTN_VAL, `REG_CONST_1, `DUMMY7b};
            74:  instr = {`JZ,    `R30, 17'd78};
            75:  instr = {`SUB,   `R30, `REG_ARCHER_Y, `R28, `DUMMY7b};
            76:  instr = {`JZ,    `R30, 17'd78};
            77:  instr = {`SUB,   `REG_ARCHER_Y, `REG_ARCHER_Y, `REG_CONST_1, `DUMMY7b};
            78:  instr = {`AND,   `R30, `REG_BTN_VAL, `R29, `DUMMY7b};
            79:  instr = {`JZ,    `R30, 17'd83};
            80:  instr = {`SUB,   `R30, `REG_ARCHER_Y, `REG_LIMIT_Y, `DUMMY7b};
            81:  instr = {`JZ,    `R30, 17'd83};
            82:  instr = {`ADD,   `REG_ARCHER_Y, `REG_ARCHER_Y, `REG_CONST_1, `DUMMY7b};

            // --- FIRE ARROW ON BTNC ---
            83:  instr = {`LOADC, `R24, 17'd4};
            84:  instr = {`AND,   `R30, `REG_BTN_VAL, `R24, `DUMMY7b};
            85:  instr = {`JZ,    `R30, 17'd92};
            86:  instr = {`JZ,    `REG_ARROW_X, 17'd88};
            87:  instr = {`JUMP,  `REG_RZERO, 17'd92};
            88:  instr = {`ADD,   `REG_ARROW_X, `REG_ARCHER_X, `REG_ARCHER_W, `DUMMY7b};
            89:  instr = {`LOADC, `R24, 17'd10};
            90:  instr = {`ADD,   `REG_ARROW_Y, `REG_ARCHER_Y, `R24, `DUMMY7b};
            91:  instr = {`JUMP,  `REG_RZERO, 17'd92};

            // --- MOVE ARROW ---
            92:  instr = {`JZ,    `REG_ARROW_X, 17'd99};
            93:  instr = {`ADD,   `REG_ARROW_X, `REG_ARROW_X, `R29, `DUMMY7b};
            94:  instr = {`LOADC, `R24, 17'd318};
            95:  instr = {`SUB,   `R30, `REG_ARROW_X, `R24, `DUMMY7b};
            96:  instr = {`JZ,    `R30, 17'd98};
            97:  instr = {`JUMP,  `REG_RZERO, 17'd99};
            98:  instr = {`LOADC, `REG_ARROW_X, 17'd0};

            // --- SPAWN / MOVE TARGET ---
            99:  instr = {`JZ,    `REG_BALLOON_X, 17'd101};
            100: instr = {`JUMP,  `REG_RZERO, 17'd107};
            101: instr = {`LOAD,  `R30, `REG_ADDR_RAND, `DUMMY12b};
            102: instr = {`LOADC, `R24, 17'd254};
            103: instr = {`AND,   `REG_BALLOON_X, `R30, `R24, `DUMMY7b};
            104: instr = {`LOADC, `R24, 17'd40};
            105: instr = {`ADD,   `REG_BALLOON_X, `REG_BALLOON_X, `R24, `DUMMY7b};
            106: instr = {`LOADC, `REG_BALLOON_Y, 17'd0};
            107: instr = {`ADD,   `REG_BALLOON_Y, `REG_BALLOON_Y, `REG_CONST_1, `DUMMY7b};
            108: instr = {`LOADC, `R24, 17'd232};
            109: instr = {`SUB,   `R30, `REG_BALLOON_Y, `R24, `DUMMY7b};
            110: instr = {`JZ,    `R30, 17'd145};

            // --- COLLISION: ARROW WITH TARGET ---
            111: instr = {`JZ,    `REG_ARROW_X, 17'd150};
            112: instr = {`SUB,   `R30, `REG_ARROW_X, `REG_BALLOON_X, `DUMMY7b};
            113: instr = {`JZ,    `R30, 17'd122};
            114: instr = {`LOADC, `R24, 17'd2};
            115: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            116: instr = {`JZ,    `R30, 17'd122};
            117: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            118: instr = {`JZ,    `R30, 17'd122};
            119: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            120: instr = {`JZ,    `R30, 17'd122};
            121: instr = {`JUMP,  `REG_RZERO, 17'd150};
            122: instr = {`SUB,   `R30, `REG_ARROW_Y, `REG_BALLOON_Y, `DUMMY7b};
            123: instr = {`JZ,    `R30, 17'd140};
            124: instr = {`LOADC, `R24, 17'd1};
            125: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            126: instr = {`JZ,    `R30, 17'd140};
            127: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            128: instr = {`JZ,    `R30, 17'd140};
            129: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            130: instr = {`JZ,    `R30, 17'd140};
            131: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            132: instr = {`JZ,    `R30, 17'd140};
            133: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            134: instr = {`JZ,    `R30, 17'd140};
            135: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            136: instr = {`JZ,    `R30, 17'd140};
            137: instr = {`SUB,   `R30, `R30, `R24, `DUMMY7b};
            138: instr = {`JZ,    `R30, 17'd140};
            139: instr = {`JUMP,  `REG_RZERO, 17'd150};

            // --- HIT / RESPAWN CONTROL ---
            140: instr = {`LOADC, `REG_ARROW_X, 17'd0};
            141: instr = {`LOADC, `REG_BALLOON_X, 17'd0};
            142: instr = {`ADD,   `REG_SCORE_VAL, `REG_SCORE_VAL, `REG_CONST_1, `DUMMY7b};
            143: instr = {`STORE, `REG_SCORE_VAL, `REG_ADDR_SCORE, `DUMMY12b};
            144: instr = {`JUMP,  `REG_RZERO, 17'd150};
            145: instr = {`LOADC, `REG_BALLOON_X, 17'd0};
            146: instr = {`JUMP,  `REG_RZERO, 17'd150};

            // --- DRAW ARCHER ---
            150: instr = {`MUL,   `REG_VRAM_PTR, `REG_ARCHER_Y, `REG_SCR_WIDTH, `DUMMY7b};
            151: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_ARCHER_X, `DUMMY7b};
            152: instr = {`ADD,   `REG_CNT_H,    `REG_ARCHER_H, `R28,           `DUMMY7b};
            153: instr = {`ADD,   `REG_CNT_W,    `REG_ARCHER_W, `R28,           `DUMMY7b};
            154: instr = {`STORE, `REG_ARCHER_COLOR, `REG_VRAM_PTR, `DUMMY12b};
            155: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_CONST_1,   `DUMMY7b};
            156: instr = {`SUB,   `REG_CNT_W,    `REG_CNT_W,    `REG_CONST_1,   `DUMMY7b};
            157: instr = {`JZ,    `REG_CNT_W,    17'd159};
            158: instr = {`JUMP,  `REG_RZERO,    17'd154};
            159: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_OFFSET_LINE, `DUMMY7b};
            160: instr = {`SUB,   `REG_CNT_H,    `REG_CNT_H,    `REG_CONST_1,     `DUMMY7b};
            161: instr = {`JZ,    `REG_CNT_H,    17'd163};
            162: instr = {`JUMP,  `REG_RZERO,    17'd153};

            // --- DRAW ARROW ---
            163: instr = {`JZ,    `REG_ARROW_X, 17'd172};
            164: instr = {`MUL,   `REG_VRAM_PTR, `REG_ARROW_Y, `REG_SCR_WIDTH, `DUMMY7b};
            165: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_ARROW_X, `DUMMY7b};
            166: instr = {`ADD,   `REG_CNT_W,    `REG_ARROW_W, `R28,          `DUMMY7b};
            167: instr = {`STORE, `REG_ARROW_COLOR, `REG_VRAM_PTR, `DUMMY12b};
            168: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_CONST_1, `DUMMY7b};
            169: instr = {`SUB,   `REG_CNT_W,    `REG_CNT_W,    `REG_CONST_1, `DUMMY7b};
            170: instr = {`JZ,    `REG_CNT_W,    17'd172};
            171: instr = {`JUMP,  `REG_RZERO,    17'd167};

            // --- DRAW TARGET ---
            172: instr = {`JZ,    `REG_BALLOON_X, 17'd187};
            173: instr = {`MUL,   `REG_VRAM_PTR, `REG_BALLOON_Y, `REG_SCR_WIDTH, `DUMMY7b};
            174: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_BALLOON_X, `DUMMY7b};
            175: instr = {`ADD,   `REG_CNT_H,    `REG_BALLOON_W, `R28,           `DUMMY7b};
            176: instr = {`ADD,   `REG_CNT_W,    `REG_BALLOON_W, `R28,           `DUMMY7b};
            177: instr = {`STORE, `REG_BALLOON_COLOR, `REG_VRAM_PTR, `DUMMY12b};
            178: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_CONST_1,   `DUMMY7b};
            179: instr = {`SUB,   `REG_CNT_W,    `REG_CNT_W,    `REG_CONST_1,   `DUMMY7b};
            180: instr = {`JZ,    `REG_CNT_W,    17'd182};
            181: instr = {`JUMP,  `REG_RZERO,    17'd177};
            182: instr = {`ADD,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_SCR_WIDTH, `DUMMY7b};
            183: instr = {`SUB,   `REG_VRAM_PTR, `REG_VRAM_PTR, `REG_BALLOON_W, `DUMMY7b};
            184: instr = {`SUB,   `REG_CNT_H,    `REG_CNT_H,    `REG_CONST_1,   `DUMMY7b};
            185: instr = {`JZ,    `REG_CNT_H,    17'd187};
            186: instr = {`JUMP,  `REG_RZERO,    17'd176};
            187: instr = {`JUMP,  `REG_RZERO,    17'd30};

            default: instr = {`NOP, 22'd0};
        endcase
    end
endmodule

// =========================================================

module VRAM_DualPort(
    input logic clk, we_cpu, [16:0] addr_cpu, [16:0] addr_vga,
    input logic [1:0] din_cpu, output logic [1:0] dout_vga
);
    (* ram_style = "block" *) logic [1:0] vram [0:76799];

    always_ff @(posedge clk) begin
        if (we_cpu) vram[addr_cpu] <= din_cpu;
        dout_vga <= vram[addr_vga];
    end
endmodule

module vga_sync_1440x900(
    input logic clk, input rst, 
    output logic hsync, vsync, video_on, [10:0] x, y);
    localparam int H_ACTIVE = 640;
    localparam int H_FRONT  = 16;
    localparam int H_SYNC   = 96;
    localparam int H_BACK   = 48;
    localparam int H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;

    localparam int V_ACTIVE = 480;
    localparam int V_FRONT  = 10;
    localparam int V_SYNC   = 2;
    localparam int V_BACK   = 33;
    localparam int V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

    logic [10:0] h_cnt = 0, v_cnt = 0;

    always_ff @(posedge clk) begin
        if (rst) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end
        else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1)
                    v_cnt <= 0;
                else
                    v_cnt <= v_cnt + 1;
            end
            else
                h_cnt <= h_cnt + 1;
        end
    end
    
    assign hsync = ~((h_cnt >= H_ACTIVE + H_FRONT) &&
                     (h_cnt <  H_ACTIVE + H_FRONT + H_SYNC));
    assign vsync = ~((v_cnt >= V_ACTIVE + V_FRONT) &&
                     (v_cnt <  V_ACTIVE + V_FRONT + V_SYNC));

    assign video_on = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);

    assign x = h_cnt;
    assign y = v_cnt;
endmodule

module SevenSeg_Driver(
    input logic clock, [31:0] data, 
    output logic [7:0] seg, 
    output logic [7:0] an
);
    logic [19:0] cnt; 
    always_ff @(posedge clock) cnt <= cnt + 1;
    
    logic [3:0] hex;
    always_comb begin
        an = ~(1 << cnt[19:17]);
        
        case(cnt[19:17])
            0: hex = data[3:0]; 
            1: hex = data[7:4]; 
            2: hex = data[11:8]; 
            3: hex = data[15:12];
            4: hex = data[19:16]; 
            5: hex = data[23:20]; 
            6: hex = data[27:24]; 
            7: hex = data[31:28];
            default: hex = 0;
        endcase
        
        case(hex)
            4'h0: seg = 8'b1100_0000; // 0
            4'h1: seg = 8'b1111_1001; // 1
            4'h2: seg = 8'b1010_0100; // 2
            4'h3: seg = 8'b1011_0000; // 3
            4'h4: seg = 8'b1001_1001; // 4
            4'h5: seg = 8'b1001_0010; // 5
            4'h6: seg = 8'b1000_0010; // 6
            4'h7: seg = 8'b1111_1000; // 7
            4'h8: seg = 8'b1000_0000; // 8
            4'h9: seg = 8'b1001_0000; // 9
            4'hA: seg = 8'b1000_1000; // A (Majuscul)
            4'hB: seg = 8'b1000_0011; // b (Minuscul)
            4'hC: seg = 8'b1100_0110; // C (Majuscul)
            4'hD: seg = 8'b1010_0001; // d (Minuscul)
            4'hE: seg = 8'b1000_0110; // E (Majuscul)
            4'hF: seg = 8'b1000_1110; // F (Majuscul)
            default: seg = 8'b1111_1111; // toate stinse
        endcase
    end
endmodule
