all:
	verilator --cc --trace --top-module ffs_module ffs_module.sv --exe testbench.cpp; \
	cd obj_dir; make -f Vffs_module.mk Vffs_module; ./Vffs_module

.PHONY: clean
clean:
	rm -rf obj_dir
