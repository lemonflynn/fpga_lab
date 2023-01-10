module dm_cache_data(
    input           clk,
    input [9:0]     data_req_index,
    input           data_req_we,
    input [127:0]   data_write,
    output[127:0]   data_read
);

/* cache size is 16k */
reg [127:0] data_mem[0:1023];

integer i;
initial begin
    for (i=0; i<1024; i++)
        data_mem[i] = 128'b0; 
end 

assign data_read = data_mem[data_req_index];

always@(posedge(clk)) begin
    if (data_req_we)
        data_mem[data_req_index] <= data_write;
end 

endmodule
