vlib work
vmap work work

vcom -2008 packages/pkg.vhdl
vcom -2008 rtl/datapath/XREGS.vhdl rtl/datapath/genImm32.vhdl rtl/datapath/memoria.vhdl rtl/datapath/reg_en.vhdl rtl/datapath/ula.vhdl
vcom -2008 rtl/control/controle.vhdl rtl/control/controle_ULA.vhdl
vcom -2008 rtl/riscv_multiciclo.vhdl
vcom -2008 tb/riscv_testbench.vhdl

vsim work.riscv_multiciclo_tb

add wave                /riscv_multiciclo_tb/clk_tb
add wave                /riscv_multiciclo_tb/rst_tb
add wave -radix hex     /riscv_multiciclo_tb/DUT/pc
add wave -radix hex     /riscv_multiciclo_tb/DUT/instr
add wave                /riscv_multiciclo_tb/DUT/u_controle/state
add wave -radix hex     /riscv_multiciclo_tb/DUT/ula_a
add wave -radix hex     /riscv_multiciclo_tb/DUT/ula_b
add wave -radix hex     /riscv_multiciclo_tb/DUT/ula_z
add wave                /riscv_multiciclo_tb/DUT/ula_zero
add wave                /riscv_multiciclo_tb/DUT/EscreveReg
add wave -radix hex     /riscv_multiciclo_tb/DUT/dado_escrita
add wave -radix hex     /riscv_multiciclo_tb/DUT/u_xregs/breg

run -all
wave zoom full
