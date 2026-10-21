IVERILOG ?= iverilog
VVP      ?= vvp
PYTHON   ?= python3

RTL_DIR  := rtl
TB_DIR   := verification/tb
BUILD    := build

.PHONY: all compile sim python-test traffic regression clean

all: python-test compile sim

$(BUILD):
	mkdir -p $(BUILD) results/logs results/waveforms results/coverage

compile: $(BUILD)
	$(IVERILOG) -g2012 \
		-I$(RTL_DIR)/top \
		-o $(BUILD)/tb_dma.vvp \
		$(RTL_DIR)/dma/dma_engine.v \
		$(TB_DIR)/tb_top.sv

sim: compile
	$(VVP) $(BUILD)/tb_dma.vvp

python-test:
	$(PYTHON) models/pcie_ref_model.py

traffic:
	$(PYTHON) models/traffic_generator.py \
		--count 1000 --seed 6154 \
		--output results/logs/traffic.json

regression:
	$(PYTHON) scripts/regression.py

clean:
	rm -rf $(BUILD)
