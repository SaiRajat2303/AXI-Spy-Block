module axi_spyblock #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
)
(
    // Purely using the signals needed for the spyblock
    // AXI AR channel signals 
    input ARVALID,
    input ARREADY,
    input [3:0] ARID,
    input [ADDR_WIDTH-1:0] ARADDR,

    // AXI AW channel signals
    input AWVALID,
    input AWREADY,
    input [3:0] AWID,
    input [ADDR_WIDTH-1:0] AWADDR,

    // AXI W channel signals
    input WVALID,
    input WREADY,
    input [3:0] WID,
    input [DATA_WIDTH-1:0] WDATA,

    // AXI R channel signals 
    input RVALID,
    input RREADY,
    input [3:0] RID,
    input [DATA_WIDTH-1:0] RDATA,

    // Generic signals
    input clk,
    input reset,

    // Output signals 
    output r_spy_full,
    output ar_spy_full,
    output w_spy_full,
    output aw_spy_full
);

// Detect a valid txn using valid - Ready Handshake mechanism
wire ar_handshake;
wire aw_handshake;
wire w_handshake;
wire r_handshake;

assign ar_handshake     = (ARREADY & ARVALID);
assign aw_handshake     = (AWREADY & AWVALID);
assign w_handshake      = (WREADY & WVALID);
assign r_handshake      = (RREADY & RVALID);

// We dont really need a reset handling here for spy fifos , as they reset on their own

// ------------------------------------------------ R SPY FIFO HANDLING LOGIC ------------------------------------------

// FIFO signals for R-channel spy block
reg [DATA_WIDTH-1:0] r_data;
reg r_push;
reg r_pop; // assert -> when fifo is full and the next negedge is triggered
wire [DATA_WIDTH-1:0] r_pop_data;
wire r_full;
wire r_empty;
reg [3:0] prev_rid;

fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) r_spy_fifo
(
    .clk(clk),
    .reset(reset),
    .push_i(r_push),
    .push_data_i(r_data),
    .pop_i(r_pop),
    .pop_data_o(r_pop_data),
    .full_o(r_full),
    .empty_o(r_empty)
);

always@(posedge clk) begin
    if(r_handshake) begin
        if(prev_rid !== RID) begin
            prev_rid <= RID; // Store the current ID for next comparison
            r_push <= 1'b1; // Set push flag for new ID
            r_data <= RDATA;
            if(r_full) begin
                r_pop <= 1'b1; // Pop data if FIFO is full
            end
            else begin
                r_pop <= 1'b0;
            end
        end 
        else begin
            prev_rid <= prev_rid; // Maintain previous arid
            r_push <= 1'b0; // Reset push flag if no new IDß
        end
    end
    else begin
        r_push <= 1'b0; // Reset push flag if no handshake
    end
    
end

// ------------------------------------------------ AR SPY FIFO HANDLING LOGIC ------------------------------------------

// FIFO signals for AR-channel spy block
reg [DATA_WIDTH-1:0] ar_addr;
reg ar_push;
reg ar_pop; // assert -> when fifo is full and the next negedge is triggered
wire [DATA_WIDTH-1:0] ar_pop_addr;
wire ar_full;
wire ar_empty;
reg [3:0] prev_arid; // to store the previous ARID for comparison

assign ar_spy_full = ar_full;

fifo #(
    .DATA_WIDTH(ADDR_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) ar_spy_fifo
(
    .clk(clk),
    .reset(reset),
    .push_i(ar_push),
    .push_data_i(ar_addr),
    .pop_i(ar_pop),
    .pop_data_o(ar_pop_addr),
    .full_o(ar_full),
    .empty_o(ar_empty)
);

always@(posedge clk) begin
    if(ar_handshake) begin
        if(prev_arid !== ARID) begin
            prev_arid <= ARID; // Store the current ID for next comparison
            ar_push <= 1'b1; // Set push flag for new ID
            ar_addr <= ARADDR;
            if(ar_full) begin
                ar_pop <= 1'b1; // Pop data if FIFO is full
            end 
            else begin
                ar_pop <= 1'b0;
            end
        end 
            else begin
                prev_arid <= prev_arid; // Maintain previous arid
                ar_push <= 1'b0; // Reset push flag if no new IDß
            end
    end
    else begin
        ar_push <= 1'b0; // Reset push flag if no handshake
    end
end

// ------------------------------------------------ AW SPY FIFO HANDLING LOGIC ------------------------------------------

// FIFO Signals for AW-channel spy block
reg [DATA_WIDTH-1:0] aw_addr;
reg aw_push;
reg aw_pop; // assert -> when fifo is full and the next negedge is triggered
wire [DATA_WIDTH-1:0] aw_pop_addr;
wire aw_full;
wire aw_empty;
reg [3:0] prev_awid; // to store the previous AWID for comparison

assign aw_spy_full = aw_full;

fifo #(
    .DATA_WIDTH(ADDR_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) aw_spy_fifo
(
    .clk(clk),
    .reset(reset),
    .push_i(aw_push),
    .push_data_i(aw_addr),
    .pop_i(aw_pop),
    .pop_data_o(aw_pop_addr),
    .full_o(aw_full),
    .empty_o(aw_empty)
);

always@(posedge clk) begin
    if(aw_handshake) begin
        if(prev_awid !== AWID) begin
            prev_awid <= AWID; // Store the current ID for next comparison
            aw_push <= 1'b1; // Set push flag for new ID
            aw_addr <= AWADDR;
            if(aw_full) begin
                aw_pop <= 1'b1; // Pop data if FIFO is full
            end 
            else begin
                aw_pop <= 1'b0;
            end
        end 
        else begin
            prev_awid <= prev_awid; // Maintain previous awid
            aw_push <= 1'b0; // Reset push flag if no new IDß
        end
    end
    else begin
        aw_push <= 1'b0; // Reset push flag if no handshake
    end
end

// ------------------------------------------------ W SPY FIFO HANDLING LOGIC ------------------------------------------

// FIFO Signals for W-channel spy block
reg [DATA_WIDTH-1:0] w_data;
reg w_push;
reg w_pop; // assert -> when fifo is full and the next negedge is triggered
wire [DATA_WIDTH-1:0] w_pop_data;
wire w_full;
wire w_empty;
reg [3:0] prev_wid;

fifo #(
    .DATA_WIDTH(ADDR_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) w_spy_fifo
(
    .clk(clk),
    .reset(reset),
    .push_i(w_push),
    .push_data_i(w_data),
    .pop_i(w_pop),
    .pop_data_o(w_pop_data),
    .full_o(w_full),
    .empty_o(w_empty)
);

always@(posedge clk) begin
    if(w_handshake) begin
        if(prev_wid !== WID) begin
            prev_wid <= WID; // Store the current ID for next comparison
            w_push <= 1'b1; // Set push flag for new ID
            w_data <= WDATA;
            if(w_full) begin
                w_pop <= 1'b1; // Pop data if FIFO is full
            end 
            else begin
                w_pop <= 1'b0;
            end
        end 
        else begin
            prev_wid <= prev_wid; // Maintain previous wid
            w_push <= 1'b0; // Reset push flag if no new IDß
        end
    end
    else begin
        w_push <= 1'b0; // Reset push flag if no handshake
    end
end

// Logic to detect the first time the handshake occurs -> If we see a new ID during a valid transactiuon (when the handshake signal is high)

endmodule
