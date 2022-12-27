`timescale 1ns/1ns

`define CLK_PERIOD 8
`define WIDTH 8 

module bubble_tb();

    reg clk = 0;
    always #(`CLK_PERIOD/2) clk = ~clk;
    
    wire[`WIDTH-1:0] data_w;
    wire valid_w;
    /* pipe reg */
    reg[`WIDTH-1:0] data_pipe;
    reg valid_pipe;
    reg pipe_cnt;

    reg rst;
    reg ready_test;
    reg valid_test;
    wire pipe_in;
    wire pipe_out;
    wire r_o;

    assign pipe_in = r_o & valid_w;
    assign pipe_out = ready & valid_pipe;
    assign r_o = ready | (~valid_pipe);

    always@(posedge clk or posedge rst) begin
        if(rst) begin
            valid_pipe <= 1'b0;;
        end else begin
            if(r_o) begin
                valid_pipe <= valid_w;
            end
        end
    end

    always@(posedge clk or posedge rst) begin
        if(rst) begin
            data_pipe <= `WIDTH'b0;
        end else begin
            if(r_o & valid_w) begin
                data_pipe <= data_w;
            end
        end
    end

    always@(posedge clk or posedge rst) begin
        if(rst) begin
            pipe_cnt <= 1'b0;
        end else begin
            case({pipe_in, pipe_out})
            2'b10: pipe_cnt <= pipe_cnt + 1;  
            2'b01: pipe_cnt <= pipe_cnt - 1;  
            default: pipe_cnt <= pipe_cnt;
            endcase
        end
    end

    sender # ( 
        .DATA_WIDTH(`WIDTH),
        .DEPTH(16)
    ) send (
        .clk(clk),
        .rst(rst),
        .ready(r_o),
        .valid(valid_w),
        .valid_test(valid_test),
        .data(data_w)
    );

    receiver # ( 
        .DATA_WIDTH(`WIDTH),
        .DEPTH(16)
    ) rec (
        .clk(clk),
        .rst(rst),
        .ready(ready),
        .ready_test(ready_test),
        .valid(valid_pipe),
        .data(data_pipe)
    );

    integer index;
    initial begin
        $readmemh("./data.hex", send.mem);
        for(index=0;index<16;index++)
            $display("%x ", send.mem[index]);

        $dumpfile("bubble_tb.vcd");
        $dumpvars(0, bubble_tb);

        pipe_cnt = 0;
        @(posedge clk);
        rst = 1;
        ready_test = 0;
        valid_test = 0;
        repeat(2) @(posedge clk);
        #1;rst = 0;
        valid_test = 1;
        repeat(4) @(posedge clk);
        #1;ready_test = 1;
        repeat(4) @(posedge clk);
        #1;valid_test = 0;
        repeat(4) @(posedge clk);

        $finish();
    end

endmodule
