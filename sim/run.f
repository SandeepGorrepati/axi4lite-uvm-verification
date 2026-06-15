// -----------------------------------------------------------------------------
// Compile order for the AXI4-Lite UVM environment.
// Use with Questa/VCS/Xcelium, e.g.:
//   vlog -sv +incdir+../tb -f run.f      (Questa)
//   vcs  -sverilog +incdir+../tb -f run.f -ntb_opts uvm   (VCS)
// -----------------------------------------------------------------------------
+incdir+../tb
../rtl/axi4lite_slave.sv
../tb/axi4lite_if.sv
../tb/axi4lite_pkg.sv
../tb/tb_top.sv
