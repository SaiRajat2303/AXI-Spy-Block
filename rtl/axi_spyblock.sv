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
    input [ADDR_WIDTH-1:0] ARADDR,

    // AXI AW channel signals
    input AWVALID,
    input AWREADY,
    input [ADDR_WIDTH-1:0] AWADDR,

    // AXI W channel signals
    input WVALID,
    input WREADY,
    input [DATA_WIDTH-1:0] WDATA,

    // AXI R channel signals 
    input RVALID,
    input RREADY,
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

// FIFO signals for R-channel spy block
reg [DATA_WIDTH-1:0] rdat;
reg r_push;
reg r_pop; // assert -> when fifo is full and the next negedge is triggered
wire [DATA_WIDTH-1:0] r_pop_data;
wire r_full;
wire r_empty;
wire r_trig;
reg r_trig_d1;
wire r_trig_neg;

assign r_trig = (RREADY == 1'b1)?(RREADY ^ RVALID):(1'b1);
assign r_trig_neg = r_trig_d1 & ~r_trig; // negative edge detector
assign r_spy_full = r_full;

fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) r_spy_fifo
(
    .clk(clk),
    .reset(reset),
    .push_i(r_push),
    .push_data_i(rdat),
    .pop_i(r_pop),
    .pop_data_o(r_pop_data),
    .full_o(r_full),
    .empty_o(r_empty)
);

// FIFO signals for AR-channel spy block
reg [DATA_WIDTH-1:0] ar_addr;
reg ar_push;
reg ar_pop; // assert -> when fifo is full and the next negedge is triggered
wire [DATA_WIDTH-1:0] ar_pop_addr;
wire ar_full;
wire ar_empty;
wire ar_trig;
reg ar_trig_d1;
wire ar_trig_neg;

assign ar_trig = (ARREADY == 1'b1)?(ARREADY ^ ARVALID):(1'b1);
assign ar_trig_neg = ar_trig_d1 & ~ar_trig; // negative edge detector
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

// FIFO Signals for AW-channel spy block
reg [DATA_WIDTH-1:0] aw_addr;
reg aw_push;
reg aw_pop; // assert -> when fifo is full and the next negedge is triggered
wire [DATA_WIDTH-1:0] aw_pop_addr;
wire aw_full;
wire aw_empty;
wire aw_trig;
reg aw_trig_d1;
wire aw_trig_neg;

assign aw_trig = (ARREADY == 1'b1)?(ARREADY ^ ARVALID):(1'b1);
assign aw_trig_neg = aw_trig_d1 & ~aw_trig; // negative edge detector
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

// FIFO Signals for W-channel spy block
reg [DATA_WIDTH-1:0] w_data;
reg w_push;
reg w_pop; // assert -> when fifo is full and the next negedge is triggered
wire [DATA_WIDTH-1:0] w_pop_data;
wire w_full;
wire w_empty;
wire w_trig;
reg w_trig_d1;
wire w_trig_neg;

assign w_trig = (WREADY == 1'b1)?(WREADY ^ WVALID):(1'b1);
assign w_trig_neg = w_trig_d1 & ~w_trig; // negative edge detector
assign w_spy_full = w_full;

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

// We dont really need a reset handling here for spy fifos , as they reset on their own

always@(posedge clk) begin
    // R spyblock handling
    r_trig_d1 <= r_trig; // 1 cycle delayed version of r_trig
    ar_trig_d1 <= ar_trig; 
    aw_trig_d1 <= aw_trig;
    w_trig_d1 <= w_trig;

    if(r_trig_neg) begin
        rdat <= RDATA;
        r_push <= 1'b1;
        if(r_full) begin
            r_pop <= 1'b1;
        end
    end
    else begin
        rdat <= 0;
        r_push <= 1'b0;
        r_pop <= 1'b0;
    end

    if(ar_trig_neg) begin
        ar_addr <= ARADDR;
        ar_push <= 1'b1;
        if(ar_full) begin
            ar_pop <= 1'b1;
        end
    end
    else begin
        ar_addr <= 0;
        ar_push <= 1'b0;
        ar_pop <= 1'b0;
    end

    if(aw_trig_neg) begin
        aw_addr <= ARADDR;
        aw_push <= 1'b1;
        if(aw_full) begin
            aw_pop <= 1'b1;
        end
    end
    else begin
        aw_addr <= 0;
        aw_push <= 1'b0;
        aw_pop <= 1'b0;
    end

    if(w_trig_neg) begin
        w_data <= WDATA;
        w_push <= 1'b1;
        if(w_full) begin
            w_pop <= 1'b1;
        end
    end
    else begin
        w_data <= 0;
        w_push <= 1'b0;
        w_pop <= 1'b0;
    end

end


// Logic to detect the first time the handshake occurs ->

/*
Use trigger_signal wire -> need this.
Place a conditional operator that checks whether the slave is ready or not 
if the slave isnt ready , i.e. ready == 0 , tie the trigg to ative 1
If the slave is ready , then tie to the EXOR of both ready and valid
EXOR both the VALID and the READY signals -> This signal remains active 1 , until both of them go to 1
the case where both valid and ready are 0 is taken care of by the conditional assignment
now use a negedge detector for detecting when the handshake occurs for the first time -> then push the parameters into fifo
*/

endmodule
