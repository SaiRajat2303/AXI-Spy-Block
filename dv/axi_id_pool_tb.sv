
`timescale 1ns / 1ps

module axi_id_pool_tb;

  // Parameters
  parameter ID_WIDTH = 4;
  parameter ID_COUNT  = 1 << ID_WIDTH;

  // DUT signals
  logic clk, reset;
  logic alloc_req, alloc_valid;
  logic [ID_WIDTH-1:0] alloc_id;
  logic dealloc_req;
  logic [ID_WIDTH-1:0] dealloc_id;

  // Clock generation
  always #5 clk = ~clk;

  // DUT instance
  axi_id_pool #(
    .ID_WIDTH(ID_WIDTH),
    .ID_COUNT(ID_COUNT)
  ) dut (
    .clk(clk),
    .reset(reset),
    .alloc_req(alloc_req),
    .alloc_valid(alloc_valid),
    .alloc_id(alloc_id),
    .dealloc_req(dealloc_req),
    .dealloc_id(dealloc_id)
  );

  // Simple test sequence
  initial begin
    clk = 0;
    reset = 1;
    alloc_req = 0;
    dealloc_req = 0;
    dealloc_id = 0;

    // Reset
    #10;
    reset = 0;
    #10;

    // Allocate 16 IDs
    repeat (16) begin
      @(posedge clk);
      alloc_req = 1;
      wait (alloc_valid);
      $display("Allocated ID: %0d", alloc_id);
      @(posedge clk);
      alloc_req = 0;
    end

    // All IDs to be allocated at this point

    // Wait and then deallocate one ID
    #20;
    @(posedge clk);
    dealloc_id = 7; // Let's say ID=1 was allocated earlier
    dealloc_req = 1;
    @(posedge clk);
    dealloc_req = 0;

    // Allocate again and expect ID=7 to come back
    // Since free ID available post de-allocation = 7
    @(posedge clk);
    alloc_req = 1;
    wait (alloc_valid);
    $display("Re-Allocated ID: %0d", alloc_id);
    @(posedge clk);
    alloc_req = 0;

    #20;
    $display("Test completed.");
    $finish;
  end

endmodule
