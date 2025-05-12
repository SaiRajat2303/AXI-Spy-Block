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
    input [ADDR_WIDTH-1:0] AW_ADDR,

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

// We dont really need a reset handling here for spy fifos , as they reset on their own

always@(posedge clk) begin
    // R spyblock handling
    r_trig_d1 <= r_trig; // 1 cycle delayed version of r_trig
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

