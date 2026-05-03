`ifndef CACHE_DIRECT_MAPPED_SV
`define CACHE_DIRECT_MAPPED_SV

//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2026
// Engineer: Prof Rob Marano
// 
//     Create Date: 2026-04-23
//     Module Name: cache_direct_mapped
//     Description: 16-word Direct-Mapped Cache
//                  - 1 word (4 bytes) per block.
//                  - 16 blocks total.
//                  - 32-bit Address Breakdown:
//                      Offset: 2 bits (bytes within word, addr[1:0])
//                      Index:  4 bits (16 blocks, addr[5:2])
//                      Tag:    26 bits (addr[31:6])
//////////////////////////////////////////////////////////////////////////////////

module cache_direct_mapped (
    input  logic        clk,
    input  logic        reset,
    // Interface to CPU
    input  logic [31:0] cpu_addr,
    input  logic [31:0] cpu_writedata,
    input  logic        cpu_memwrite,
    input  logic        cpu_memread,
    output logic [31:0] cpu_readdata,
    output logic        mem_stall,      // Tells CPU to freeze
    
    // Interface to Main Memory (DMEM)
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_writedata,
    output logic        dmem_memwrite,
    output logic        dmem_memread,
    input  logic [31:0] dmem_readdata,
    input  logic        dmem_ready
);

    // ------------------------------------------------------------------------
    // CACHE STRUCTURE
    // ------------------------------------------------------------------------
    // 16 blocks, each containing: 1 Valid Bit, 26 Tag Bits, 32 Data Bits
    logic        valid_array [15:0];
    logic [25:0] tag_array   [15:0];
    logic [31:0] data_array  [15:0];

    // ------------------------------------------------------------------------
    // ADDRESS PARSING
    // ------------------------------------------------------------------------
    logic [25:0] tag;
    logic [3:0]  index;
    // Offset is bits [1:0], which are ignored since memory is word-aligned.
    
    assign index = cpu_addr[5:2];
    assign tag   = cpu_addr[31:6];

    // ------------------------------------------------------------------------
    // HIT / MISS LOGIC
    // ------------------------------------------------------------------------
    logic hit;
    logic miss;

    // A hit occurs if the block is valid AND the tag matches
    assign hit = valid_array[index] && (tag_array[index] == tag);
    
    // Only generate a miss if the CPU is actively asking for memory!
    assign miss = (cpu_memread || cpu_memwrite) && !hit;

    // CPU Readdata is instantly provided on a hit
    assign cpu_readdata = hit ? data_array[index] : 32'bx;

    // ------------------------------------------------------------------------
    // MAIN MEMORY & FSM LOGIC
    // ------------------------------------------------------------------------
    typedef enum logic { IDLE, FETCHING } state_t;
    state_t state, next_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            for (int i = 0; i < 16; i++) begin
                valid_array[i] <= 0;
                tag_array[i]   <= 0;
                data_array[i]  <= 0;
            end
        end else begin
            state <= next_state;
            
            // Write-Through on Hit
            // If we have a hit during a memory write, update the cache block immediately
            if (cpu_memwrite && hit) begin
                data_array[index] <= cpu_writedata;
            end
            
            // Cache Block Fill
            // When we finish fetching, populate the cache block with the new data
            if (state == FETCHING && dmem_ready) begin
                valid_array[index] <= 1'b1;
                tag_array[index]   <= tag;
                data_array[index]  <= cpu_memwrite ? cpu_writedata : dmem_readdata;
            end
        end
    end

    always_comb begin
        next_state     = state;
        mem_stall      = 0;
        dmem_addr      = cpu_addr;
        dmem_writedata = cpu_writedata;
        dmem_memwrite  = 0;
        dmem_memread   = 0;

        case (state)
            IDLE:
                if (miss) begin
                    // Freeze the CPU while we go to memory
                    mem_stall  = 1'b1;
                    next_state = FETCHING;
                    // If it's a write miss, we write to memory directly (write no-allocate or allocate, 
                    // here we allocate on write miss to simplify).
                    if (cpu_memwrite) begin
                        dmem_memwrite = 1'b1;
                    end
                    if (cpu_memread) begin
                        dmem_memread = 1'b1;
                    end
                end else if (hit && cpu_memwrite) begin
                    // Write-Through: also write to memory on a hit
                    dmem_memwrite = 1'b1;
                end
            
            FETCHING:
                begin
                    // We can un-stall the CPU on the next rising edge only when memory is ready
                    mem_stall  = 1'b1;
                    if (cpu_memwrite) dmem_memwrite = 1'b1;
                    if (cpu_memread) dmem_memread = 1'b1;
                    
                    if (dmem_ready) begin
                        next_state = IDLE;
                    end
                end
        endcase
    end

endmodule


`endif // CACHE_DIRECT_MAPPED_SV