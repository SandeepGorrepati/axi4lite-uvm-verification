# =============================================================================
# Makefile for the AXI4-Lite UVM environment.
# Targets a UVM-capable simulator. Defaults to Questa (vlog/vsim).
# Override TEST to pick a test: make questa TEST=axi4lite_sanity_test
# =============================================================================
TEST ?= axi4lite_regression_test
INC  ?= +incdir+../tb

# ---- Questa / ModelSim --------------------------------------------------------
questa:
	vlib work
	vlog -sv $(INC) -f run.f
	vsim -c tb_top -do "run -all; quit" +UVM_TESTNAME=$(TEST) \
	     +UVM_VERBOSITY=UVM_MEDIUM

# ---- Synopsys VCS -------------------------------------------------------------
vcs:
	vcs -full64 -sverilog -ntb_opts uvm $(INC) -f run.f -o simv
	./simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM

# ---- Cadence Xcelium ----------------------------------------------------------
xrun:
	xrun -uvm -sv $(INC) -f run.f +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM

clean:
	rm -rf work transcript *.vcd *.wlf csrc simv* *.log ucli.key vc_hdrs.h
