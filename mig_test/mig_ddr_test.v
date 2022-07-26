`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2022 08:29:15 AM
// Design Name: 
// Module Name: mig_ddr_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mig_ddr_test(
    //to DDR3 physical layer    
    inout  [15:0]                ddr3_dq,
    inout  [1 :0]                ddr3_dqs_n,
    inout  [1 :0]                ddr3_dqs_p,
    output [13:0]                ddr3_addr,
    output [2 :0]                ddr3_ba,
    output                       ddr3_ras_n,
    output                       ddr3_cas_n,
    output                       ddr3_we_n,
    output                       ddr3_reset_n,
    output [0 :0]                ddr3_ck_p,
    output [0 :0]                ddr3_ck_n,
    output [0 :0]                ddr3_cke,
    output [0 :0]                ddr3_cs_n,
    output [1 :0]                ddr3_dm,
    output [0 :0]                ddr3_odt,
    input                        sysclk_i,
    input                        usr_rst,
    output                       tg_compare_error,
    output                       init_calib_complete
    );
wire sys_rst = 1'b0;
wire clk_200m, locked;
clk_wiz_0 clk_wiz_inst(.clk_out1(clk_200m),.reset(sys_rst),.locked(locked),.clk_in1(sysclk_i));

localparam ADDR_WIDTH       = 28;
/*
data bus is 16 bits, and burst len is 8, so data width is 
16 * 8 = 128 bits
*/
localparam APP_DATA_WIDTH   = 128;
localparam TEST_DATA_RANGE  = 12'd10;

localparam [2:0]IDLE        = 3'd0;
localparam [2:0]WRITE       = 3'd1;
localparam [2:0]W_2_R       = 3'd2; //we need a middle state to reset r_w_cnt and addr.
localparam [2:0]READ        = 3'd3;
localparam [2:0]WAIT_READ   = 3'd4; //wait read operation finish
localparam [2:0]DONE        = 3'd5;

localparam [2:0]CMD_WRITE   =3'd0;
localparam [2:0]CMD_READ    =3'd1;

reg [2:0] state, next_state;
reg [ADDR_WIDTH-1:0]        app_addr_reg;
reg [11:0]                  r_w_cnt; //how many data bas been read 
reg [11:0]                  r_cmd_sent; //how many read cmd has been sent

wire                        app_sr_active; //ignored
wire                        app_ref_ack;   //ignored
wire                        app_zq_ack;    //ignored
wire[11:0]                  device_temp;   //ignored

wire[ADDR_WIDTH-1:0]        app_addr_i;
wire[2:0]                   app_cmd_i;
wire                        app_en_i;
wire                        app_rdy_o;
wire[APP_DATA_WIDTH-1:0]    app_rd_data_o;
wire                        app_rd_data_end_o;
wire                        app_rd_data_valid_o;
wire[APP_DATA_WIDTH-1:0]    app_wdf_data_i;
wire                        app_wdf_end_i;
wire                        app_wdf_rdy_o;
wire                        app_wdf_wren_i;
wire[7:0]                   debug_read_data;
wire                        ui_clk;
wire                        ui_rst;
wire                        usr_rst_i;

assign usr_rst_i = usr_rst;
assign app_cmd_i        = (state == WRITE) ? CMD_WRITE : CMD_READ; 
assign app_en_i         = (state == WRITE) ? (app_wdf_rdy_o & app_rdy_o) : ((state == READ) && app_rdy_o);
assign app_wdf_wren_i   = (state == WRITE) ? (app_wdf_rdy_o & app_rdy_o) : 0; 
assign app_wdf_end_i    = app_wdf_wren_i;
assign app_addr_i       = app_addr_reg;
assign app_wdf_data_i   = {120'd0, app_addr_reg[7:0]}; 
assign debug_read_data  = app_rd_data_o[7:0];

//r_w_cnt the data write into sdram, and should equal to the data read out
//assign tg_compare_error = app_rd_data_valid_o && (app_addr_reg[7:0] != debug_read_data);
assign tg_compare_error = (state == DONE);

always@(posedge ui_clk)
begin
    if(state == WRITE) begin
        r_w_cnt         <= app_wdf_wren_i ? (r_w_cnt + 12'd1) : r_w_cnt;
        app_addr_reg    <= app_wdf_wren_i ? (app_addr_reg + 28'd8) : app_addr_reg; 
    end else if(state == READ) begin
        r_cmd_sent      <= app_rdy_o ? (r_cmd_sent + 12'd1) : r_cmd_sent;
        app_addr_reg    <= app_rdy_o ? (app_addr_reg + 28'd8) : app_addr_reg;
        r_w_cnt         <= app_rd_data_valid_o ? (r_w_cnt + 12'd1) : r_w_cnt;
    end else if(state == WAIT_READ) begin
        app_addr_reg    <= 28'd0;
        r_w_cnt         <= app_rd_data_valid_o ? (r_w_cnt + 12'd1) : r_w_cnt;
    end else begin
        r_cmd_sent      <= 12'd0;
        app_addr_reg    <= 28'd0;
        r_w_cnt         <= 12'd0;
    end
end

always@(posedge ui_clk)
begin
    if(ui_rst | !usr_rst_i)
        state <= IDLE;
    else
        state <= next_state;
end

always@(*)
begin
    case(state)
        IDLE    : next_state    = init_calib_complete ? WRITE : IDLE;
        WRITE   : next_state    = (r_w_cnt > TEST_DATA_RANGE) ? W_2_R : WRITE;
        W_2_R   : next_state    = READ; 
        READ    : next_state    = (r_cmd_sent > TEST_DATA_RANGE) ? WAIT_READ: READ;
        WAIT_READ:next_state    = (r_w_cnt > TEST_DATA_RANGE) ? DONE: WAIT_READ;
        DONE    : next_state    = DONE;
        default : next_state    = IDLE;
    endcase
end

mig_7series_0 u_mig_7series_0 (
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr),        // output [13:0]    ddr3_addr
    .ddr3_ba                        (ddr3_ba),          // output [2:0]     ddr3_ba
    .ddr3_cas_n                     (ddr3_cas_n),       // output           ddr3_cas_n
    .ddr3_ck_n                      (ddr3_ck_n),        // output [0:0]     ddr3_ck_n
    .ddr3_ck_p                      (ddr3_ck_p),        // output [0:0]     ddr3_ck_p
    .ddr3_cke                       (ddr3_cke),         // output [0:0]     ddr3_cke
    .ddr3_ras_n                     (ddr3_ras_n),       // output           ddr3_ras_n
    .ddr3_reset_n                   (ddr3_reset_n),     // output           ddr3_reset_n
    .ddr3_we_n                      (ddr3_we_n),        // output           ddr3_we_n
    .ddr3_dq                        (ddr3_dq),          // inout [31:0]     ddr3_dq
    .ddr3_dqs_n                     (ddr3_dqs_n),       // inout [3:0]      ddr3_dqs_n
    .ddr3_dqs_p                     (ddr3_dqs_p),       // inout [3:0]      ddr3_dqs_p
    .ddr3_cs_n                      (ddr3_cs_n),        // output [0:0]     ddr3_cs_n
    .ddr3_dm                        (ddr3_dm),          // output [3:0]     ddr3_dm
    .ddr3_odt                       (ddr3_odt),         // output [0:0]     ddr3_odt
    .init_calib_complete            (init_calib_complete),// output         init_calib_complete
    // Application interface ports
    .app_addr                       (app_addr_i),        // input [27:0]     app_addr
    .app_cmd                        (app_cmd_i),         // input [2:0]      app_cmd
    .app_en                         (app_en_i),          // input            app_en
    .app_rdy                        (app_rdy_o),         // output           app_rdy
    .app_wdf_data                   (app_wdf_data_i),    // input [255:0]    app_wdf_data
    .app_wdf_end                    (app_wdf_end_i),     // input            app_wdf_end
    .app_wdf_wren                   (app_wdf_wren_i),    // input            app_wdf_wren
    .app_wdf_rdy                    (app_wdf_rdy_o),     // output           app_wdf_rdy
    .app_rd_data                    (app_rd_data_o),     // output [255:0]   app_rd_data
    .app_rd_data_end                (app_rd_data_end_o), // output           app_rd_data_end
    .app_rd_data_valid              (app_rd_data_valid_o),// output           app_rd_data_valid
    .app_sr_req                     (1'b0),
    .app_ref_req                    (1'b0),
    .app_zq_req                     (1'b0),
    .app_sr_active                  (app_sr_active),    // output           app_sr_active
    .app_ref_ack                    (app_ref_ack),      // output           app_ref_ack
    .app_zq_ack                     (app_zq_ack),       // output           app_zq_ack
    .ui_clk                         (ui_clk),           // output           ui_clk
    .ui_clk_sync_rst                (ui_rst),           // output           ui_clk_sync_rst
    .app_wdf_mask                   (32'd0),            // input [31:0]     app_wdf_mask
    // System Clock Ports
    .sys_clk_i                      (clk_200m),
    .sys_rst                        (locked),           // input            sys_rst
    .device_temp                    (device_temp)
    );

endmodule
