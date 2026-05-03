`ifndef CACHE_FULLY_ASSOCIATIVE_SV
`define CACHE_FULLY_ASSOCIATIVE_SV

module cache_fully_associative (
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
    logic        valid_array [15:0];
    logic [29:0] tag_array   [15:0];
    logic [31:0] data_array  [15:0];
    
    // Round-robin replacement pointer (0 to 15)
    logic [3:0]  replace_ptr;

    // ------------------------------------------------------------------------
    // ADDRESS PARSING
    // ------------------------------------------------------------------------
    logic [29:0] tag;
    assign tag = cpu_addr[31:2];

    // ------------------------------------------------------------------------
    // HIT / MISS LOGIC (Content Addressable Memory - CAM)
    // ------------------------------------------------------------------------
    logic hit;
    logic miss;
    logic [3:0] hit_index; // Which block matched?

    always_comb begin
        hit = 1'b0;
        hit_index = 4'b0;
        // Parallel search across all 16 blocks
        for (int i = 0; i < 16; i++) begin
            if (valid_array[i] && (tag_array[i] == tag)) begin
                hit = 1'b1;
                hit_index = i[3:0];
            end
        end
    end
    
    assign miss = (cpu_memread || cpu_memwrite) && !hit;
    assign cpu_readdata = hit ? data_array[hit_index] : 32'bx;

    // ------------------------------------------------------------------------
    // MAIN MEMORY & FSM LOGIC
    // ------------------------------------------------------------------------
    typedef enum logic { IDLE, FETCHING } state_t;
    state_t state, next_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            replace_ptr <= 4'b0;
            for (int i = 0; i < 16; i++) begin
                valid_array[i] <= 0;
                tag_array[i]   <= 0;
                data_array[i]  <= 0;
            end
        end else begin
            state <= next_state;
            
            // Write-Through on Hit
            if (cpu_memwrite && hit) begin
                data_array[hit_index] <= cpu_writedata;
            end
            
            if (state == FETCHING && dmem_ready) begin
                // Allocate block at the replacement pointer
                valid_array[replace_ptr] <= 1'b1;
                tag_array[replace_ptr]   <= tag;
                data_array[replace_ptr]  <= cpu_memwrite ? cpu_writedata : dmem_readdata;
                
                // Advance the replacement pointer (FIFO policy)
                replace_ptr <= replace_ptr + 1;
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


`endif // CACHE_FULLY_ASSOCIATIVE_SV