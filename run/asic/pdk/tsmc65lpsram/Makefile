TSMC_SR_DIR := /home/user10/Aba_Tapeout/deepsocflow/run/asic/srams

TSMC_SR_WEIGHTS_DIR := /home/user10/Aba_Tapeout/deepsocflow/run/asic/srams/sram_weights
SRAM_WEIGHT_SPEC_FILE := /home/user10/Aba_Tapeout/deepsocflow/run/asic/pdk/tsmc65lpsram/sram_weights.spec

TSMC_SR_EDGES_DIR := /home/user10/Aba_Tapeout/deepsocflow/run/asic/srams/sram_edges
SRAM_EDGES_SPEC_FILE := /home/user10/Aba_Tapeout/deepsocflow/run/asic/pdk/tsmc65lpsram/sram_edges.spec

TSMC_SR_OUTPUT_DIR := /home/user10/Aba_Tapeout/deepsocflow/run/asic/srams/sram_output
SRAM_OUTPUT_SPEC_FILE := /home/user10/Aba_Tapeout/deepsocflow/run/asic/pdk/tsmc65lpsram/sram_output.spec

TSMC_MEMORY_COMPILER := /home/user10/ARM_IP/IP_Library/tsmc/cln65lp/rf_sp_hdf_hvt_rvt/r0p0/bin/

gen_memories: srams
	@mkdir -p $(TSMC_SR_DIR)
	@mkdir -p $(TSMC_SR_WEIGHTS_DIR)
	echo "Generating SRAM_WEIGHTS"
	cd $(TSMC_SR_WEIGHTS_DIR);$(TSMC_MEMORY_COMPILER)/rf_sp_hdf_hvt_rvt all -spec $(SRAM_WEIGHT_SPEC_FILE);
	cd $(TSMC_SR_WEIGHTS_DIR);$(TSMC_MEMORY_COMPILER)/rf_sp_hdf_hvt_rvt liberty -spec $(SRAM_WEIGHT_SPEC_FILE);
	
	@mkdir -p $(TSMC_SR_EDGES_DIR)
	echo "Generating SRAM_EDGES"
	cd $(TSMC_SR_EDGES_DIR);$(TSMC_MEMORY_COMPILER)/rf_sp_hdf_hvt_rvt all -spec $(SRAM_EDGES_SPEC_FILE);
	cd $(TSMC_SR_EDGES_DIR);$(TSMC_MEMORY_COMPILER)/rf_sp_hdf_hvt_rvt liberty -spec $(SRAM_EDGES_SPEC_FILE);
	
	@mkdir -p $(TSMC_SR_OUTPUT_DIR)
	echo "Generating SRAM_WEIGHTS"
	cd $(TSMC_SR_OUTPUT_DIR);$(TSMC_MEMORY_COMPILER)/rf_sp_hdf_hvt_rvt all -spec $(SRAM_OUTPUT_SPEC_FILE);
	cd $(TSMC_SR_OUTPUT_DIR);$(TSMC_MEMORY_COMPILER)/rf_sp_hdf_hvt_rvt liberty -spec $(SRAM_OUTPUT_SPEC_FILE);
srams :
