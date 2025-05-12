`timescale 1ns/1ps

module tb_axi_traffic_generator;

  parameter ID_WIDTH   = 4;
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 64;
  parameter LEN_WIDTH  = 8;

  logic clk;
  logic rst_n;

  // AXI signals
  logic [ID_WIDTH-1:0]   awid;
  logic [ADDR_WIDTH-1:0] awaddr;
  logic [7:0]            awlen;
  logic [2:0]            awsize;
  logic [1:0]            awburst;
  logic                  awvalid;
  logic                  awready;

  logic [DATA_WIDTH-1:0] wdata;
  logic [(DATA_WIDTH/8)-1:0] wstrb;
  logic                  wlast;
  logic                  wvalid;
  logic                  wready;

  logic [ID_WIDTH-1:0]   bid;
  logic [1:0]            bresp;
  logic                  bvalid;
  logic                  bready;

  logic [ID_WIDTH-1:0]   arid;
  logic [ADDR_WIDTH-1:0] araddr;
  logic [7:0]            arlen;
  logic [2:0]            arsize;
  logic [1:0]            arburst;
  logic                  arvalid;
  logic                  arready;

  logic [ID_WIDTH-1:0]   rid;
  logic [DATA_WIDTH-1:0] rdata;
  logic [1:0]            rresp;
  logic                  rlast;
  logic                  rvalid;
  logic                  rready;

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    clk   = 0;
    rst_n = 0;
    #20;
    rst_n = 1;
  end

  // DUT
  axi_traffic_generator #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .awid     (awid),
    .awaddr   (awaddr),
    .awlen    (awlen),
    .awsize   (awsize),
    .awburst  (awburst),
    .awvalid  (awvalid),
    .awready  (awready),
    .wdata    (wdata),
    .wstrb    (wstrb),
    .wlast    (wlast),
    .wvalid   (wvalid),
    .wready   (wready),
    .bid      (bid),
    .bresp    (bresp),
    .bvalid   (bvalid),
    .bready   (bready),
    .arid     (arid),
    .araddr   (araddr),
    .arlen    (arlen),
    .arsize   (arsize),
    .arburst  (arburst),
    .arvalid  (arvalid),
    .arready  (arready),
    .rid      (rid),
    .rdata    (rdata),
    .rresp    (rresp),
    .rlast    (rlast),
    .rvalid   (rvalid),
    .rready   (rready)
  );

  // Simple AXI Slave: responds immediately

  assign awready = 1;
  assign wready  = 1;

  always_ff @(posedge clk) begin
    if (rst_n && awvalid && awready) begin
      bid    <= awid;
      bresp  <= 2'b00;
      bvalid <= 1;
    end else begin
      bvalid <= 0;
    end
  end

  assign arready = 1;

  logic [3:0] read_count;
  logic [7:0] read_len;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rvalid <= 0;
      rlast  <= 0;
      rid    <= 0;
      rdata  <= 0;
      rresp  <= 0;
      read_count <= 0;
      read_len   <= 0;
    end else begin
      if (arvalid && arready) begin
        read_len   <= arlen;
        read_count <= 0;
        rvalid <= 1;
        rid    <= arid;
        rdata  <= $random;
        rresp  <= 0;
        rlast  <= (arlen == 0);
      end else if (rvalid && rready) begin
        read_count <= read_count + 1;
        if (read_count == read_len) begin
          rlast <= 1;
          rvalid <= 0;
        end else begin
          rdata <= $random;
          rlast <= (read_count == read_len - 1);
        end
      end else begin
        rvalid <= 0;
      end
    end
  end

  // Simulation end
  initial begin
    #1000;
    $display("Simulation finished.");
    $finish;
  end

endmodule
