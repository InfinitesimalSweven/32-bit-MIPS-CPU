`ifndef DMEM_SV
`define DMEM_SV


module dmem
// n=bit length of register; r=bit length of addr to limit memory and not crash your verilog emulator
    #(parameter n = 32, parameter r = 8, parameter LATENCY = 10)(
    //
    // ---------------- PORT DEFINITIONS ----------------
    //
    input  logic           clk, reset,
    input  logic           memread, memwrite,
    input  logic [(n-1):0] addr, writedata,
    output logic [(n-1):0] readdata,
    output logic           dmem_ready
);
    //
    // ---------------- MODULE DESIGN IMPLEMENTATION ----------------
    //
    logic [(n-1):0] RAM[0:(2**r-1)];

    // Latency Counter State
    logic [3:0] delay_counter;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            delay_counter <= 0;
            dmem_ready <= 0;
        end else begin
            if (memread || memwrite) begin
                if (delay_counter == LATENCY - 1) begin
                    dmem_ready <= 1;
                    delay_counter <= 0;
                    if (memwrite) RAM[addr[(n-1):2]] <= writedata;
                end else begin
                    dmem_ready <= 0;
                    delay_counter <= delay_counter + 1;
                end
            end else begin
                dmem_ready <= 0;
                delay_counter <= 0;
            end
        end
    end

    assign readdata = RAM[addr[(n-1):2]]; // word aligned (ignores lower 2 bits of address)

endmodule



`endif // DMEM_SV