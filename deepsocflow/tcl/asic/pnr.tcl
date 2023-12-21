setMultiCpuUsage -localCpu 20

source ../../deepsocflow/tcl/asic/loadDesignTech.tcl
source ../../deepsocflow/tcl/asic/initialFloorplan.tcl
source ../../deepsocflow/tcl/asic/pinPlacement.tcl
source ../../deepsocflow/tcl/asic/placement.tcl
source ../../deepsocflow/tcl/asic/clock.tcl
source ../../deepsocflow/tcl/asic/route.tcl
source ../../deepsocflow/tcl/asic/reportDesign.tcl
source ../../deepsocflow/tcl/asic/outputGen.tcl

saveDesign route.enc
dumpToGIF ../../docs/pnr.gif