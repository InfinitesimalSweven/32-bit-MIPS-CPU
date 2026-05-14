`ifndef CPU_SV
`define CPU_SV

`include "src/controller.sv"
`include "src/datapath.sv"
`include "src/hazard.sv"

module cpu(
    input  logic        clk, reset, intr, mem_stall,
    output logic [31:0] pcF,
    input  logic [31:0] instrF,
    output logic        memwriteM, memreadM,
    output logic [31:0] aluoutM, writedataM,
    input  logic [31:0] readdataM
);
    logic [31:0] instrD;
    logic branchD, jumpD;
    logic jalD, jrD;
    logic memtoregD, memwriteD, alusrcD, regdstD, regwriteD;
    logic [3:0] alucontrolD;
    
    logic stallF, stallD, stallE, stallM, stallW, flushD, flushE;
    logic Exception_Flag;
    logic forwardaD, forwardbD;
    logic [1:0] forwardaE, forwardbE;
    logic [4:0] rsD, rtD, rsE, rtE;
    logic [4:0] writeregE, writeregM, writeregW;
    logic regwriteE, regwriteM, regwriteW;
    logic memtoregE, memtoregM;
    logic jalE, jalM, jalW;

    controller c(
        .opD(instrD[31:26]), .functD(instrD[5:0]),
        .memtoregD(memtoregD), .memwriteD(memwriteD),
        .alusrcD(alusrcD), .regdstD(regdstD), .regwriteD(regwriteD),
        .branchD(branchD), .jumpD(jumpD),
        .jalD(jalD), .jrD(jrD),
        .alucontrolD(alucontrolD)
    );

    datapath dp(
        .clk(clk), .reset(reset),
        .pcF(pcF), .instrF(instrF),
        .aluoutM(aluoutM), .writedataM(writedataM), .readdataM(readdataM),
        .memtoregD(memtoregD), .memwriteD(memwriteD),
        .alusrcD(alusrcD), .regdstD(regdstD), .regwriteD(regwriteD),
        .branchD(branchD), .jumpD(jumpD), .jalD(jalD), .jrD(jrD), .alucontrolD(alucontrolD),
        .instrD(instrD),
        .stallF(stallF), .stallD(stallD), .stallE(stallE), .stallM(stallM), .stallW(stallW), .flushE(flushE), .flushD(flushD),
        .Exception_Flag(Exception_Flag),
        .forwardaD(forwardaD), .forwardbD(forwardbD),
        .forwardaE(forwardaE), .forwardbE(forwardbE),
        .rsD(rsD), .rtD(rtD), .rsE(rsE), .rtE(rtE),
        .writeregE(writeregE), .writeregM(writeregM), .writeregW(writeregW),
        .regwriteE(regwriteE), .regwriteM(regwriteM), .regwriteW(regwriteW),
        .memtoregE(memtoregE), .memtoregM(memtoregM),
        .memwriteM_out(memwriteM),
        .jalE_out(jalE), .jalM_out(jalM), .jalW_out(jalW)
    );
 
    assign memreadM = memtoregM;
 
    hazard h(
        .rsD(rsD), .rtD(rtD), .rsE(rsE), .rtE(rtE),
        .writeregE(writeregE), .writeregM(writeregM), .writeregW(writeregW),
        .regwriteE(regwriteE), .regwriteM(regwriteM), .regwriteW(regwriteW),
        .memtoregE(memtoregE), .memtoregM(memtoregM), .branchD(branchD),
        .jalE(jalE), .jalM(jalM), .jalW(jalW),
        .jrD(jrD),              // FIX: wire jrD so hazard can detect lw->jr stall
        .intr(intr),
        .forwardaD(forwardaD), .forwardbD(forwardbD),
        .forwardaE(forwardaE), .forwardbE(forwardbE),
        .mem_stall(mem_stall),
        .stallF(stallF), .stallD(stallD), .stallE(stallE), .stallM(stallM), .stallW(stallW), .flushE(flushE), .flushD(flushD),
        .Exception_Flag(Exception_Flag)
    );

endmodule



`endif // CPU_SV