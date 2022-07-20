
module debouncer #(
  parameter WIDTH              = 1,
  parameter SAMPLE_CNT_MAX     = 25000,
  parameter PULSE_CNT_MAX      = 150,
  parameter WRAPPING_CNT_WIDTH = $clog2(SAMPLE_CNT_MAX) + 1,
  parameter SAT_CNT_WIDTH      = $clog2(PULSE_CNT_MAX) + 1
) (
  input clk,
  input [WIDTH-1:0] glitchy_signal,
  output [WIDTH-1:0] debounced_signal
);

    // TODO: fill in neccesary logic to implement the wrapping counter and the saturating counters
    // Some initial code has been provided to you, but feel free to change it however you like
    // One wrapping counter is required
    // One saturating counter is needed for each bit of debounced_signal
    // You need to think of the conditions for reseting, clock enable, etc. those registers
    // Refer to the block diagram in the spec

    wire [WRAPPING_CNT_WIDTH-1:0] wrapping_cnt_value;
    wire [WRAPPING_CNT_WIDTH-1:0] wrapping_cnt_next;
    wire wrapping_cnt_rst;

    REGISTER_R #(.N(WRAPPING_CNT_WIDTH), .INIT(0)) wrapping_cnt(
      .q(wrapping_cnt_value),
      .d(wrapping_cnt_next),
      .rst(wrapping_cnt_rst),
      .clk(clk));

    assign wrapping_cnt_rst = (wrapping_cnt_value == SAMPLE_CNT_MAX);
    assign wrapping_cnt_next = wrapping_cnt_value + 1;

    wire [SAT_CNT_WIDTH-1:0] sat_cnt_value[WIDTH-1:0];
    wire [SAT_CNT_WIDTH-1:0] sat_cnt_next[WIDTH-1:0];
    wire sat_cnt_rst[WIDTH-1:0];
    wire sat_cnt_ce[WIDTH-1:0];

    genvar i;
    generate for (i = 0; i < WIDTH; i = i + 1) begin
      REGISTER_R_CE #(.N(SAT_CNT_WIDTH), .INIT(0)) sat_cnt (
        .q(sat_cnt_value[i]),
        .d(sat_cnt_next[i]),
        .rst(sat_cnt_rst[i]),
        .ce(sat_cnt_ce[i]),
        .clk(clk));
    end
    endgenerate

    generate for (i = 0; i < WIDTH; i = i + 1) begin
      assign debounced_signal[i] = (sat_cnt_value[i] == PULSE_CNT_MAX);

      assign sat_cnt_next[i] = glitchy_signal[i] ? (sat_cnt_value[i] + 1) : {SAT_CNT_WIDTH{1'b0}};
      /* reset sat counter while glitchy_signal is 0 */
      assign sat_cnt_rst[i]  = ~glitchy_signal[i];
      /* clock enable when sample count is wraping and debounced_signal has not reached PULSE_CNT_MAX yet  */
      assign sat_cnt_ce[i]   = wrapping_cnt_rst & (~debounced_signal[i]);
    end
    endgenerate

endmodule
