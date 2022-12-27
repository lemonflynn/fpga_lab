`timescale 1ns/1ns

module sender #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
) (
    input clk,
    input rst,
    input ready,
    output valid,
    input valid_test,
    output [DATA_WIDTH-1:0] data
);

    reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];
    reg [ADDR_WIDTH:0] idx; 
    assign valid = (idx != DEPTH) & valid_test; 
    assign data = mem[idx];

    always@(posedge clk or posedge rst) begin
        if(rst)begin
            idx <= 1'b0;
        end else begin
            if(ready & valid & valid_test)
                idx <= idx + 1'b1;
            else
                idx <= idx;
        end
    end
endmodule
