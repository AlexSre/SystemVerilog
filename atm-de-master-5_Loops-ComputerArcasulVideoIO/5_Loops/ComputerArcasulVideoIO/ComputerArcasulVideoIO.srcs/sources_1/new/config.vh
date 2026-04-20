`define COLOR_BLUE 12'h00F // Blue
`define COLOR_RED  12'hF00 // Red
`define COLOR_BLACK 12'h000 // Black
`define COLOR_WHITE 12'hFFF // White

`define ARCHER_WIDTH    17'd10
`define ARCHER_HEIGHT   17'd20
`define ARCHER_COLOR    `COLOR_BLUE

`define SCREEN_WIDTH   17'd320
`define SCREEN_OFFSET_LINE 17'd300

`define SCREEN_HEIGHT  17'd240


// =========================================================
// ALOCARE REGISTRE
// =========================================================

// --- 1. REGISTRE DE LUCRU (Temp) ---
`define REG_VRAM_PTR         `R0   
`define REG_CNT_W            `R1   
`define REG_CNT_H            `R2   
`define REG_TEMP_RES         `R3   

// --- 2. I/O ȘI SCOR ---
`define REG_ADDR_SCORE       `R4   
`define REG_ADDR_BTNS        `R5   
`define REG_ADDR_RAND        `R6   
`define REG_BTN_VAL          `R7   
`define REG_SCORE_VAL        `R8   
`define REG_OFFSET_LINE      `R9   

// --- 3. ARCAȘ (ARCHER) ---
`define REG_ARCHER_X         `R10
`define REG_ARCHER_Y         `R11
`define REG_ARCHER_W         `R12
`define REG_ARCHER_H         `R13
`define REG_ARCHER_COLOR     `R14  

// --- 4. SĂGEATĂ (ARROW) ---
`define REG_ARROW_X          `R15
`define REG_ARROW_Y          `R16
`define REG_ARROW_W          `R17
`define REG_ARROW_COLOR      `R18  

// --- 5. BALON (BALLOON) ---
`define REG_BALLOON_X        `R19
`define REG_BALLOON_Y        `R20
`define REG_BALLOON_W        `R21
`define REG_BALLOON_COLOR    `R22  

// --- 6. CONSTANTE ȘI REZERVĂ ---
`define REG_CONST_1          `R25  
`define REG_SCR_WIDTH        `R26  
`define REG_LIMIT_Y          `R27  
`define REG_RZERO            `R31
