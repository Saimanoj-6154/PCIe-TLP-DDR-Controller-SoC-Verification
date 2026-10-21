`timescale 1ns/1ps

module ddr_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 4096
)(
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output reg                   ready,
    output reg                   rd_valid
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    integer i;
    integer word_addr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data  <= 0;
            ready    <= 1'b0;
            rd_valid <= 1'b0;
        end else begin
            ready    <= 1'b1;
            rd_valid <= 1'b0;

            if (wr_en && rd_en) begin
                // Unsupported simultaneous read/write in this model.
            end else if (wr_en) begin
                word_addr = addr / (DATA_WIDTH/8);

                if (word_addr >= 0 && word_addr < DEPTH)
                    mem[word_addr] <= wr_data;
            end else if (rd_en) begin
                word_addr = addr / (DATA_WIDTH/8);

                if (word_addr >= 0 && word_addr < DEPTH) begin
                    rd_data <= mem[word_addr];
                    rd_valid <= 1'b1;
                end
            end
        end
    end

endmodule
