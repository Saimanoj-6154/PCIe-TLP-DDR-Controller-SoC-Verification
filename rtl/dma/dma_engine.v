`timescale 1ns/1ps

module dma_engine #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  start,
    input  wire [ADDR_WIDTH-1:0] src_addr,
    input  wire [ADDR_WIDTH-1:0] dst_addr,
    input  wire [15:0]           length_words,

    output reg                   busy,
    output reg                   done,
    output reg                   error,

    output reg  [ADDR_WIDTH-1:0] m_axi_awaddr,
    output reg                   m_axi_awvalid,
    input  wire                  m_axi_awready,

    output reg  [DATA_WIDTH-1:0] m_axi_wdata,
    output reg  [DATA_WIDTH/8-1:0] m_axi_wstrb,
    output reg                   m_axi_wvalid,
    input  wire                  m_axi_wready,

    input  wire                  m_axi_bvalid,
    output reg                   m_axi_bready
);

    localparam IDLE  = 3'd0;
    localparam ADDR  = 3'd1;
    localparam WRITE = 3'd2;
    localparam RESP  = 3'd3;
    localparam DONE  = 3'd4;

    reg [2:0] state;
    reg [ADDR_WIDTH-1:0] current_src;
    reg [ADDR_WIDTH-1:0] current_dst;
    reg [15:0] remaining;
    reg [DATA_WIDTH-1:0] data_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            busy          <= 1'b0;
            done          <= 1'b0;
            error         <= 1'b0;
            current_src   <= 0;
            current_dst   <= 0;
            remaining     <= 0;
            data_counter  <= 0;
            m_axi_awaddr  <= 0;
            m_axi_awvalid <= 0;
            m_axi_wdata   <= 0;
            m_axi_wstrb   <= {DATA_WIDTH/8{1'b1}};
            m_axi_wvalid  <= 0;
            m_axi_bready  <= 0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    error <= 1'b0;

                    if (start) begin
                        if (length_words == 0) begin
                            error <= 1'b1;
                            done <= 1'b1;
                        end else begin
                            current_src <= src_addr;
                            current_dst <= dst_addr;
                            remaining <= length_words;
                            data_counter <= 0;
                            busy <= 1'b1;
                            state <= ADDR;
                        end
                    end
                end

                ADDR: begin
                    m_axi_awaddr <= current_dst;
                    m_axi_awvalid <= 1'b1;

                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wdata <= data_counter;
                        m_axi_wvalid <= 1'b1;
                        state <= WRITE;
                    end
                end

                WRITE: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid <= 1'b0;
                        m_axi_bready <= 1'b1;
                        state <= RESP;
                    end
                end

                RESP: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        current_src <= current_src + DATA_WIDTH/8;
                        current_dst <= current_dst + DATA_WIDTH/8;
                        data_counter <= data_counter + 1'b1;
                        remaining <= remaining - 1'b1;

                        if (remaining == 1) begin
                            state <= DONE;
                        end else begin
                            state <= ADDR;
                        end
                    end
                end

                DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                    error <= 1'b1;
                end
            endcase
        end
    end

endmodule
