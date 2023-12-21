getPinAssignMode -pinEditInBatch -quiet
setPinAssignMode -pinEditInBatch true

editPin -pinWidth 0.2 -pinDepth 0.6 -fixOverlap 1 -unit MICRON -spreadDirection        clockwise -side Top    -layer 3 -spreadType center -spacing 0.8 -pin {aclk aresetn s_axis_weights_*}
editPin -pinWidth 0.2 -pinDepth 0.6 -fixOverlap 1 -unit MICRON -spreadDirection        clockwise -side Left   -layer 3 -spreadType center -spacing 0.8 -pin {s_axis_pixels_*}
editPin -pinWidth 0.2 -pinDepth 0.6 -fixOverlap 1 -unit MICRON -spreadDirection counterclockwise -side Right  -layer 3 -spreadType center -spacing 0.8 -pin {m_axis_*}

setPinAssignMode -pinEditInBatch false
getPinAssignMode -pinEditInBatch -quiet
setPinAssignMode -pinEditInBatch true


setPinAssignMode -pinEditInBatch false


legalizePin
checkPinAssignment
