
// Written from Hardware.export()

`define ROWS                8           // PE rows, constrained by resources
`define COLS                24          // PE cols, constrained by resources
`define X_BITS              4           // Bits per word in input
`define K_BITS              4           // Bits per word in input
`define Y_BITS              16          // Bits per word in output of conv

`define KH_MAX              7           // max of kernel height, across layers
`define KW_MAX              7           // max of kernel width, across layers
`define XH_MAX              512         // max of input image height, across layers
`define XW_MAX              512         // max of input image width, across layers
`define XN_MAX              64          // max of input batch size, across layers
`define CI_MAX              2048        // max of input channels, across layers
`define CONFIG_BEATS        0           // constant, for now
`define RAM_WEIGHTS_DEPTH   512         // CONFIG_BEATS + max(KW * CI), across layers
`define RAM_EDGES_DEPTH     2048        // max (KW * CI * XW), across layers when KW != 1

`define DELAY_MUL           3            // constant, for now 
`define DELAY_W_RAM         2            // constant, for now 

`define S_WEIGHTS_WIDTH_LF  64          // constant (64), for now
`define S_PIXELS_WIDTH_LF   64          // constant (64), for now
`define M_OUTPUT_WIDTH_LF   64          // constant (64), for now