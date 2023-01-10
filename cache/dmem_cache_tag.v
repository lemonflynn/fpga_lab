module dm_cache_tag #(
    parameter   TAGMSB= 31, 
    parameter   TAGLSB= 14 
)(
    input           clk,
    input [9:0]     tag_req_index,
    input           tag_req_we,
    input           tag_write_valid,
    input           tag_write_dirty,
    input [TAGMSB-TAGLSB:0]   tag_write_tag,
    output          tag_read_valid,
    output          tag_read_dirty,
    output [TAGMSB-TAGLSB:0]  tag_read_tag
);

parameter TAG_WIDTH = TAGMSB - TAGLSB + 2;

reg [TAG_WIDTH:0] tag_mem[0:1023];
wire [TAG_WIDTH:0] tag_read;

integer i;

initial begin
    for (i=0; i<1024; i++) begin
        tag_mem[i] = {TAG_WIDTH{1'b0}};
    end
end

assign {tag_read_valid, tag_read_dirty, tag_read_tag} = tag_mem[tag_req_index];

always@(posedge clk) begin
    if (tag_req_we)
        tag_mem[tag_req_index] <= {tag_write_valid, tag_write_dirty, tag_write_tag};
end

endmodule
