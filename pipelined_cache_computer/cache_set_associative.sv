`ifndef CACHE_SET_ASSOCIATIVE_SV
`define CACHE_SET_ASSOCIATIVE_SV

//////////////////////////////////////////////////////////////////////////////////
// The Cooper Union
// ECE 251 Spring 2026
// Engineer: Prof Rob Marano
// 
//     Create Date: 2026-04-23
//     Module Name: cache_set_associative
//     Description: 16-word 2-Way Set-Associative Cache
//                  - 1 word (4 bytes) per block.
//                  - 16 blocks total, 8 sets (2 blocks per set).
//                  - 32-bit Address Breakdown:
//                      Offset: 2 bits (addr[1:0])
//                      Index:  3 bits (8 sets, addr[4:2])
//                      Tag:    27 bits (addr[31:5])
//                  - Uses LRU (Least Recently Used) replacement policy per set.
//////////////////////////////////////////////////////////////////////////////////

module cache_set_associative (
    input  logic        clk,
    input  logic        reset,
    // Interface to CPU
    input  logic [31:0] cpu_addr,
    input  logic [31:0] cpu_writedata,
    input  logic        cpu_memwrite,
    input  logic        cpu_memread,
    output logic [31:0] cpu_readdata,
    output logic        mem_stall,
    
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
    // 8 sets, 2 ways per set.
    logic        valid_array [7:0][1:0];
    logic [26:0] tag_array   [7:0][1:0];
    logic [31:0] data_array  [7:0][1:0];
    
    // 1-bit LRU tracker per set. 
    // 0 = Way 0 is LRU (evict Way 0)
    // 1 = Way 1 is LRU (evict Way 1)
    logic        lru_array   [7:0];

    // ------------------------------------------------------------------------
    // ADDRESS PARSING
    // ------------------------------------------------------------------------
    logic [2:0]  index;
    logic [26:0] tag;
    assign index = cpu_addr[4:2];
    assign tag   = cpu_addr[31:5];

    // ------------------------------------------------------------------------
    // HIT / MISS LOGIC (CAM search within the Set)
    // ------------------------------------------------------------------------
    logic hit_way0, hit_way1;
    logic hit;
    logic miss;
    logic hit_way_index; // 0 for Way 0, 1 for Way 1

    assign hit_way0 = valid_array[index][0] && (tag_array[index][0] == tag);
    assign hit_way1 = valid_array[index][1] && (tag_array[index][1] == tag);
    
    assign hit = hit_way0 || hit_way1;
    assign hit_way_index = hit_way1; // If hit_way1 is true, it's Way 1. Else 0.
    
    assign miss = (cpu_memread || cpu_memwrite) && !hit;
    assign cpu_readdata = hit ? data_array[index][hit_way_index] : 32'bx;

    // ------------------------------------------------------------------------
    // MAIN MEMORY & FSM LOGIC
    // ------------------------------------------------------------------------
    typedef enum logic { IDLE, FETCHING } state_t;
    state_t state, next_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            for (int i = 0; i < 8; i++) begin
                lru_array[i] <= 1'b0;
                valid_array[i][0] <= 0;
                valid_array[i][1] <= 0;
            end
        end else begin
            state <= next_state;
            
            // Write-Through on Hit
            if (cpu_memwrite && hit) begin
                data_array[index][hit_way_index] <= cpu_writedata;
            end
            
            // Update LRU on Hit
            if ((cpu_memread || cpu_memwrite) && hit) begin
                // If we hit Way 0, Way 1 becomes LRU (1)
                // If we hit Way 1, Way 0 becomes LRU (0)
                lru_array[index] <= ~hit_way_index;
            end
            
            if (state == FETCHING && dmem_ready) begin
                // Allocate block at the LRU way
                valid_array[index][lru_array[index]] <= 1'b1;
                tag_array[index][lru_array[index]]   <= tag;
                data_array[index][lru_array[index]]  <= cpu_memwrite ? cpu_writedata : dmem_readdata;
                
                // After allocating, update LRU so the OTHER way is now LRU
                lru_array[index] <= ~lru_array[index];
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
                    mem_stall  = 1'b1;
                    next_state = FETCHING;
                    if (cpu_memwrite) dmem_memwrite = 1'b1;
                    if (cpu_memread) dmem_memread = 1'b1;
                end else if (hit && cpu_memwrite) begin
                    dmem_memwrite = 1'b1;
                end
            FETCHING:
                begin
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


`endif // CACHE_SET_ASSOCIATIVE_SV