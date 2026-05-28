module cache_controller (

    input clk,
    input rst,

    // CPU interface
    input [31:0] cpu_addr,
    input [31:0] cpu_write_data,

    input cpu_read,
    input cpu_write,

    output reg [31:0] cpu_read_data,
    output reg cpu_ready,

    // Memory interface
    output reg [31:0] mem_addr,
    output reg [31:0] mem_write_data,

    output reg mem_read,
    output reg mem_write,

    input [31:0] mem_read_data,
    input mem_ready

);

    // =====================================================
    // CACHE PARAMETERS
    // =====================================================

    parameter NUM_SETS = 4;
    parameter NUM_WAYS = 2;

    // =====================================================
    // CACHE STORAGE
    // =====================================================

    reg [31:0] data_array [0:NUM_SETS-1][0:NUM_WAYS-1];

    reg [25:0] tag_array [0:NUM_SETS-1][0:NUM_WAYS-1];

    reg valid_array [0:NUM_SETS-1][0:NUM_WAYS-1];

    reg dirty_array [0:NUM_SETS-1][0:NUM_WAYS-1];

    // LRU tracking
    reg lru [0:NUM_SETS-1];

    // =====================================================
    // ADDRESS BREAKDOWN
    // =====================================================

    wire [1:0] index;
    wire [25:0] tag;

    assign index = cpu_addr[5:4];

    assign tag = cpu_addr[31:6];

    // =====================================================
    // HIT DETECTION
    // =====================================================

    wire hit_way0;
    wire hit_way1;

    assign hit_way0 =
            valid_array[index][0] &&
            (tag_array[index][0] == tag);

    assign hit_way1 =
            valid_array[index][1] &&
            (tag_array[index][1] == tag);

    wire cache_hit;
    wire victim_dirty;

    assign cache_hit = hit_way0 || hit_way1;
    assign victim_dirty =

        dirty_array[index][lru[index]];

    wire [31:0] hit_data;

    assign hit_data =

            (hit_way0) ? data_array[index][0] :

            (hit_way1) ? data_array[index][1] :

            32'b0;

    // =====================================================
    // CACHE FSM
    // =====================================================

    parameter IDLE      = 2'b00;
    parameter MEM_READ  = 2'b01;
    parameter REFILL    = 2'b10;
    parameter WRITE_BACK  = 2'b11;

    reg [1:0] state;

    reg [1:0] replace_way;

    reg [31:0] pending_addr;

    // =====================================================
    // CACHE ACCESS LOGIC
    // =====================================================

    integer i;
    integer j;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            cpu_ready <= 0;

            cpu_read_data <= 0;

            mem_read <= 0;
            mem_write <= 0;

            mem_addr <= 0;
            mem_write_data <= 0;

            state <= IDLE;

            replace_way <= 0;

            pending_addr <= 0;

            // Initialize cache state
            for (i = 0; i < NUM_SETS; i = i + 1) begin

                lru[i] <= 0;

                for (j = 0; j < NUM_WAYS; j = j + 1) begin

                    valid_array[i][j] <= 0;

                    dirty_array[i][j] <= 0;

                    data_array[i][j] <= 0;

                    tag_array[i][j] <= 0;

                end
            end
        end

        else begin

            cpu_ready <= 0;

            mem_read <= 0;

            mem_write <= 0;

            case (state)

                // =================================================
                // IDLE STATE
                // =================================================

                IDLE: begin

                    // =============================================
                    // CPU READ
                    // =============================================

                    if (cpu_read) begin

                        // =========================================
                        // CACHE HIT
                        // =========================================

                        if (cache_hit) begin

                            cpu_read_data <= hit_data;

                            cpu_ready <= 1;

                            // Update LRU
                            if (hit_way0)
                                lru[index] <= 1;

                            else if (hit_way1)
                                lru[index] <= 0;

                        end

                        // =========================================
                        // CACHE MISS
                        // =========================================

                        else begin

                            pending_addr <= cpu_addr;

                            replace_way <= lru[index];

                            // =====================================
                            //DIRTY VICTIM
                            // =====================================

                            if (victim_dirty) begin

                                mem_addr <= {

                                    tag_array[index][lru[index]],

                                    index,

                                    4'b0000

                                };

                                mem_write_data <=

                                    data_array[index][lru[index]];

                                mem_write <= 1;

                                state <= WRITE_BACK;

                            end

                            // =====================================
                            // CLEAN VICTIM
                            // =====================================

                            else begin

                                mem_addr <= cpu_addr;

                                mem_read <= 1;

                                state <= MEM_READ;

                            end

                        end
                    end

                    // =============================================
                    // CPU WRITE
                    // =============================================

                    if (cpu_write) begin

                        // =========================================
                        // WRITE HIT
                        // =========================================

                        if (cache_hit) begin

                            // Write into correct way
                            if (hit_way0) begin

                                data_array[index][0]

                                    <= cpu_write_data;

                                dirty_array[index][0]

                                    <= 1;

                                lru[index] <= 1;

                            end

                            else if (hit_way1) begin

                                data_array[index][1]

                                    <= cpu_write_data;

                                dirty_array[index][1]

                                    <= 1;

                                lru[index] <= 0;

                            end

                            cpu_ready <= 1;

                        end
                    end
                end
                // =================================================
                // WRITE BACK DIRTY LINE
                // =================================================

                WRITE_BACK: begin

                    mem_write <= 1;

                    if (mem_ready) begin

                        mem_addr <= pending_addr;

                        mem_read <= 1;

                        state <= MEM_READ;

                    end

                end
                // =================================================
                // WAIT FOR MEMORY
                // =================================================

                MEM_READ: begin

                    mem_read <= 1;

                    if (mem_ready) begin

                        state <= REFILL;

                    end
                end

                // =================================================
                // REFILL CACHE
                // =================================================

                REFILL: begin

                    data_array[
                        pending_addr[5:4]
                    ][replace_way]

                        <= mem_read_data;

                    tag_array[
                        pending_addr[5:4]
                    ][replace_way]

                        <= pending_addr[31:6];

                    valid_array[
                        pending_addr[5:4]
                    ][replace_way]

                        <= 1;

                    dirty_array[
                        pending_addr[5:4]
                    ][replace_way]

                        <= 0;

                    cpu_read_data <= mem_read_data;

                    cpu_ready <= 1;

                    // Update LRU
                    lru[pending_addr[5:4]]

                        <= ~replace_way;

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule