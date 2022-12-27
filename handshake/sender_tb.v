`timescale 1ns/1ns

`define CLK_PERIOD 8
`define WIDTH 8 

module sender_tb();

    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    reg rst = 0;
    reg ready = 0;
    wire valid;
    wire [`WIDTH-1:0] data;
    integer index;

    sender # (
        .DATA_WIDTH(`WIDTH),
        .DEPTH(16)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .ready(ready),
        .valid(valid),
        .data(data)
    );

    initial begin
        $readmemh("./data.hex", DUT.mem);
        for(index=0;index<16;index++)
            $display("%x ", DUT.mem[index]);

        $dumpfile("sender_tb.vcd");
        $dumpvars(0,sender_tb);

        @(posedge clk);
        rst = 1;
        repeat(10) @(posedge clk);
        rst = 0;
        for(index=0;index<16;index++) begin
            repeat(10) @(posedge clk);
            #1;
            ready = 1;
            @(posedge clk);
            #1;
            ready = 0;
        end

        $finish();
    end
endmodule
