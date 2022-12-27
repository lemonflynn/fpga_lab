`timescale 1ns/1ps

`define CLOCK_PERIOD 10

module axi4_testbench();
    reg clk = 0;
    reg rst = 0;

    // Generate 100 MHz clock
    always #(`CLOCK_PERIOD/2) clk = ~clk;

    reg [31:0] write_data = 32'd0;
    reg write_data_valid = 0;
    wire write_data_ready;

    reg [1:0] write_addr = 2'd0;
    reg write_addr_valid = 0;
    wire write_addr_ready;

    wire [1:0] write_resp;
    wire write_resp_valid;
    reg write_resp_ready = 0; 

    reg [1:0] read_addr;
    reg read_addr_valid;
    wire read_addr_ready;

    wire [31:0] read_data;
    wire read_data_valid;
    reg read_data_ready;
    wire [1:0] read_resp;

    axi_mapped_registers axi_periph(
        .axi_clk(clk),
        .axi_rstn(rst),
        
        .axi_write_data(write_data),
        .write_data_valid(write_data_valid),
        .write_data_ready(write_data_ready),
        
        .axi_write_addr(write_addr),
        .write_addr_valid(write_addr_valid),
        .write_addr_ready(write_addr_ready),
        
        .axi_write_resp(write_resp),
        .write_resp_ready(write_resp_ready),
        .write_resp_valid(write_resp_valid),

        .axi_read_addr_i(read_addr),
        .read_addr_valid_i(read_addr_valid),
        .read_addr_ready_o(read_addr_ready),

        .axi_read_data_o(read_data),
        .read_data_valid_o(read_data_valid),
        .read_data_ready_i(read_data_ready),
        .read_resp_o(read_resp)
   );

    reg done = 0;
    initial begin
        $dumpfile("axi4-lite-tb.vcd");
        $dumpvars(0, axi4_testbench);

        fork
            begin

                $monitor("reg[0] %d\n", axi_periph.regs[0]);
                $monitor("reg[1] %d\n", axi_periph.regs[1]);
                $monitor("reg[2] %d\n", axi_periph.regs[2]);
                $monitor("reg[3] %d\n", axi_periph.regs[3]);
                rst = 0;
                write_data_valid = 0;
                write_addr_valid = 0;
                write_resp_ready = 0;
                read_addr = 0;
                read_addr_valid = 0;
                read_data_ready = 1;
                repeat(2) @(posedge clk);
                rst = 1;
                repeat(5) @(posedge clk);
                write_data = 32'd1234;
                #2; //setup time
                write_data_valid = 1;
                @(posedge clk);
                #2; //hold time
                write_data_valid = 0;

                repeat(2) @(posedge clk);
                write_addr = 2'd3;
                #2; //setup time
                write_addr_valid = 1;
                @(posedge clk);
                #2; //hold time
                write_addr_valid = 0;

                $display("start read");
                @(posedge clk);
                #2;read_addr = 2'd0;
                read_addr_valid = 1;
                @(posedge clk);
                #2;read_addr_valid = 0;
                repeat(5)@(posedge clk);

                #2;read_addr = 2'd3;
                read_addr_valid = 1;
                @(posedge clk);
                #2;read_addr_valid = 0;
                repeat(5)@(posedge clk);
                
            end
            begin
                repeat (25000) @(posedge clk);
                if (!done) begin
                    $display("Failure: timing out");
                    $finish();
                end
            end
        join
    end

endmodule
