# Load design
set design     "dnn_engine"

set libdir            "../asic/pdk/tsmc65lp"
set netlist           "../asic/outputs/$design.out.v"
set sdc               "../asic/outputs/$design.out.sdc"
set best_timing_lib 	"../asic/pdk/tsmc65lp/lib/sc9_cln65lp_base_rvt_ff_typical_min_1p10v_m40c.lib ../asic/srams/sram_weights/sram_weights_ss_1p08v_1p08v_m40c.lib ../asic/srams/sram_edges/sram_edges_ss_1p08v_1p08v_m40c.lib"
set worst_timing_lib 	"../asic/pdk/tsmc65lp/lib/sc9_cln65lp_base_rvt_ss_typical_max_1p08v_125c.lib ../asic/srams/sram_weights/sram_weights_ss_1p08v_1p08v_125c.lib ../asic/srams/sram_edges/sram_edges_ss_1p08v_1p08v_125c.lib"
set lef 		           { ../asic/pdk/tsmc65lp/lef/sc9_tech.lef ../asic/pdk/tsmc65lp/lef/sc9_cln65lp_base_rvt.lef ../asic/srams/sram_weights/sram_weights.lef ../asic/srams/sram_edges/sram_edges.lef}

# set best_captbl 	"$libdir/captbl/cln65g+_1p08m+alrdl_top2_cbest.captable"
# set worst_captbl 	"$libdir/captbl/cln65g+_1p08m+alrdl_top2_cworst.captable"

# default settings
set init_pwr_net "VDD"
set init_gnd_net "VSS"

# default settings
set init_verilog "$netlist"
set init_design_netlisttype "Verilog"
set init_design_settop 1
set init_top_cell "$design"
set init_lef_file "$lef"

# MCMM setup
create_library_set -name WC_LIB -timing $worst_timing_lib
create_library_set -name BC_LIB -timing $best_timing_lib
create_rc_corner -name Cmax -T 125
create_rc_corner -name Cmin -T -40
create_delay_corner -name WC -library_set WC_LIB -rc_corner Cmax
create_delay_corner -name BC -library_set BC_LIB -rc_corner Cmin
create_constraint_mode -name CON -sdc_file [list $sdc]
create_analysis_view -name WC_VIEW -delay_corner WC -constraint_mode CON
create_analysis_view -name BC_VIEW -delay_corner BC -constraint_mode CON
init_design -setup {WC_VIEW} -hold {BC_VIEW}

set_interactive_constraint_modes {CON}
setDesignMode -process 65
