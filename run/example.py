from deepsocflow import Bundle, Hardware, QModel, QInput

'''
0. Specify Hardware
'''
hw = Hardware (                          # Alternatively: hw = Hardware.from_json('hardware.json')
        processing_elements = (8, 24)  , # (rows, columns) of multiply-add units
        frequency_mhz       = 250      , #  
        bits_input          = 4        , # bit width of input pixels and activations
        bits_weights        = 4        , # bit width of weights
        bits_sum            = 16       , # bit width of accumulator
        bits_bias           = 16       , # bit width of bias
        max_batch_size      = 64       , # 
        max_channels_in     = 2048     , #
        max_kernel_size     = 7       , #
        max_image_size      = 512      , #
        ram_weights_depth   = 512       , #
        ram_edges_depth     = 2048      , #
        axi_width           = 64       , #
        target_cpu_int_bits = 32       , #
        valid_prob          = 1        , # probability in which AXI-Stream s_valid signal should be toggled in simulation
        ready_prob          = 1        , # probability in which AXI-Stream m_ready signal should be toggled in simulation
        data_dir            = 'vectors', # directory to store generated test vectors
     )
hw.export() # Generates: config_hw.svh, config_hw.tcl, config_tb.svh, hardware.json
hw.export_vivado_tcl(board='zcu104')


'''
1. Build Model 
'''
XN = 1
input_shape = (XN,18,18,3) # (XN, XH, XW, CI)

QINT_BITS = 0
qq = f'quantized_bits({hw.K_BITS},{QINT_BITS},False,True,1)'
qr = f'quantized_relu({hw.X_BITS},{QINT_BITS},negative_slope=0)'    
ql = f'quantized_relu({hw.X_BITS},{QINT_BITS},negative_slope=0.125)'
kq = bq = qq

x = x_in = QInput(shape=input_shape[1:], batch_size=XN, hw=hw, int_bits=QINT_BITS, name='input')

x = x_skip1 = Bundle( core= {'type':'conv' , 'filters':8 , 'kernel_size':(11,11), 'strides':(2,1), 'padding':'same', 'kernel_quantizer':kq, 'bias_quantizer':bq, 'use_bias':True , 'act_str':qr}, pool= {'type':'avg', 'size':(3,4), 'strides':(2,3), 'padding':'same', 'act_str':f'quantized_bits({hw.X_BITS},0,False,False,1)'})(x)
x = x_skip2 = Bundle( core= {'type':'conv' , 'filters':8 , 'kernel_size':( 1, 1), 'strides':(1,1), 'padding':'same', 'kernel_quantizer':kq, 'bias_quantizer':bq, 'use_bias':True , 'act_str':qq}, add = {'act_str':f'quantized_bits({hw.X_BITS},0,False,True,1)'})(x, x_skip1)
x =           Bundle( core= {'type':'conv' , 'filters':8 , 'kernel_size':( 7, 7), 'strides':(1,1), 'padding':'same', 'kernel_quantizer':kq, 'bias_quantizer':bq, 'use_bias':False, 'act_str':qq}, add = {'act_str':f'quantized_bits({hw.X_BITS},0,False,True,1)'})(x, x_skip2)
x =           Bundle( core= {'type':'conv' , 'filters':8 , 'kernel_size':( 5, 5), 'strides':(1,1), 'padding':'same', 'kernel_quantizer':kq, 'bias_quantizer':bq, 'use_bias':True , 'act_str':ql}, add = {'act_str':f'quantized_bits({hw.X_BITS},0,False,True,1)'})(x, x_skip1)
x =           Bundle( core= {'type':'conv' , 'filters':24, 'kernel_size':( 3, 3), 'strides':(1,1), 'padding':'same', 'kernel_quantizer':kq, 'bias_quantizer':bq, 'use_bias':True , 'act_str':qr},)(x)
x =           Bundle( core= {'type':'conv' , 'filters':10, 'kernel_size':( 1, 1), 'strides':(1,1), 'padding':'same', 'kernel_quantizer':kq, 'bias_quantizer':bq, 'use_bias':True , 'act_str':ql}, flatten= True)(x)
x =           Bundle( core= {'type':'dense', 'units'  :10,                                                           'kernel_quantizer':kq, 'bias_quantizer':bq, 'use_bias':True , 'act_str':ql}, softmax= True)(x)

model = QModel(inputs=x_in.raw, outputs=x)
model.compile()
model.summary()

'''
2. TRAIN (using qkeras)
'''
# model.fit(...)


'''
3. EXPORT FOR INFERENCE
'''
SIM, SIM_PATH = 'xsim', "F:/Xilinx/Vivado/2022.1/bin/" # For Xilinx Vivado
# SIM, SIM_PATH = 'verilator', "" # For Verilator

model.export_inference(x=model.random_input, hw=hw)  # Runs forward pass in float & int, compares them. Generates: config_fw.h (C firmware), weights.bin, expected.bin
model.verify_inference(SIM=SIM, SIM_PATH=SIM_PATH)   # Runs SystemVerilog testbench with the model & weights, randomizing handshakes, testing with actual C firmware in simulation

'''
4. IMPLEMENTATION

a. FPGA: Open vivado, source vivado_flow.tcl
b. ASIC: Set PDK paths, run syn.tcl & pnr.tcl
c. Compile C firmware with generated header (config_fw.h) and run on device
'''