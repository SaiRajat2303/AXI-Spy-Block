
module tb_axi_ar_fsm;

    // Parameters
    parameter ADDR_WIDTH = 16;
    parameter ID_WIDTH = 4;
    parameter ID_COUNT = 1 << ID_WIDTH;

    // Testbench signals
    logic clk;
    logic reset;
    logic start_txn;
    logic [ADDR_WIDTH-1:0] cfg_araddr;
    logic [7:0] cfg_arlen;
    logic dealloc_req;
    logic [ID_WIDTH-1:0] dealloc_id;
    
    logic arvalid;
    logic [ID_WIDTH-1:0] arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [7:0] arlen;
    logic arready;

    // Instantiate the AXI AR FSM
    axi_ar_fsm #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .ID_COUNT(ID_COUNT)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start_txn(start_txn),
        .cfg_araddr(cfg_araddr),
        .cfg_arlen(cfg_arlen),
        .dealloc_req(dealloc_req),
        .dealloc_id(dealloc_id),
        .arvalid(arvalid),
        .arid(arid),
        .araddr(araddr),
        .arlen(arlen),
        .arready(arready)
    );

    // Clock generation
    always #5 clk = ~clk; // 100 MHz clock

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;
        arready = 1; // Always keep the Slave ready for requests
        start_txn = 0;
        cfg_araddr = 16'h1000;  // Example address
        cfg_arlen = 8'h08;      // Example length
        dealloc_req = 0;
        dealloc_id = 4'b0000;

        // Apply reset
        reset = 1;
        #10 reset = 0;

        // Test Case 1: Start the first transaction
        start_txn = 1;
        #10 start_txn = 0;
        // Wait for some cycles for the FSM to process
        #50;

        // Test Case 2: Deallocate ID after first transaction
        dealloc_req = 1;
        dealloc_id = arid;  // Deallocate the ID
        #10 dealloc_req = 0;

        // Test Case 3: Start a second transaction with a different address and length
        cfg_araddr = 16'h2000;
        cfg_arlen = 8'h04;
        start_txn = 1;
        #5 arready = 1;
        #10 start_txn = 0;
        // Wait for some cycles
        #50;

        // Test Case 4: Deallocate ID after second transaction
        dealloc_req = 1;
        dealloc_id = arid;  // Deallocate the ID
        #10 dealloc_req = 0;

        // Test Case 5: Start a third transaction with a different configuration
        cfg_araddr = 16'h3000;
        cfg_arlen = 8'h10;  // Larger length
        start_txn = 1;
        #10 start_txn = 0;
        // Wait for some cycles
        #50;

        // Test Case 6: Deallocate ID after third transaction
        dealloc_req = 1;
        dealloc_id = arid;  // Deallocate the ID
        #10 dealloc_req = 0;

        // Test Case 7: Start a fourth transaction with another address
        cfg_araddr = 16'h4000;
        cfg_arlen = 8'h02;  // Smaller length
        start_txn = 1;
        #10 start_txn = 0;
        // Wait for some cycles
        #50;

        // Test Case 8: Deallocate ID after fourth transaction
        dealloc_req = 1;
        dealloc_id = arid;  // Deallocate the ID
        #10 dealloc_req = 0;

        // Test Case 9: Start a fifth transaction with the original address
        cfg_araddr = 16'h1000;  // Reuse the first address
        cfg_arlen = 8'h06;      // New length
        start_txn = 1;
        #10 start_txn = 0;
        // Wait for some cycles
        #50;

        // End simulation
        $finish;
    end

    // Monitor the output signals
    initial begin
        $monitor("Time = %0t | arvalid = %b | arid = %h | araddr = %h | arlen = %h | arready = %b",
                  $time, arvalid, arid, araddr, arlen, arready);
    end

endmodule
