set TOP dnn_engine
set FREQ 1000
set clock_cycle [expr 1000/$FREQ]
set io_delay [expr $clock_cycle/5]

#--------- CONFIG
set REPORT_DIR ../asic/reports/
set_db hdl_max_loop_limit 10000000
#set_db partition_based_synthesis false
set_db max_cpus_per_server 8
#set super_thread_debug_directory "../asic/reports/Super_Thread_Bugs.log"

#--------- LIBRARIES
set_db library "../asic/pdk/tsmc65lp/lib/sc9_cln65lp_base_rvt_ss_typical_max_1p08v_125c.lib ../asic/srams/sram_weights/sram_weights_ss_1p08v_1p08v_125c.lib ../asic/srams/sram_edges/sram_edges_ss_1p08v_1p08v_125c.lib"
set_db lef_library { ../asic/pdk/tsmc65lp/lef/sc9_tech.lef ../asic/pdk/tsmc65lp/lef/sc9_cln65lp_base_rvt.lef ../asic/srams/sram_weights/sram_weights.lef ../asic/srams/sram_edges/sram_edges.lef}
set_db cap_table_file ../asic/pdk/tsmc65lp/qrc/typical.captbl

#--------- READ
read_hdl -language sv ../../deepsocflow/rtl/include/defines.svh
read_hdl -language v2001 ../asic/srams/sram_weights/sram_weights.v
read_hdl -language v2001 ../asic/srams/sram_edges/sram_edges.v
read_hdl -language sv ../asic/srams/ram_asic.sv

read_hdl -language v2001 [glob ../../deepsocflow/rtl/ext/*.v]
read_hdl -language sv [glob ../../deepsocflow/rtl/ext/*.sv]
read_hdl -language sv [glob ../../deepsocflow/rtl/*.sv]
read_hdl -language v2001 [glob ../../deepsocflow/rtl/*.v]

#--------- ELABORATE & CHECK
set_db lp_insert_clock_gating false
elaborate $TOP
check_design > ${REPORT_DIR}/check_design.rpt
uniquify $TOP

#--------- CONSTRAINTS
create_clock -name aclk -period $clock_cycle [get_ports aclk]
set_false_path -from [get_ports "aresetn"]
set_input_delay -clock [get_clocks aclk] -add_delay -max $io_delay [all_inputs]
set_output_delay -clock [get_clocks aclk] -add_delay -max $io_delay [all_outputs]

#--------- RETIME OPTIONS
set_db retime_async_reset true
set_db design:${TOP} .retime true

#--------- SYNTHESIZE
set_db syn_global_effort medium
syn_generic
syn_map
syn_opt

#--------- NETLIST
write -mapped > ../asic/outputs/${TOP}.out.v
write_sdc > ../asic/outputs/${TOP}.out.sdc

#--------- REPORTS
report_area -detail > ${REPORT_DIR}/syn_${TOP}_${FREQ}MHZ_area.rpt
report_gates > ${REPORT_DIR}/syn_${TOP}_${FREQ}MHZ_gates.rpt
report_timing  -nworst 100 > ${REPORT_DIR}/syn_${TOP}_${FREQ}MHZ_timing.rpt
report_congestion > ${REPORT_DIR}/syn_${TOP}_${FREQ}MHZ_congestion.rpt
report_messages > ${REPORT_DIR}/syn_${TOP}_${FREQ}MHZ_messages.rpt
report_hierarchy > ${REPORT_DIR}/syn_${TOP}_${FREQ}MHZ_hierarchy.rpt
report_clock_gating > ${REPORT_DIR}/syn_${TOP}_${FREQ}MHZ_clock_gating.rpt

build_rtl_power_models -clean_up_netlist
report_power > ${REPORT_DIR}/syn_${TOP}_${FREQ}MHZ_power.rpt
