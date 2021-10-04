`timescale 1ns/1ps
`include "../include/params.v"

module axis_maxpool_engine #(ZERO=0) (
    aclk         ,
    aresetn      ,
    debug_config ,
    s_axis_tvalid,
    s_axis_tready,
    s_axis_tdata , // cgu
    s_axis_tuser ,
    m_axis_tvalid,
    m_axis_tready,
    m_axis_tdata , // cgu
    m_axis_tkeep , // cgu
    m_axis_tlast 
  );

  localparam UNITS        = `UNITS       ;
  localparam GROUPS       = `GROUPS      ;
  localparam MEMBERS      = `MEMBERS     ;
  localparam WORD_WIDTH   = `WORD_WIDTH  ;
  localparam TUSER_WIDTH_MAXPOOL_IN   = `TUSER_WIDTH_MAXPOOL_IN  ;

  localparam DEBUG_CONFIG_WIDTH_MAXPOOL = `DEBUG_CONFIG_WIDTH_MAXPOOL;
  localparam KH_MAX       = `KH_MAX      ; // odd
  localparam KW_MAX       = `KW_MAX      ; // odd
  localparam I_IS_NOT_MAX = `I_IS_NOT_MAX;
  localparam UNITS_EDGES  = `UNITS_EDGES;

  input  wire aclk, aresetn;
  input  wire s_axis_tvalid, m_axis_tready;
  output wire m_axis_tvalid, s_axis_tready, m_axis_tlast;
  input  wire [TUSER_WIDTH_MAXPOOL_IN-1:0] s_axis_tuser;

  input wire  [GROUPS*UNITS*2*WORD_WIDTH-1:0]       s_axis_tdata;
  output wire [GROUPS*UNITS_EDGES*2*WORD_WIDTH-1:0] m_axis_tdata;
  output wire [GROUPS*UNITS_EDGES*2-1:0]            m_axis_tkeep;

  output wire [DEBUG_CONFIG_WIDTH_MAXPOOL-1:0] debug_config;

  wire [GROUPS*UNITS*2*WORD_WIDTH-1:0] slice_m_data_flat;
  wire [GROUPS*UNITS*2-1:0]            slice_m_keep_flat;
  wire [GROUPS*UNITS*2*WORD_WIDTH-1:0] engine_m_data_flat;
  wire [GROUPS*UNITS*2-1:0]            engine_m_keep_flat;

  wire [WORD_WIDTH-1:0] slice_m_data_cgu [1:0][GROUPS-1:0][UNITS-1:0];
  wire slice_m_keep_cgu [1:0][GROUPS-1:0][UNITS-1:0];

  wire [WORD_WIDTH-1:0] axis_m_data_cgu [1:0][GROUPS-1:0][UNITS_EDGES-1:0];
  wire axis_m_keep_cgu [1:0][GROUPS-1:0][UNITS_EDGES-1:0];

  wire m_valid, slice_ready, engine_ready, m_last, engine_clken;


  /*
    Syncing
  */
  assign engine_clken = slice_ready;
  assign s_axis_tready = engine_ready && slice_ready;

  maxpool_engine #(.ZERO(ZERO)) engine
  (
    .clk         (aclk         ),
    .clken       (engine_clken ),
    .resetn      (aresetn      ),
    .debug_config(debug_config ),
    .s_valid     (s_axis_tvalid),
    .s_data_flat_cgu (s_axis_tdata ),
    .s_ready     (engine_ready ),
    .s_user      (s_axis_tuser ),
    .m_valid     (m_valid      ),
    .m_data_flat_cgu (engine_m_data_flat       ),
    .m_keep_flat_cgu (engine_m_keep_flat       ),
    .m_last      (m_last       )
  );

  axis_reg_slice_maxpool slice (
    .aclk           (aclk           ),  // input wire aclk
    .aresetn        (aresetn        ),  // input wire aresetn
    .s_axis_tvalid  (m_valid        ),  // input wire s_axis_tvalid
    .s_axis_tready  (slice_ready    ),  // output wire s_axis_tready
    .s_axis_tdata   (engine_m_data_flat),  // input wire [2047 : 0] s_axis_tdata
    .s_axis_tkeep   (engine_m_keep_flat),  // input wire [255 : 0] s_axis_tkeep
    .s_axis_tlast   (m_last         ),  // input wire s_axis_tlast

    .m_axis_tvalid  (m_axis_tvalid  ),  // output wire m_axis_tvalid
    .m_axis_tready  (m_axis_tready  ),  // input wire m_axis_tready
    .m_axis_tdata   (slice_m_data_flat   ),  // output wire [2047 : 0] m_axis_tdata
    .m_axis_tkeep   (slice_m_keep_flat   ),  // output wire [255 : 0] m_axis_tkeep
    .m_axis_tlast   (m_axis_tlast   )   // output wire m_axis_tlast
  );

  /*
    Padding output with zeros
  */

  generate
    for (genvar c=0; c<2; c=c+1) begin
      for (genvar g=0; g<GROUPS; g=g+1) begin
        
        /*
          Pad KH_MAX      /2 units on either side with zeros
        */
        for (genvar i=0; i<KH_MAX      /2; i = i+1) begin
          assign axis_m_data_cgu [c][g][i] = 0;
          assign axis_m_keep_cgu [c][g][i] = slice_m_keep_cgu [c][g][0];

          assign axis_m_data_cgu [c][g][(UNITS_EDGES-1)-i] = 0;
          assign axis_m_keep_cgu [c][g][(UNITS_EDGES-1)-i] = slice_m_keep_cgu [c][g][0];
        end

        /*
          Assign actual data to middle units
        */

        for (genvar u=0; u<UNITS_EDGES; u=u+1) begin
          if (u < UNITS) begin
            assign slice_m_data_cgu [c][g][u] = slice_m_data_flat [(c*GROUPS*UNITS + g*UNITS + u + 1)*WORD_WIDTH-1 : (c*GROUPS*UNITS + g*UNITS + u)*WORD_WIDTH];
            assign slice_m_keep_cgu [c][g][u] = slice_m_keep_flat [(c*GROUPS*UNITS + g*UNITS + u + 1)-1            : (c*GROUPS*UNITS + g*UNITS + u)];
          
            assign axis_m_data_cgu [c][g][u + KH_MAX      /2] = slice_m_data_cgu [c][g][u];
            assign axis_m_keep_cgu [c][g][u + KH_MAX      /2] = slice_m_keep_cgu [c][g][u];
          end

          // Flatten
          assign m_axis_tdata [(c*GROUPS*UNITS_EDGES + g*UNITS_EDGES + u + 1)*WORD_WIDTH-1 : (c*GROUPS*UNITS_EDGES + g*UNITS_EDGES + u)*WORD_WIDTH] = axis_m_data_cgu [c][g][u];
          assign m_axis_tkeep [(c*GROUPS*UNITS_EDGES + g*UNITS_EDGES + u + 1)           -1 : (c*GROUPS*UNITS_EDGES + g*UNITS_EDGES + u)           ] = axis_m_keep_cgu [c][g][u];

        end
      end
    end
  endgenerate

endmodule