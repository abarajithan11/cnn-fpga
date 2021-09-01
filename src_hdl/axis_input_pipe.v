`include "params.v"

module axis_input_pipe 
  #(
    ZERO=0,
    
    UNITS                     = `UNITS                    ,
    CORES                     = `CORES                    ,
    COPIES                    = `COPIES                   ,
    MEMBERS                   = `MEMBERS                  ,
    WORD_WIDTH                = `WORD_WIDTH               , 
    KH_MAX                    = `KH_MAX                   ,   // odd number
    KW_MAX                    = `KW_MAX                   ,
    // DEBUG WIDTHS
    DEBUG_CONFIG_WIDTH_W_ROT  = `DEBUG_CONFIG_WIDTH_W_ROT  ,
    DEBUG_CONFIG_WIDTH_IM_PIPE= `DEBUG_CONFIG_WIDTH_IM_PIPE,
    //  IMAGE TUSER INDICES 
    I_KH2                     = `I_KH2             , 
    TUSER_WIDTH_IM_SHIFT_IN   = `TUSER_WIDTH_IM_SHIFT_IN  ,
    TUSER_WIDTH_IM_SHIFT_OUT  = `TUSER_WIDTH_IM_SHIFT_OUT ,
    IM_CIN_MAX                = `IM_CIN_MAX               ,
    IM_BLOCKS_MAX             = `IM_BLOCKS_MAX            ,
    IM_COLS_MAX               = `IM_COLS_MAX              ,
    S_WEIGHTS_WIDTH_HF        = `S_WEIGHTS_WIDTH_HF          ,
    LATENCY_BRAM              = `LATENCY_BRAM             ,
    // WEIGHTS TUSER INDICES 
    I_WEIGHTS_IS_TOP_BLOCK    = `I_WEIGHTS_IS_TOP_BLOCK   ,
    I_WEIGHTS_IS_BOTTOM_BLOCK = `I_WEIGHTS_IS_BOTTOM_BLOCK,
    I_WEIGHTS_IS_COLS_1_K2    = `I_WEIGHTS_IS_COLS_1_K2   ,
    I_WEIGHTS_IS_CONFIG       = `I_WEIGHTS_IS_CONFIG      ,
    I_WEIGHTS_IS_CIN_LAST     = `I_WEIGHTS_IS_CIN_LAST    ,
    I_WEIGHTS_KW2             = `I_WEIGHTS_KW2            , 
    TUSER_WIDTH_WEIGHTS_OUT   = `TUSER_WIDTH_WEIGHTS_OUT  ,
    //  CONV TUSER INDICES   
    I_IS_NOT_MAX              = `I_IS_NOT_MAX             ,
    I_IS_MAX                  = `I_IS_MAX                 ,
    I_IS_LRELU                = `I_IS_LRELU               ,
    I_IS_TOP_BLOCK            = `I_IS_TOP_BLOCK           ,
    I_IS_BOTTOM_BLOCK         = `I_IS_BOTTOM_BLOCK        ,
    I_IS_COLS_1_K2            = `I_IS_COLS_1_K2           ,
    I_IS_CONFIG               = `I_IS_CONFIG              ,
    I_IS_CIN_LAST             = `I_IS_CIN_LAST            ,
    I_KW2                     = `I_KW2             , 
    TUSER_WIDTH_CONV_IN       = `TUSER_WIDTH_CONV_IN      
  )(
    aclk                  ,
    aresetn               ,
    debug_config          ,
    s_axis_pixels_1_tready, 
    s_axis_pixels_1_tvalid, 
    s_axis_pixels_1_tlast , 
    s_axis_pixels_1_tdata , 
    s_axis_pixels_1_tkeep , 
    s_axis_pixels_2_tready,  
    s_axis_pixels_2_tvalid,  
    s_axis_pixels_2_tlast ,   
    s_axis_pixels_2_tdata ,   
    s_axis_pixels_2_tkeep ,      
    s_axis_weights_tready ,
    s_axis_weights_tvalid ,
    s_axis_weights_tlast  ,
    s_axis_weights_tdata  ,
    s_axis_weights_tkeep  , 
    m_axis_tready         ,      
    m_axis_tvalid         ,     
    m_axis_tlast          ,     
    m_axis_tuser          ,
    m_axis_pixels_tdata   ,
    m_axis_weights_tdata  
  ); 


  localparam UNITS_EDGES       = `UNITS_EDGES      ;
  localparam IM_IN_S_DATA_WORDS= `IM_IN_S_DATA_WORDS;
  localparam BITS_KH2          = `BITS_KH2;
  localparam BITS_KW2          = `BITS_KW2;
  localparam TKEEP_WIDTH_IM_IN = `TKEEP_WIDTH_IM_IN;

  input wire aclk;
  input wire aresetn;

  output wire s_axis_pixels_1_tready;
  input  wire s_axis_pixels_1_tvalid;
  input  wire s_axis_pixels_1_tlast ;
  input  wire [WORD_WIDTH*IM_IN_S_DATA_WORDS-1:0] s_axis_pixels_1_tdata;
  input  wire [TKEEP_WIDTH_IM_IN            -1:0] s_axis_pixels_1_tkeep;

  output wire s_axis_pixels_2_tready;
  input  wire s_axis_pixels_2_tvalid;
  input  wire s_axis_pixels_2_tlast ;
  input  wire [WORD_WIDTH*IM_IN_S_DATA_WORDS-1:0] s_axis_pixels_2_tdata;
  input  wire [TKEEP_WIDTH_IM_IN            -1:0] s_axis_pixels_2_tkeep;

  output wire s_axis_weights_tready;
  input  wire s_axis_weights_tvalid;
  input  wire s_axis_weights_tlast ;
  input  wire [S_WEIGHTS_WIDTH_HF -1:0] s_axis_weights_tdata;
  input  wire [S_WEIGHTS_WIDTH_HF /8 -1:0] s_axis_weights_tkeep;

  wire image_is_config;
  wire im_mux_m_ready;
  wire im_mux_m_valid;
  wire [TUSER_WIDTH_IM_SHIFT_IN-1:0] im_mux_m_user;
  wire [WORD_WIDTH*UNITS_EDGES-1:0] im_mux_m_data_1;
  wire [WORD_WIDTH*UNITS_EDGES-1:0] im_mux_m_data_2;

  wire pixels_m_ready;
  wire pixels_m_valid;
  wire [TUSER_WIDTH_IM_SHIFT_OUT-1:0] pixels_m_user;
  
  wire weights_m_ready;
  wire weights_m_valid;
  wire weights_m_last;
  wire [TUSER_WIDTH_WEIGHTS_OUT-1:0] weights_m_user;

  input  wire m_axis_tready;
  output wire m_axis_tvalid;
  output wire m_axis_tlast ;
  output wire [COPIES*WORD_WIDTH*UNITS      -1:0] m_axis_pixels_tdata;
  output wire [WORD_WIDTH*CORES*MEMBERS     -1:0] m_axis_weights_tdata;
  output wire [TUSER_WIDTH_CONV_IN-1:0] m_axis_tuser;

  wire [DEBUG_CONFIG_WIDTH_IM_PIPE-1:0] image_pipe_debug_config;
  wire [BITS_KH2     -1:0]              im_shift_1_debug_config, im_shift_2_debug_config;
  wire [DEBUG_CONFIG_WIDTH_W_ROT  -1:0] w_rot_debug_config;

  localparam DEBUG_CONFIG_WIDTH = 2*BITS_KH2      + DEBUG_CONFIG_WIDTH_IM_PIPE + DEBUG_CONFIG_WIDTH_W_ROT;
  output wire [DEBUG_CONFIG_WIDTH-1:0] debug_config;
  assign debug_config = {im_shift_2_debug_config, im_shift_1_debug_config, image_pipe_debug_config, w_rot_debug_config};

  axis_image_pipe #(.ZERO(ZERO)) IM_MUX (
    .aclk            (aclk   ),
    .aresetn         (aresetn),
    .debug_config    (image_pipe_debug_config),
    .is_config       (image_is_config        ),
    .s_axis_1_tready (s_axis_pixels_1_tready), 
    .s_axis_1_tvalid (s_axis_pixels_1_tvalid), 
    .s_axis_1_tlast  (s_axis_pixels_1_tlast ), 
    .s_axis_1_tdata  (s_axis_pixels_1_tdata ), 
    .s_axis_1_tkeep  (s_axis_pixels_1_tkeep ), 
    .s_axis_2_tready (s_axis_pixels_2_tready),  
    .s_axis_2_tvalid (s_axis_pixels_2_tvalid),  
    .s_axis_2_tlast  (s_axis_pixels_2_tlast ),   
    .s_axis_2_tdata  (s_axis_pixels_2_tdata ),   
    .s_axis_2_tkeep  (s_axis_pixels_2_tkeep ),      
    .m_axis_tready   (im_mux_m_ready ),      
    .m_axis_tvalid   (im_mux_m_valid ),     
    .m_axis_1_tdata  (im_mux_m_data_1),
    .m_axis_2_tdata  (im_mux_m_data_2),
    .m_axis_tuser    (im_mux_m_user  )
  );

  axis_image_shift_buffer #(.ZERO(ZERO)) IM_SHIFT_1 (
    .aclk          (aclk           ),
    .aresetn       (aresetn        ),
    .is_config     (image_is_config),
    .debug_config  (im_shift_1_debug_config),
    .s_axis_tready (im_mux_m_ready ),  
    .s_axis_tvalid (im_mux_m_valid ),  
    .s_axis_tdata  (im_mux_m_data_1),   
    .s_axis_tuser  (im_mux_m_user  ),   
    .m_axis_tvalid (pixels_m_valid ),     
    .m_axis_tready (pixels_m_ready ),      
    .m_axis_tuser  (pixels_m_user  ),
    .m_axis_tdata  (m_axis_pixels_tdata [1*WORD_WIDTH*UNITS-1 : 0*WORD_WIDTH*UNITS])
  );
generate
  if (COPIES==2)
    axis_image_shift_buffer #(.ZERO(ZERO)) IM_SHIFT_2 (
      .aclk          (aclk           ),
      .aresetn       (aresetn        ),
      .is_config     (image_is_config),
      .debug_config  (im_shift_2_debug_config),
      .s_axis_tvalid (im_mux_m_valid ),  
      .s_axis_tdata  (im_mux_m_data_2),   
      .s_axis_tuser  (im_mux_m_user  ),   
      .m_axis_tready (pixels_m_ready ),      
      .m_axis_tdata  (m_axis_pixels_tdata [2*WORD_WIDTH*UNITS-1 : 1*WORD_WIDTH*UNITS])
    );
endgenerate

  axis_weight_rotator #(.ZERO(ZERO)) WEIGHTS_ROTATOR (
    .aclk          (aclk                 ),
    .aresetn       (aresetn              ),
    .debug_config  (w_rot_debug_config   ),
    .s_axis_tready (s_axis_weights_tready), 
    .s_axis_tvalid (s_axis_weights_tvalid), 
    .s_axis_tlast  (s_axis_weights_tlast ), 
    .s_axis_tdata  (s_axis_weights_tdata ),
    .s_axis_tkeep  (s_axis_weights_tkeep ),
    .m_axis_tready (weights_m_ready      ),      
    .m_axis_tvalid (weights_m_valid      ),   
    .m_axis_tdata  (m_axis_weights_tdata ),
    .m_axis_tlast  (weights_m_last       ),
    .m_axis_tuser  (weights_m_user       ) 
  );

  /*
    Synchronizing streams
  */

  assign m_axis_tvalid   = weights_m_valid && pixels_m_valid;
  assign weights_m_ready = m_axis_tready   && pixels_m_valid;
  assign pixels_m_ready  = m_axis_tready   && weights_m_valid;

  /* 
    TUSER 
  */
  
  assign m_axis_tlast    = weights_m_last;

  assign m_axis_tuser [I_IS_NOT_MAX     ] = pixels_m_user  [I_IS_NOT_MAX];
  assign m_axis_tuser [I_IS_MAX         ] = pixels_m_user  [I_IS_MAX    ];
  assign m_axis_tuser [I_KH2 + BITS_KH2-1: I_KH2] = pixels_m_user [I_KH2 + BITS_KH2-1: I_KH2];
  assign m_axis_tuser [I_IS_LRELU       ] = pixels_m_user  [I_IS_LRELU  ];

  assign m_axis_tuser [I_IS_TOP_BLOCK   ] = weights_m_user [I_WEIGHTS_IS_TOP_BLOCK   ] && m_axis_tvalid;
  assign m_axis_tuser [I_IS_BOTTOM_BLOCK] = weights_m_user [I_WEIGHTS_IS_BOTTOM_BLOCK] && m_axis_tvalid;
  assign m_axis_tuser [I_IS_COLS_1_K2   ] = weights_m_user [I_WEIGHTS_IS_COLS_1_K2   ] && m_axis_tvalid;
  assign m_axis_tuser [I_IS_CONFIG      ] = weights_m_user [I_WEIGHTS_IS_CONFIG      ];
  assign m_axis_tuser [I_IS_CIN_LAST    ] = weights_m_user [I_WEIGHTS_IS_CIN_LAST    ] && m_axis_tvalid;
  assign m_axis_tuser [I_KW2 + BITS_KW2-1: I_KW2] = weights_m_user [I_WEIGHTS_KW2 + BITS_KW2-1: I_WEIGHTS_KW2];

  /*
    DATA

    - Pixels  : two (C) streams of U
    - Weights : one stream in CMG
    - Conv engine is agnostic to M and G
      - Assume weights are in MCG, then cores are CMG_flat
    - Send out two streams of pixels and one of weights
  */
endmodule