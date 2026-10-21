`timescale 1ns/1ps

module tb_top;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;

    logic clk = 0;
    logic rst_n = 0;

    logic start;
    logic [ADDR_WIDTH-1:0] src_addr;
    logic [ADDR_WIDTH-1:0] dst_addr;
    logic [15:0] length_words;

    wire busy, done, error;
    wire [ADDR_WIDTH-1:0] awaddr;
    wire awvalid;
    logic awready;

    wire [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH/8-1:0] wstrb;
    wire wvalid;
    logic wready;

    logic bvalid;
    wire bready;

    int write_count = 0;

    always #5 clk = ~clk;

    dma_engine #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .length_words(length_words),
        .busy(busy),
        .done(done),
        .error(error),
        .m_axi_awaddr(awaddr),
        .m_axi_awvalid(awvalid),
        .m_axi_awready(awready),
        .m_axi_wdata(wdata),
        .m_axi_wstrb(wstrb),
        .m_axi_wvalid(wvalid),
        .m_axi_wready(wready),
        .m_axi_bvalid(bvalid),
        .m_axi_bready(bready)
    );

    // Simplified AXI write responder.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready <= 0;
            wready <= 0;
            bvalid <= 0;
            write_count <= 0;
        end else begin
            awready <= 1;
            wready <= 1;

            if (wvalid && wready)
                write_count <= write_count + 1;

            if (wvalid && wready)
                bvalid <= 1;
            else if (bvalid && bready)
                bvalid <= 0;
        end
    end

    initial begin
        start = 0;
        src_addr = 'h1000;
        dst_addr = 'h2000;
        length_words = 4;

        repeat (4) @(negedge clk);
        rst_n = 1;

        repeat (2) @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        wait(done);
        @(negedge clk);

        $display("DMA done=%0b, error=%0b, writes=%0d",
                 done, error, write_count);

        if (error)
            $fatal(1, "DMA reported an error");

        if (write_count != 4)
            $fatal(1, "Expected 4 writes, observed %0d",
                   write_count);

        $display("DMA smoke test PASSED");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "Simulation timeout");
    end

endmodule
