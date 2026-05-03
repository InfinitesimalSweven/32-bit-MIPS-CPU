`ifndef CONTROLLER_SV
`define CONTROLLER_SV


`include "src/maindec.sv"
`include "src/aludec.sv"

module controller(
    input  logic [5:0] opD, functD,
    output logic       memtoregD, memwriteD,
    output logic       alusrcD, regdstD, regwriteD,
    output logic       branchD, jumpD,
    output logic [3:0] alucontrolD
);
    logic [1:0] aluopD;
    
    // CPU main decoder
    maindec md(opD, memtoregD, memwriteD, branchD, alusrcD, regdstD, regwriteD, jumpD, aluopD);
    
    // CPU ALU decoder
    aludec  ad(functD, aluopD, alucontrolD);

endmodule



`endif // CONTROLLER_SV