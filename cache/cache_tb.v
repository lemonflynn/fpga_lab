`timescale 1ns/1ps

`define CLOCK_PERIOD 10

module cache_testbench();

reg clk = 0;
reg rst = 0;

reg cpu_req_valid, cpu_req_rw;
reg [31:0] cpu_req_addr, cpu_req_data;
wire cpu_data_ready;
wire [31:0] cpu_data;

/* signal between cache controller and memory */
wire mem_req_valid, mem_req_rw;
wire [31:0] mem_req_addr;
wire [127:0] mem_req_data;
wire mem_ready;
wire [127:0] mem_data;

// Generate 100 MHz clock
always #(`CLOCK_PERIOD/2) clk = ~clk;

dm_cache_controller cache_controller(
    .clk(clk),
    .rst(rst),
    /* cpu <-> cache */
    .cpu_req_valid_i(cpu_req_valid),
    .cpu_req_rw_i(cpu_req_rw),
    .cpu_req_addr_i(cpu_req_addr),
    .cpu_req_data_i(cpu_req_data),
    .cpu_data_ready_o(cpu_data_ready),
    .cpu_data_o(cpu_data),
    /* cache <-> mem */
    .mem_ready_i(mem_ready),
    .mem_data_i(mem_data),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_rw_o(mem_req_rw),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_data_o(mem_req_data)
); 

dummy_memory demo_mem (
    .clk(clk),
    .rst(rst),
    /* cache <-> mem */
    .mem_req_valid_i(mem_req_valid),
    .mem_req_rw_i(mem_req_rw),
    .mem_req_addr_i(mem_req_addr),
    .mem_req_data_i(mem_req_data),
    .mem_ready_o(mem_ready),
    .mem_data_o(mem_data)
);

integer index;
initial begin
    $dumpfile("cache_tb.vcd");
    $dumpvars(0, cache_testbench);

    $display("start test");

    $monitor("cpu_data_ready %d", cpu_data_ready);
    $monitor("->cpu_data  %x", cpu_data);

    $readmemh("./mem_data.hex", demo_mem.mem);
    for(index=0;index<16;index++)
        $display("%x ", demo_mem.mem[index]);
    
    $display("0x4096 %x ", demo_mem.mem[4096]);
    cpu_req_valid = 0;
    cpu_req_rw = 32'd0;
    cpu_req_addr = 32'd0;
    cpu_req_data = 0;
    rst = 1;

    repeat(10)@(posedge clk);
    #1;rst = 0;
    repeat(2)@(posedge clk);
    fork
        begin
            cpu_read(32'h8);
            cpu_read(32'h4);
            /* cause cache allocate */
            cpu_read(32'h4000);
            /* make cache dirty */
            cpu_write(32'h4000, 32'habcd);
            /* cause cache write back */
            cpu_write(32'h4, 32'h1234);
            /* read again */
            cpu_read(32'h4000);
            /* read again */
            cpu_read(32'h4);

            repeat(5)@(posedge clk);
            $finish();
        end
        begin
            repeat(1000)@(posedge clk);
            $display("timeout");
            $finish();
        end
    join
end

task cpu_read(input [31:0] addr);
    begin
        #1;
        cpu_req_addr = addr;
        cpu_req_valid = 1;
        $display("cpu read 0x%h", addr);
        @(posedge clk);
        #1;cpu_req_valid = 0;
        while(cpu_data_ready == 1'b0)@(posedge clk);
        repeat(2)@(posedge clk);
    end
endtask

task cpu_write(input [31:0] addr, input [31:0] data);
    begin
        #1;
        cpu_req_addr = addr;
        cpu_req_rw = 1;
        cpu_req_data = data;
        cpu_req_valid = 1;
        $display("cpu write 0x%h > 0x%h", data, addr);
        @(posedge clk);
        #1;
        cpu_req_valid = 0;
        cpu_req_rw = 0;
        while(cpu_data_ready == 1'b0)@(posedge clk);
        repeat(2)@(posedge clk);
    end
endtask

endmodule
