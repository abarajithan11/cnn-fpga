/*//////////////////////////////////////////////////////////////////////////////////
Group : ABruTECH
Engineer: Abarajithan G.

Create Date: 12/05/2021
Design Name: CYCLIC_BRAM
Tool Versions: Vivado 2018.2

Revision:
Revision 0.01 - File Created
Additional Comments: 

//////////////////////////////////////////////////////////////////////////////////*/
`timescale 1ns/1ps
module cyclic_bram #(
  R_DEPTH      = 8,
  R_DATA_WIDTH = 8,
  W_DATA_WIDTH = 8,
  LATENCY      = 3,
  ABSORB       = 0,
  USE_R_LAST   = 0,
  USE_W_LAST   = 0,
  IP_TYPE      = 0 // 0 - weights, 1 - edge
)(
  clk  ,
  clken,
  resetn,
  w_en,
  r_en,
  s_data,
  m_data,
  m_valid,
  r_last_in,
  w_last_in,
  r_addr_max,
  w_addr_max,
  r_addr_min
  );
  localparam SIZE = R_DEPTH * R_DATA_WIDTH;
  localparam W_DEPTH =  SIZE / W_DATA_WIDTH;
  localparam W_ADDR_WIDTH = $clog2(W_DEPTH);
  localparam R_ADDR_WIDTH = $clog2(R_DEPTH);

  input  logic clk, clken, resetn;
  input  logic w_en, r_en;
  input  logic [W_DATA_WIDTH-1:0] s_data;
  output logic [R_DATA_WIDTH-1:0] m_data;
  output logic m_valid;
  input  logic r_last_in, w_last_in;
  input  logic [R_ADDR_WIDTH-1:0] r_addr_max, r_addr_min;
  input  logic [W_ADDR_WIDTH-1:0] w_addr_max;
 
  /*
    BRAM_WRITE_ADDRESS
  */

  logic [W_ADDR_WIDTH-1:0] w_addr_next, w_addr;
  logic w_last;
  assign w_last = USE_W_LAST  ? w_last_in : w_addr == w_addr_max;
  assign w_addr_next = w_last ? 0         : w_addr + 1;
  register #(
    .WORD_WIDTH   (W_ADDR_WIDTH), 
    .RESET_VALUE  (0),
    .LOCAL        (1)
  ) ADDR_W (
    .clock        (clk        ),
    .clock_enable (clken && w_en),
    .resetn       (resetn     ),
    .data_in      (w_addr_next),
    .data_out     (w_addr)
  );

  /*
    BRAM READ ADDRESS
  */

  logic [R_ADDR_WIDTH-1:0] r_addr, r_addr_next;
  logic r_last;
  assign r_last =  USE_R_LAST ?  r_last_in  : r_addr == r_addr_max;
  assign r_addr_next = r_last ?  r_addr_min : r_addr + 1;
  register #(
    .WORD_WIDTH   (R_ADDR_WIDTH), 
    .RESET_VALUE  (0),
    .LOCAL        (1)
  ) ADD_R (
    .clock        (clk   ),
    .clock_enable (clken && r_en),
    .resetn       (resetn),
    .data_in      (r_addr_next),
    .data_out     (r_addr     )
  );

  logic [R_DATA_WIDTH-1 :0] bram_m_data;

  generate
    if (IP_TYPE == 0)
    `ifdef XILINX
      bram_weights bram (
    `else 
      bram_weights_asic #(
        .R_DEPTH      (R_DEPTH     ),
        .R_DATA_WIDTH (R_DATA_WIDTH),
        .W_DATA_WIDTH (W_DATA_WIDTH)
      ) bram (
    `endif
        .clka   (clk),    
        .ena    (clken),     
        .wea    (w_en),     
        .addra  (w_addr),  
        .dina   (s_data),   
        .clkb   (clk),   
        .enb    (clken),     
        .addrb  (r_addr),  
        .doutb  (bram_m_data)  
      );
  endgenerate

  /*
    FIFO and Delay to make an always valid cyclic BRAM
  */

  if (ABSORB) begin
    
    logic fifo_r_en, r_en_delayed;

    n_delay #(
      .N          (LATENCY),
      .WORD_WIDTH (1)
    ) VALID (
      .clk      (clk),
      .resetn   (resetn),
      .clken    (clken),
      .data_in  (r_en),
      .data_out (r_en_delayed)
    );

    axis_pipeline_register # (
      .DATA_WIDTH  (R_DATA_WIDTH),
      .KEEP_ENABLE (0),
      .LAST_ENABLE (0),
      .ID_ENABLE   (0),
      .DEST_ENABLE (0),
      .USER_ENABLE (0),
      .REG_TYPE    (2),
      .LENGTH      (LATENCY)
    ) REG_PIPE (
      .clk          (clk),
      .rst          (~resetn),
      .s_axis_tdata (bram_m_data),
      .s_axis_tvalid(clken && r_en_delayed),
      .m_axis_tdata (m_data),
      .m_axis_tvalid(m_valid),
      .m_axis_tready(clken && r_en)
    );
  end
  else assign m_data = bram_m_data;

endmodule