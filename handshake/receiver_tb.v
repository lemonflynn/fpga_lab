`timescale 1ns/1ns

`define CLK_PERIOD 8
`define WIDTH 8 

module receiver_tb();

    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;

    reg rst = 0;
    wire ready;
    reg valid;
    reg [`WIDTH-1:0] data;
    integer index;

    receiver # (
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
        $readmemh("./receiver.hex", DUT.mem);
        for(index=0;index<16;index++)
            $display("%x ", DUT.mem[index]);

        $dumpfile("receiver_tb.vcd");
        $dumpvars(0, receiver_tb);
        $monitor("index %d\n", DUT.idx);

        data = 0;
        @(posedge clk);
        rst = 1;
        repeat(10) @(posedge clk);
        rst = 0;
        for(index=0;index<18;index++) begin
            repeat(10) @(posedge clk);
            #1;
            valid = 1;
            data = data + 1;
            @(posedge clk);
            #1;
            valid = 0;
        end

        for(index=0;index<16;index++)
            $display("%x ", DUT.mem[index]);
        $finish();
    end
endmodule
