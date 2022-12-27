`timescale 1ns/1ns

module receiver #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16, 
    parameter ADDR_WIDTH = $clog2(DEPTH)
) (
    input   clk,
    input   rst,
    output  ready,
    input   ready_test,
    input   valid,
    input   [DATA_WIDTH-1:0] data
);

    /* To receive data, ready_test should also be valid */
    reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];
    reg [ADDR_WIDTH:0] idx; 
    reg [DATA_WIDTH-1:0] debug_reg;
    assign ready = (idx != DEPTH) & ready_test; 

    always@(posedge clk or posedge rst) begin
        if(rst)begin
            idx <= 1'b0;
        end else begin
            if(ready_test & ready & valid) begin
                idx <= idx + 1'b1;
                mem[idx] <= data;
                debug_reg <= data;
            end else begin
                idx <= idx;
                mem[idx] <= mem[idx];
                debug_reg <= debug_reg;
            end
        end
    end 
endmodule
