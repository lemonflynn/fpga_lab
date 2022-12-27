module axi_mapped_registers(
    input axi_clk,
    input axi_rstn,
    
    input [31:0] axi_write_data,
    input write_data_valid,
    output write_data_ready,
    
    input [1:0] axi_write_addr,
    input write_addr_valid,
    output write_addr_ready,
    
    output [1:0] axi_write_resp,
    input write_resp_ready,
    output write_resp_valid,
    
    input [1:0] axi_read_addr_i,
    input read_addr_valid_i,
    output read_addr_ready_o,

    output[31:0] axi_read_data_o,
    output read_data_valid_o,
    input read_data_ready_i,
    output [1:0] read_resp_o
);

reg[31:0] regs[3:0];
wire[31:0] write_data;
wire[1:0] write_addr;
wire write_en;
wire[31:0] debug_d0;
wire[31:0] debug_d1;
wire[31:0] debug_d2;
wire[31:0] debug_d3;

//read logic
wire read_en;
wire[1:0] read_addr;
reg[31:0] read_data;
reg read_data_en;

assign debug_d0 = regs[0];
assign debug_d1 = regs[1];
assign debug_d2 = regs[2];
assign debug_d3 = regs[3];

axi_write_logic axi_inst(
    .axi_clk(axi_clk),
    .rstn(axi_rstn), //axi is reset low

    .write_data(axi_write_data),
    .write_data_valid(write_data_valid),
    .write_data_ready(write_data_ready),

    .write_addr(axi_write_addr),
    .write_addr_valid(write_addr_valid),
    .write_addr_ready(write_addr_ready),

    .write_resp_ready(write_resp_ready),
    .write_resp_valid(write_resp_valid),
    .write_resp(axi_write_resp),

    .read_addr_i(axi_read_addr_i),
    .read_addr_valid_i(read_addr_valid_i),
    .read_addr_ready_o(read_addr_ready_o),

    .read_data_o(axi_read_data_o),
    .read_data_valid_o(read_data_valid_o),
    .read_data_ready_i(read_data_ready_i),
    .read_resp_o(read_resp_o),

    .data_out(write_data), //data output to external logic
    .addr_out(write_addr), //address output to external logic
    .data_valid(write_en),

    .read_addr_to_user_o(read_addr),
    .read_addr_valid_to_user_o(read_en),

    .read_data_user_valid_i(read_data_en),
    .read_data_from_user_i(read_data)
);


integer i;
always@(posedge axi_clk)
begin
    if(~axi_rstn) begin
        for(i=0;i<4;i++)
            regs[i] <= 32'd0;
    end else if(write_en) begin
        regs[write_addr] <= write_data;
    end else if(read_en) begin
        read_data <= regs[read_addr];
        read_data_en <= 1'd1;
    end else begin
        read_data <= 32'd0;
        read_data_en <= 1'd0;
    end
end

endmodule
