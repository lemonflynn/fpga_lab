module axi_write_logic(
	input axi_clk,
	input rstn, //axi is reset low

    //write logic
	input [1:0] write_addr,
	input write_addr_valid,
	output reg write_addr_ready,

	input [31:0] write_data,
	input write_data_valid,
	output reg write_data_ready,

    input write_resp_ready,
    output reg write_resp_valid,
    output [1:0] write_resp,

    //read logic
    input [1:0] read_addr_i,
    input read_addr_valid_i,
    output reg read_addr_ready_o,

    output [31:0] read_data_o,
    output read_data_valid_o,
    input read_data_ready_i,
    output [1:0] read_resp_o,

    output [31:0] data_out, //data output to external logic
    output [1:0] addr_out,  //address output to external logic
    output data_valid,		//signal indicating output data and address are valid

    /* we don't need valid/ready signal here, axi4-lite would be used by fifo or ram */
    output [1:0] read_addr_to_user_o,
    output reg read_addr_valid_to_user_o,

    input read_data_user_valid_i,
    input [31:0] read_data_from_user_i
);

//flip flops for latching data, addr is 4 bytes aligned
reg [31:0] data_latch;
reg [1:0] addr_latch;
reg [1:0] addr_latch_delay;
reg data_done;
reg addr_done;

reg [31:0] read_data_latch;
reg [1:0] read_addr_latch;
reg read_data_latched;

assign data_out = data_latch;
assign addr_out = addr_latch;
/* this signal only keep assert for one clock, this could cause problem */
assign data_valid = data_done & addr_done;

assign read_addr_to_user_o = read_addr_latch;
assign read_data_o = read_data_latch;
assign read_data_valid_o = read_data_latched;

always@(posedge axi_clk)
begin
    addr_latch_delay <= addr_latch;
end

/* write address handshake*/
always@(posedge axi_clk)
begin
    if(~rstn | (write_addr_valid & write_addr_ready))
        write_addr_ready <= 0;
    else
        write_addr_ready <= 1;
end

/* write data handshake*/
always@(posedge axi_clk)
begin
    if(~rstn | (write_data_valid & write_data_ready))
        write_data_ready <= 0;
    else
        write_data_ready <= 1;
end

always@(posedge axi_clk)
begin
    if(~rstn) begin
        data_latch <= 32'd0;
        addr_latch <= 2'd0;
    end else begin
        if(write_data_valid & write_data_ready)
            data_latch <= write_data;

        if(write_addr_valid & write_addr_ready);
            addr_latch <= write_addr;
    end
end

always@(posedge axi_clk)
begin
    if(~rstn | (data_done & addr_done)) begin
        data_done <= 1'd0;
        addr_done <= 1'd0;
    end else begin
        if(write_data_valid & write_data_ready)
            data_done <= 1'd1;
        if(write_addr_valid & write_addr_ready)
            addr_done <= 1'd1;
    end
end

assign write_resp = 2'd0; // always indicate OKAY status for write
always@(posedge axi_clk)
begin
    if(~rstn | (write_resp_ready & write_resp_valid))
        write_resp_valid <= 1'd0;
    else if(data_done & addr_done)
        write_resp_valid <= 1'd1;
end

//read logic start here.
always@(posedge axi_clk)
begin
    if(~rstn | (read_addr_valid_i & read_addr_ready_o))
        read_addr_ready_o <= 0;
    else
        read_addr_ready_o <= 1;
end

always@(posedge axi_clk)
begin
    if(~rstn) begin
        read_addr_latch <= 2'd0 ;
        read_addr_valid_to_user_o <= 1'd0;
    end else if(read_addr_valid_i & read_addr_ready_o) begin
        read_addr_latch <= read_addr_i;
        read_addr_valid_to_user_o <= 1'd1; // valid only keep high for 1 clock.
    end else begin
        read_addr_latch <= 2'd0 ;
        read_addr_valid_to_user_o <= 1'd0;
    end
end

always@(posedge axi_clk)
begin
    if(~rstn) begin
        read_data_latch <= 32'd0;
        read_data_latched <= 1'd0;
    end else if(read_data_user_valid_i) begin
        read_data_latch <= read_data_from_user_i;
        read_data_latched <= 1'd1;
    end else if(read_data_latched & read_data_ready_i) begin
        read_data_latch <= 32'd0;
        read_data_latched <= 1'd0;
    end
end

endmodule
