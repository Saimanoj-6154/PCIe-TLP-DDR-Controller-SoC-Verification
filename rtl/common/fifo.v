`timescale 1ns/1ps

module fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout,
    output wire                  full,
    output wire                  empty
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0] count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            dout   <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1'b1;
                    count <= count + 1'b1;
                end

                2'b01: begin
                    dout <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1'b1;
                    count <= count - 1'b1;
                end

                2'b11: begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1'b1;
                    dout <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1'b1;
                end

                default: begin
                    // No operation.
                end
            endcase
        end
    end

endmodule
