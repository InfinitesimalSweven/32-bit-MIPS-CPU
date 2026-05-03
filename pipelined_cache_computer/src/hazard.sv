`ifndef HAZARD_SV
`define HAZARD_SV

module hazard (
    input  logic [4:0] rsD, rtD, rsE, rtE,
    input  logic [4:0] writeregE, writeregM, writeregW,
    input  logic       regwriteE, regwriteM, regwriteW,
    input  logic       memtoregE, memtoregM,
    input  logic       branchD,
    input  logic       jalE, jalM, jalW,
    input  logic       intr,
    input  logic       mem_stall,
    output logic       forwardaD, forwardbD,
    output logic [1:0] forwardaE, forwardbE,
    output logic       stallF, stallD, stallE, stallM, stallW, flushD, flushE,
    output logic       Exception_Flag
);

    logic [4:0] effWriteregE, effWriteregM, effWriteregW;
    assign effWriteregE = jalE ? 5'd31 : writeregE;
    assign effWriteregM = jalM ? 5'd31 : writeregM;
    assign effWriteregW = jalW ? 5'd31 : writeregW;

    // 1. Forwarding to Execute stage (ALU inputs)
    always_comb begin
        forwardaE = 2'b00;
        forwardbE = 2'b00;

        if (rsE != 0) begin
            if (rsE == effWriteregM && regwriteM) forwardaE = 2'b10;
            else if (rsE == effWriteregW && regwriteW) forwardaE = 2'b01;
        end

        if (rtE != 0) begin
            if (rtE == effWriteregM && regwriteM) forwardbE = 2'b10;
            else if (rtE == effWriteregW && regwriteW) forwardbE = 2'b01;
        end
    end

    // 2. Forwarding to Decode stage (Branch equality checks)
    assign forwardaD = (rsD != 0) && (rsD == effWriteregM) && regwriteM;
    assign forwardbD = (rtD != 0) && (rtD == effWriteregM) && regwriteM;

    // 3. Stalls
    logic lwstall;
    logic branchstall;

    // Load-use data hazard stalling
    assign lwstall = memtoregE && (rtE == rsD || rtE == rtD);

    // Branch hazard stalling (if branch evaluates in ID, must wait for precise conditions)
    assign branchstall = branchD &&
             (regwriteE && (writeregE == rsD || writeregE == rtD) ||
              memtoregM && (writeregM == rsD || writeregM == rtD));

    assign Exception_Flag = intr;

    assign stallD = lwstall || branchstall || mem_stall;
    assign stallF = stallD;       // stallD already includes mem_stall
    assign stallE = mem_stall;
    assign stallM = mem_stall;
    assign stallW = mem_stall;
    assign flushD = Exception_Flag && !mem_stall;  // Clear Decode on exception, unless frozen
    assign flushE = (lwstall || branchstall || Exception_Flag) && !mem_stall; // Clear Execute on data stall or exception, unless frozen
    
endmodule



`endif // HAZARD_SV