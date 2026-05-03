`ifndef DATAPATH_SV
`define DATAPATH_SV

`include "src/regfile.sv"
`include "src/alu.sv"
`include "src/adder.sv"
`include "src/sl2.sv"
`include "src/mux2.sv"
`include "src/mux3.sv"
`include "src/signext.sv"
`include "src/eqcmp.sv"

module datapath(
    input  logic        clk, reset,
    output logic [31:0] pcF,
    input  logic [31:0] instrF,
    output logic [31:0] aluoutM, writedataM,
    input  logic [31:0] readdataM,

    input  logic        memtoregD, memwriteD,
    input  logic        alusrcD, regdstD, regwriteD,
    input  logic        jumpD, branchD,
    input  logic        jalD, jrD,          // NEW: jal and jr control signals
    input  logic [3:0]  alucontrolD,

    output logic [31:0] instrD,

    input  logic        stallF, stallD, stallE, stallM, stallW, flushD, flushE,
    input  logic        Exception_Flag,
    input  logic        forwardaD, forwardbD,
    input  logic [1:0]  forwardaE, forwardbE,

    output logic [4:0]  rsD, rtD, rsE, rtE,
    output logic [4:0]  writeregE, writeregM, writeregW,
    output logic        regwriteE, regwriteM, regwriteW,
    output logic        memtoregE, memtoregM,
    output logic        memwriteM_out
);

    // --- FETCH STAGE ---
    logic [31:0] pcnextFD, pcnextbrFD, pcplus4F, pcbranchD;
    logic pcsrcD;
    logic [31:0] pcplus4D;
    mux2 #(32) pcbrmux(pcplus4F, pcbranchD, pcsrcD, pcnextbrFD);
    
    logic [31:0] pcjumpFD;
    assign pcjumpFD = {pcplus4D[31:28], instrD[25:0], 2'b00};
    
    // NEW: jr selects srcaD as next PC; takes priority over normal jump
    always_comb begin
        if (Exception_Flag) pcnextFD = 32'h8000_0180;
        else if (jrD)       pcnextFD = srcaD;
        else if (jumpD)     pcnextFD = pcjumpFD;
        else                pcnextFD = pcnextbrFD;
    end
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset)        pcF <= 32'b0;
        else if (~stallF) pcF <= pcnextFD;
    end
    
    assign pcplus4F = pcF + 32'b100;

    // --- IF/ID REGISTER ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushD) begin
            instrD   <= 32'b0;
            pcplus4D <= 32'b0;
        end else if (~stallD) begin
            instrD   <= (pcsrcD || jumpD || jrD) ? 32'b0 : instrF; // NEW: flush on jr too
            pcplus4D <= pcplus4F;
        end
    end

    // --- DECODE STAGE ---
    logic [31:0] srcaD, srcbD;
    logic [31:0] signimmD, signimmshD;
    logic [31:0] resultW;
    logic        equalD;

    assign rsD = instrD[25:21];
    assign rtD = instrD[20:16];
    logic [4:0] rdD;
    assign rdD = instrD[15:11];

    regfile rf(clk, regwriteW, rsD, rtD, writeregW, resultW, srcaD, srcbD);
    
    logic [31:0] compaD, compbD;
    assign compaD = forwardaD ? aluoutM : srcaD;
    assign compbD = forwardbD ? aluoutM : srcbD;
    eqcmp comp(compaD, compbD, equalD);
    
    assign pcsrcD     = branchD & equalD;
    assign signimmshD = signimmD << 2;
    assign pcbranchD  = pcplus4D + signimmshD;
    signext se(instrD[15:0], signimmD);

    // --- ID/EX REGISTER ---
    logic [31:0] srcaE, srcbE, signimmE;
    logic [4:0]  rdE;
    logic        memwriteE, alusrcE, regdstE;
    logic [3:0]  alucontrolE;
    logic [31:0] pcplus4E;
    logic        jalE;                       // NEW: pipeline jal to EX

    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushE) begin
            regwriteE   <= 0;
            memtoregE   <= 0;
            memwriteE   <= 0;
            alusrcE     <= 0;
            regdstE     <= 0;
            alucontrolE <= 0;
            srcaE       <= 0;
            srcbE       <= 0;
            signimmE    <= 0;
            rsE         <= 0;
            rtE         <= 0;
            rdE         <= 0;
            pcplus4E    <= 0;
            jalE        <= 0;               // NEW
        end else if (~stallE) begin
            regwriteE   <= regwriteD;
            memtoregE   <= memtoregD;
            memwriteE   <= memwriteD;
            alusrcE     <= alusrcD;
            regdstE     <= regdstD;
            alucontrolE <= alucontrolD;
            srcaE       <= srcaD;
            srcbE       <= srcbD;
            signimmE    <= signimmD;
            rsE         <= rsD;
            rtE         <= rtD;
            rdE         <= rdD;
            pcplus4E    <= pcplus4D;
            jalE        <= jalD;            // NEW
        end
    end

    // --- EXECUTE STAGE ---
    logic [31:0] srca2E, srcb2E, srcb3E;
    logic [31:0] aluoutE;
    logic zeroE;
    
    mux3 #(32) forwardamux(srcaE, resultW, aluoutM, forwardaE, srca2E);
    mux3 #(32) forwardbmux(srcbE, resultW, aluoutM, forwardbE, srcb2E);
    mux2 #(32) srcbmux(srcb2E, signimmE, alusrcE, srcb3E);
    alu alu(clk, srca2E, srcb3E, alucontrolE, aluoutE, zeroE);
    // NEW: jal overrides writereg to 31; otherwise normal rd/rt selection
    logic [4:0] writeregE_normal;
    mux2 #(5) wrmux(rtE, rdE, regdstE, writeregE_normal);
    assign writeregE = jalE ? 5'd31 : writeregE_normal;

    // Exception tracking Register
    logic [31:0] EPC;
    always_ff @(posedge clk or posedge reset) begin
        if (reset)           EPC <= 32'b0;
        else if (Exception_Flag) EPC <= pcplus4D - 32'd4;
    end

    // --- EX/MEM REGISTER ---
    logic        jalM;                       // NEW: pipeline jal to MEM
    logic [31:0] pcplus4M;                  // NEW: pipeline pcplus4 to MEM
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            regwriteM     <= 0;
            memtoregM     <= 0;
            memwriteM_out <= 0;
            aluoutM       <= 0;
            writedataM    <= 0;
            writeregM     <= 0;
            jalM          <= 0;             // NEW
            pcplus4M      <= 0;             // NEW
        end else if (~stallM) begin
            regwriteM     <= regwriteE;
            memtoregM     <= memtoregE;
            memwriteM_out <= memwriteE;
            aluoutM       <= aluoutE;
            writedataM    <= srcb2E;
            writeregM     <= writeregE;
            jalM          <= jalE;          // NEW
            pcplus4M      <= pcplus4E;      // NEW
        end
    end

    // --- MEM/WB REGISTER ---
    logic        memtoregW, jalW;           // NEW: jalW
    logic [31:0] readdataW, aluoutW, pcplus4W; // NEW: pcplus4W
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            regwriteW <= 0;
            memtoregW <= 0;
            readdataW <= 0;
            aluoutW   <= 0;
            writeregW <= 0;
            jalW      <= 0;                 // NEW
            pcplus4W  <= 0;                 // NEW
        end else if (~stallW) begin
            regwriteW <= regwriteM;
            memtoregW <= memtoregM;
            readdataW <= readdataM;
            aluoutW   <= aluoutM;
            writeregW <= writeregM;
            jalW      <= jalM;              // NEW
            pcplus4W  <= pcplus4M;          // NEW
        end
    end

    // NEW: jal selects pcplus4W as writeback result instead of ALU/memory
    mux3 #(32) resmux(aluoutW, readdataW, pcplus4W, {jalW, memtoregW}, resultW);

endmodule



`endif // DATAPATH_SV