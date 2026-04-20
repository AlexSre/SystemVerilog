`timescale 1ns / 1ps
`include "isa.vh"

module tb_CPU_ALU();
    // Semnale pentru CPU
    logic clk;
    logic rst;
    logic [25:0] instr;
    logic [16:0] pc;
    logic [16:0] addr_bus;
    logic [15:0] data_in;
    logic [15:0] data_out;
    logic we, z_flag;

    // Instanțiere CPU
    CPU_17bit uut (
        .clk(clk), .rst(rst), .instr(instr),
        .pc(pc), .addr_bus(addr_bus), 
        .data_in(data_in), .data_out(data_out),
        .we(we), .z_flag(z_flag)
    );

    // Generare ceas (100MHz)
    // Procedura de test
    initial begin
        clk = 0; rst = 1; instr = 0; data_in = 0;
        #1 clk = 1;
        #1 rst = 0;
        #1 clk = 0;

        $display("--- Start Teste ALU ---");

        // TEST LOADC: Incarcam R1 cu 10 si R2 cu 5
        #1 instr = {`LOADC, `R1, 17'd10};
        #1 clk = ~clk;
        #1 clk = ~clk;

        #1 instr = {`LOADC, `R2, 17'd5};
        #1 clk = ~clk;
        #1 clk = ~clk;

        // TEST ADD: R3 = R1 + R2 (10 + 5 = 15)
        #1 instr = {`ADD, `R3, `R1, `R2, `DUMMY7b};
        #1 clk = ~clk;
        #1 clk = ~clk;
        
        // TEST SUB: R4 = R1 - R2 (10 - 5 = 5)
        #1 instr = {`SUB, `R4, `R1, `R2, `DUMMY7b};
        #1 clk = ~clk;
        #1 clk = ~clk;

        // TEST AND: R5 = R1 & R2 (1010 & 0101 = 0)
        #1 instr = {`AND, `R5, `R1, `R2, `DUMMY7b};
        #1 clk = ~clk;
        #1 clk = ~clk;


        // TEST OR:  R6 = R1 | R2 (1010 | 0101 = 15)
        #1 instr = {`OR,  `R6, `R1, `R2, `DUMMY7b};
        #1 clk = ~clk;
        #1 clk = ~clk;

        // TEST XOR: R7 = R1 ^ R2 (1010 ^ 0101 = 15)
        #1 instr = {`XOR, `R7, `R1, `R2, `DUMMY7b};
        #1 clk = ~clk;
        #1 clk = ~clk;

        // TEST SUB pentru Zero Flag: R8 = R1 - R1 (10 - 10 = 0)
        #1 instr = {`SUB, `R7, `R1, `R1, `DUMMY7b};
        #1 clk = ~clk;
        #1 clk = ~clk;

        #1 instr = {`LOADC, `R7,  17'h4321}; 
        #1 clk = ~clk;
        #1 clk = ~clk;
        #1 instr = {`LOADC, `R0,  `IO_SCORE}; 
        #1 clk = ~clk;
        #1 clk = ~clk;
        #1 instr = {`STORE, `R7,  `R0, `DUMMY12b};
        #1 clk = ~clk;
        #1 clk = ~clk;
        #1 instr = {`LOAD, `R6,  `R0, `DUMMY12b};
        #1 clk = ~clk;
        #1 clk = ~clk;
        #1 clk = ~clk;
        #1 clk = ~clk;
        #2;
        $finish;
    end

    // Afisare rezultate in consola
    initial begin
        //$monitor("Time=%0t | PC=%h | Instr=%h | Rdest_Val=%h | Zero=%b", 
          //       $time, pc, instr, uut.alu_out, z_flag);
    end
endmodule


`timescale 1ns / 1ps
`include "isa.vh"

module tb_Memory_Test();
    // Semnale pentru simulare
    logic clk;
    logic rst;
    logic [25:0] instr;
    logic [15:0] data_in;

    // Ieșiri CPU
    logic [16:0] pc;
    logic [16:0] addr_bus;
    logic [15:0] data_out;
    logic we;
    logic z_flag;

    // Instanțiere CPU
    CPU_17bit uut (
        .clk(clk), .rst(rst), .instr(instr),
        .pc(pc), .addr_bus(addr_bus), 
        .data_in(data_in), .data_out(data_out),
        .we(we), .z_flag(z_flag)
    );

    // Generare ceas: 10ns perioadă (100MHz)
    always #5 clk = ~clk;

    // Procedura de test
    initial begin
        // 1. Inițializare sistem
        clk = 0;
        rst = 1;
        instr = 0;
        data_in = 16'h0000;
        
        $display("--- Start Test Memorie ---");
        #20 rst = 0; // Eliberăm resetul

        // PASUL 1: Pregătim datele (0xABCD) și adresa (0x0064 -> 100 dec)
        // LOADC R1, 0xABCD
        @(negedge clk); instr = {`LOADC, 5'd1, 17'hABCD};
        // LOADC R0, 0x0064
        @(negedge clk); instr = {`LOADC, 5'd0, 17'h0064};

        // PASUL 2: Executăm SCRIEREA (STORE)
        // MEM[R0] = R1  =>  VRAM[100] = 0xABCD
        @(negedge clk); instr = {`STORE, 5'd1, 5'd0, 12'd0}; 
        
        // Verificăm în acest moment semnalele de ieșire
        #2; // Așteptăm propagarea logicii
        if (we && addr_bus == 17'h64 && data_out == 16'hABCD)
            $display("[OK] Semnale STORE corecte: Addr=%h, Data=%h", addr_bus, data_out);
        else
            $display("[ERR] STORE incorect! WE=%b, Addr=%h, Data=%h", we, addr_bus, data_out);

        // PASUL 3: Pregătim CITIREA (LOAD)
        // Simulăm memoria: setăm data_in cu valoarea pe care o "citește" CPU-ul
        data_in = 16'hABCD; 
        // R6 = MEM[R0]
        @(negedge clk); instr = {`LOAD, 5'd6, 5'd0, 12'd0};

        // PASUL 4: Verificăm dacă R6 a primit valoarea
        // Trebuie să mai așteptăm un ciclu pentru Write-Back în reg R6
        @(negedge clk); 
        #2;
        // Pentru a verifica R6, am putea face o operatie ALU sau monitoriza uut.regs[6]
        if (uut.regs[6] == 16'hABCD)
            $display("[OK] LOAD corect: Registrul R6 a primit %h", uut.regs[6]);
        else
            $display("[ERR] LOAD incorect: Registrul R6 are %h", uut.regs[6]);

        #20;
        $display("--- Test Finalizat ---");
        $finish;
    end

    // Monitorizare automată
    initial begin
        $monitor("T=%0t | PC=%d | Instr=%h | Addr=%h | DataOut=%h | WE=%b | R6=%h", 
                 $time, pc, instr, addr_bus, data_out, we, uut.regs[6]);
    end

endmodule

module tb_JZ_Register();
    logic clk;
    logic rst;
    logic [25:0] instr;
    logic [31:0] data_in;
    logic [16:0] pc;
    logic [16:0] addr_bus;
    logic [31:0] data_out;
    logic we;
    logic z_flag;

    CPU_17bit uut (
        .clk(clk), .rst(rst), .instr(instr),
        .pc(pc), .addr_bus(addr_bus),
        .data_in(data_in), .data_out(data_out),
        .we(we), .z_flag(z_flag)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        instr = 26'd0;
        data_in = 32'd0;

        #12;
        rst = 0;

        @(negedge clk) instr = {`LOADC, `R1, 17'd0};
        @(negedge clk) instr = {`JZ,    `R1, 17'd7};
        @(posedge clk);
        #1;
        if (pc != 17'd7) begin
            $display("[ERR] JZ should branch when the selected register is zero. PC=%0d", pc);
            $finish;
        end

        @(negedge clk) instr = {`LOADC, `R2, 17'd3};
        @(negedge clk) instr = {`JZ,    `R2, 17'd12};
        @(posedge clk);
        #1;
        if (pc != 17'd9) begin
            $display("[ERR] JZ should not branch when the selected register is non-zero. PC=%0d", pc);
            $finish;
        end

        $display("[OK] JZ register semantics verified.");
        $finish;
    end
endmodule
