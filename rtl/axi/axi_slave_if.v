`timescale 1ns/1ps

module axi_slave_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire [ADDR_WIDTH-1:0]   awaddr,
    input  wire                    awvalid,
    output wire                    awready,

    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire [DATA_WIDTH/8-1:0] wstrb,
    input  wire                    wvalid,
    output wire                    wready,

    output reg                     bvalid,
    input  wire                    bready,

    output reg  [ADDR_WIDTH-1:0]   mem_addr,
    output reg  [DATA_WIDTH-1:0]   mem_wdata,
    output reg  [DATA_WIDTH/8-1:0] mem_wstrb,
    output reg                     mem_wr_en
);

    reg have_addr;
    reg have_data;

    assign awready = !have_addr && !bvalid;
    assign wready  = !have_data && !bvalid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            have_addr <= 0;
            have_data <= 0;
            bvalid <= 0;
            mem_addr <= 0;
            mem_wdata <= 0;
            mem_wstrb <= 0;
            mem_wr_en <= 0;
        end else begin
            mem_wr_en <= 0;

            if (awvalid && awready) begin
                mem_addr <= awaddr;
                have_addr <= 1;
            end

            if (wvalid && wready) begin
                mem_wdata <= wdata;
                mem_wstrb <= wstrb;
                have_data <= 1;
            end

            if (have_addr && have_data && !bvalid) begin
                mem_wr_en <= 1;
                bvalid <= 1;
                have_addr <= 0;
                have_data <= 0;
            end

            if (bvalid && bready)
                bvalid <= 0;
        end
    end

endmodule
