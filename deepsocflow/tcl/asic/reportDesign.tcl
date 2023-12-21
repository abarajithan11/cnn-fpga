

verifyGeometry
verifyConnectivity

# Timing report
report_timing -max_paths 100 > ../asic/reports/${design}.post_route.timing.rpt

# Power report
report_power -outfile ../asic/reports/${design}.post_route.power.rpt

# Design report
summaryReport -nohtml -outfile ../asic/reports/${design}.post_route.summary.rpt
