# relative to matlab callscript
cd ../sim/ 

if {[file exists rtl_work]} {
   vdel -lib rtl_work -all
}

vlib rtl_work
vmap work rtl_work

file copy -force {../rtl/cordicLUT.vh} {cordicLUT.vh}
file copy -force {../rtl/cordicPkg.vh} {cordicPkg.vh}
vlog     -work work {../rtl/cordicCosSinParallel.sv}
vlog     -work work {../rtl/cordicCosSinSerial.sv}
vlog     -work work {../rtl/cordicCosSin.sv}
vlog     -work work {tb_CordicCosSin.sv}

vsim -t 1ns -L work -voptargs="+acc" tb_CordicCosSin

onbreak {exit -force}
run -all
