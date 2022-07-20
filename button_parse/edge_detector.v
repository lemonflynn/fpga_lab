`timescale 1ns/1ns

module edge_detector #(
  parameter WIDTH = 1
)(
  input clk,
  input [WIDTH-1:0] signal_in,
  output [WIDTH-1:0] edge_detect_pulse
);

  // TODO: implement a multi-bit edge detector that detects a rising edge of 'signal_in[x]'
  // and outputs a one-cycle pulse 'edge_detect_pulse[x]' at the next clock edge
  // Feel free to use as many number of registers you like
    reg [WIDTH-1:0] signal_latched;
    reg [WIDTH-1:0] edge_reg;
    assign edge_detect_pulse = edge_reg & signal_latched;

    always@(posedge clk) begin
        signal_latched <= signal_in;
        edge_reg <= signal_latched ^ signal_in;
    end

endmodule
