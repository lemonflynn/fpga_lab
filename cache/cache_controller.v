`timescale 1ns/1ns
`define MSB 31
`define LSB 14

module dm_cache_controller (
    input clk,
    input rst,
    /* cpu <-> cache */
    input               cpu_req_valid_i,
    input               cpu_req_rw_i,
    input [31:0]        cpu_req_addr_i,
    input [31:0]        cpu_req_data_i,
    output reg          cpu_data_ready_o,
    output reg [31:0]   cpu_data_o,
    /* cache <-> mem */
    input               mem_ready_i,
    input  [127:0]      mem_data_i,
    output reg          mem_req_valid_o,
    output reg          mem_req_rw_o,
    output reg [31:0]   mem_req_addr_o,
    output reg [127:0]  mem_req_data_o
);

parameter idle          = 2'b00;
parameter compare_tag   = 2'b01;
parameter allocate      = 2'b10;
parameter write_back    = 2'b11;

wire [9:0] req_index;

reg [31:0] cpu_req_addr_latch;
reg [31:0] cpu_req_data_latch;
reg cpu_req_rw_latch;

//cache tag signal
reg tag_req_we, tag_write_valid, tag_write_dirty;
reg [`MSB-`LSB:0] tag_write_tag;
wire tag_read_valid, tag_read_dirty;
wire [`MSB-`LSB:0] tag_read_tag;

//cache data signal
reg         data_req_we;
reg[127:0]  data_write;
wire[127:0] data_read;

//FSM
reg[1:0] state, next_state;

assign req_index = cpu_req_addr_latch[13:4];

dm_cache_tag # (
    .TAGMSB(`MSB),
    .TAGLSB(`LSB)
) cache_tag (
    .clk(clk),
    .tag_req_index(req_index),
    .tag_req_we(tag_req_we),
    .tag_write_valid(tag_write_valid),
    .tag_write_dirty(tag_write_dirty),
    .tag_write_tag(tag_write_tag),
    .tag_read_valid(tag_read_valid),
    .tag_read_dirty(tag_read_dirty),
    .tag_read_tag(tag_read_tag)
);

dm_cache_data cache_data (
    .clk(clk),
    .data_req_index(req_index),
    .data_req_we(data_req_we),
    .data_write(data_write),
    .data_read(data_read)
);

always@(posedge clk or rst) begin
    if(rst)
        state <= idle;
    else
        state <= next_state;
end

always@(*) begin
    case(state)
    idle: begin
        if(cpu_req_valid_i)
            next_state = compare_tag; 
    end
    compare_tag: begin
        /* cache hit */
        if(cpu_req_addr_latch[`MSB:`LSB] == tag_read_tag && tag_read_valid) begin
            next_state = idle;
        end else begin
        /* cache miss */
            if(tag_read_valid == 1'b0 || tag_read_dirty == 1'b0)
                next_state = allocate; //compulsory miss or miss with clean block
            else
                next_state = write_back; //miss with dirty line
        end
    end
    allocate: begin
        if(mem_ready_i) next_state = compare_tag; 
    end
    write_back: begin
        if(mem_ready_i) next_state = allocate;
    end
    default: next_state = idle;
    endcase
end

always@(posedge clk or rst) begin
    if(rst) begin
        cpu_data_ready_o    <= 1'b0;
        tag_req_we          <= 1'b0;
        data_req_we         <= 1'b0;
        data_write          <= 128'b0;
        mem_req_valid_o     <= 1'b0;
        mem_req_rw_o        <= 1'b0;
    end else begin
        /* inital signal */
        cpu_data_ready_o    <= 1'b0;
        tag_req_we          <= 1'b0;
        data_req_we         <= 1'b0;
        mem_req_valid_o     <= 1'b0;
        mem_req_rw_o        <= 1'b0;
        /* since cache line is 128 bits, that's 16 bytes, 
         * memory access is 16 bytes aligned, so lower 4 bits is zero
         */
        mem_req_addr_o      <= {cpu_req_addr_latch[31:4], 4'b0};
        mem_req_data_o      <= data_read;

        case(cpu_req_addr_latch[3:2])
            2'b00: data_write <= {data_read[127:32], cpu_req_data_latch};
            2'b01: data_write <= {data_read[127:64], cpu_req_data_latch, data_read[31:0]};
            2'b10: data_write <= {data_read[127:96], cpu_req_data_latch, data_read[63:0]};
            2'b11: data_write <= {cpu_req_data_latch, data_read[95:0]};
        endcase

        case (state)
        idle: begin
            if(cpu_req_valid_i) begin
                cpu_req_rw_latch <= cpu_req_rw_i;
                cpu_req_addr_latch <= cpu_req_addr_i;
                cpu_req_data_latch <= cpu_req_data_i;
            end
        end
        compare_tag: begin
            if(cpu_req_addr_latch[`MSB:`LSB] == tag_read_tag && tag_read_valid) begin
                /* cache hit */
                cpu_data_ready_o <= 1'b1;
                if(data_req_we) begin
                /* we are at allocate stage one clock cycle before, and we are updating
                 * cache line at this clock cycle, date in data_read is stale
                 */
                    if(cpu_req_rw_latch) begin
                        /* if cpu is writing data, just return  cpu_req_data */
                        cpu_data_o <= cpu_req_data_i;
                    end else begin
                        case(cpu_req_addr_latch[3:2])
                            2'b00: cpu_data_o <= data_write[31:0];
                            2'b01: cpu_data_o <= data_write[63:32];
                            2'b10: cpu_data_o <= data_write[95:64];
                            2'b11: cpu_data_o <= data_write[127:96];
                        endcase
                    end
                end else begin
                    case(cpu_req_addr_latch[3:2])
                        2'b00: cpu_data_o <= data_read[31:0];
                        2'b01: cpu_data_o <= data_read[63:32];
                        2'b10: cpu_data_o <= data_read[95:64];
                        2'b11: cpu_data_o <= data_read[127:96];
                    endcase
                end
                if(cpu_req_rw_latch) begin
                    data_req_we <= 1'b1;
                    tag_req_we <= 1'b1;
                    tag_write_tag <= tag_read_tag;
                    tag_write_valid <= 1'b1;
                    /*cache line is dirty*/
                    tag_write_dirty <= 1'b1;
                end
            end else begin
                /* cache miss */
                tag_req_we <= 1'b1;
                tag_write_tag <= cpu_req_addr_latch[`MSB:`LSB];
                tag_write_valid <= 1'b1;
                /* cache line is dirty if write */
                tag_write_dirty <= cpu_req_rw_latch;
                /* generate memory request */
                mem_req_valid_o <= 1'b1;
                /* cache line is valid and dirty, need to write back to memory */
                if(tag_read_valid & tag_read_dirty) begin
                    mem_req_rw_o <= 1'b1;
                    mem_req_addr_o <= {tag_read_tag, cpu_req_addr_latch[`LSB-1:4], 4'b0};
                end
            end
        end
        allocate: begin
            if(mem_ready_i) begin 
                data_req_we <= 1'b1;
                data_write <= mem_data_i;
            end
        end
        write_back: begin
            /* dirty cache line has been write back, fetch new data from mem into cache line*/
            if(mem_ready_i)
                mem_req_valid_o <= 1'b1;
        end
        default: begin
            cpu_data_ready_o    <= 1'b0;
            tag_req_we          <= 1'b0;
            data_req_we         <= 1'b0;
            mem_req_valid_o     <= 1'b0;
            mem_req_rw_o        <= 1'b0;
        end
        endcase
    end
end

endmodule
