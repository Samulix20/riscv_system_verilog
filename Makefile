VERILATOR_ROOT = /home/samuelpp/opt/verilator
VV = ${VERILATOR_ROOT}/bin/verilator
TOP_MODULE = rv32_core
VERILATED_MODULE = V${TOP_MODULE}
VERILOG_MODULES = $(shell find rtl/modules -name '*.sv')

run: clean verilate test

verilate:
	${VV} -I $(VERILOG_MODULES) -Wall --top-module ${TOP_MODULE} \
	--trace --trace-structs \
	--x-assign unique --x-initial unique \
	--cc -CFLAGS "-std=c++20" --exe rtl/${TOP_MODULE}.sv testbench.cpp 

clean:
	rm -rf obj_dir waveform.vcd

test:
	make -C obj_dir -f ${VERILATED_MODULE}.mk
	./obj_dir/${VERILATED_MODULE} +verilator+rand+reset+2

wave:
	gtkwave waveform.vcd >/dev/null 2>/dev/null &
