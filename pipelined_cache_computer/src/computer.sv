`ifndef COMPUTER_SV
`define COMPUTER_SV

`include "src/cpu.sv"
`include "src/imem.sv"
`include "src/dmem.sv"
`include "src/cache_direct_mapped.sv"


module computer(
    input  logic        clk, reset, intr,
    input  logic        cache_en,  // 1 = use cache, 0 = bypass cache directly to dmem
    output logic [31:0] writedata, dataadr,
    output logic        memwrite
);
    logic [31:0] pc, instr, readdata;
    logic        mem_stall, cache_mem_stall;
    logic [31:0] dmem_addr, dmem_writedata, dmem_readdata, cache_readdata;
    logic        dmem_memwrite, dmem_memread;
    logic        memread, dmem_ready;

    // CPU instantiation
    cpu mips_pipelined(
        .clk(clk), .reset(reset), .intr(intr), .mem_stall(mem_stall),
        .pcF(pc), .instrF(instr),
        .memwriteM(memwrite), .memreadM(memread), .aluoutM(dataadr),
        .writedataM(writedata), .readdataM(readdata)
    );

    // Instruction Memory
    imem imem(
        .addr(pc[9:2]),
        .readdata(instr)
    );

    // Cache arrays
    cache_direct_mapped dcache (
        .clk(clk),
        .reset(reset),
        .cpu_addr(dataadr),
        .cpu_writedata(writedata),
        .cpu_memwrite(memwrite && cache_en),
        .cpu_memread(memread && cache_en),
        .cpu_readdata(cache_readdata),
        .mem_stall(cache_mem_stall),
        // Main Memory side
        .dmem_addr(dmem_addr),
        .dmem_writedata(dmem_writedata),
        .dmem_memwrite(dmem_memwrite),
        .dmem_memread(dmem_memread),
        .dmem_readdata(dmem_readdata),
        .dmem_ready(dmem_ready)
    );

    // BYPASS LOGIC
    // If cache_en == 0, route CPU directly to DMEM and stall pipeline until dmem_ready
    assign readdata = cache_en ? cache_readdata : dmem_readdata;
    assign mem_stall = cache_en ? cache_mem_stall : ((memread || memwrite) && !dmem_ready);

    logic final_dmem_memread, final_dmem_memwrite;
    logic [31:0] final_dmem_addr, final_dmem_writedata;
    assign final_dmem_memread   = cache_en ? dmem_memread   : memread;
    assign final_dmem_memwrite  = cache_en ? dmem_memwrite  : memwrite;
    assign final_dmem_addr      = cache_en ? dmem_addr      : dataadr;
    assign final_dmem_writedata = cache_en ? dmem_writedata : writedata;

    // Main Data Memory
    dmem dmem(
        .clk(clk), .reset(reset),
        .memread(final_dmem_memread),
        .memwrite(final_dmem_memwrite),
        .addr(final_dmem_addr),
        .writedata(final_dmem_writedata),
        .readdata(dmem_readdata),
        .dmem_ready(dmem_ready)
    );

endmodule



`endif // COMPUTER_SV