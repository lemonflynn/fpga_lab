`timescale 1ns/1ns

module dummy_memory(
    input clk,
    input rst,
    /* cache <-> mem */
    input          mem_req_valid_i,
    input          mem_req_rw_i,
    input [31:0]   mem_req_addr_i,
    input [127:0]  mem_req_data_i,
    output reg     mem_ready_o,
    output [127:0] mem_data_o
);

//4 * 8k = 32k 
reg[31:0] mem[0:8191];
wire [29:0] word_addr;

assign word_addr = mem_req_addr_i[31:2];

assign mem_data_o = {mem[word_addr+3], mem[word_addr+2], mem[word_addr+1], mem[word_addr]};

always@(posedge clk or rst) begin
    if(rst) begin
        mem_ready_o <= 1'b0;
    end if(mem_req_valid_i) begin
        /* write request */
        if(mem_req_rw_i)
            {mem[word_addr+3], mem[word_addr+2], mem[word_addr+1], mem[word_addr]} <= mem_req_data_i;

        mem_ready_o <= 1'b1;
    end else begin
        mem_ready_o <= 1'b0;
    end
end

endmodule
