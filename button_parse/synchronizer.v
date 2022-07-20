`timescale 1ns/1ns

module synchronizer #(parameter WIDTH = 1) (
  input [WIDTH-1:0] async_signal,
  input clk,
  output [WIDTH-1:0] sync_signal
);
  // TODO: Create your 2 flip-flop synchronizer here
  // This module takes in a vector of WIDTH-bit asynchronous
  // (from different clock domain or not clocked, such as button press) signals
  // and should output a vector of WIDTH-bit synchronous signals
  // that are synchronized to the input clk

    reg[WIDTH-1:0] reg_first, reg_second;
    assign sync_signal = reg_second;
    always@(posedge clk) begin
        reg_first <= async_signal;
        reg_second <= reg_first;
    end

endmodule
