module axi_traffic_generator #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64,
    parameter LEN_WIDTH  = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // AXI Write Address Channel
    output logic [ID_WIDTH-1:0]  awid,
    output logic [ADDR_WIDTH-1:0] awaddr,
    output logic [7:0]           awlen,
    output logic [2:0]           awsize,
    output logic [1:0]           awburst,
    output logic                 awvalid,
    input  logic                 awready,

    // AXI Write Data Channel
    output logic [DATA_WIDTH-1:0] wdata,
    output logic [(DATA_WIDTH/8)-1:0] wstrb,
    output logic                 wlast,
    output logic                 wvalid,
    input  logic                 wready,

    // AXI Write Response Channel
    input  logic [ID_WIDTH-1:0]  bid,
    input  logic [1:0]           bresp,
    input  logic                 bvalid,
    output logic                 bready,

    // AXI Read Address Channel
    output logic [ID_WIDTH-1:0]  arid,
    output logic [ADDR_WIDTH-1:0] araddr,
    output logic [7:0]           arlen,
    output logic [2:0]           arsize,
    output logic [1:0]           arburst,
    output logic                 arvalid,
    input  logic                 arready,

    // AXI Read Data Channel
    input  logic [ID_WIDTH-1:0]  rid,
    input  logic [DATA_WIDTH-1:0] rdata,
    input  logic [1:0]           rresp,
    input  logic                 rlast,
    input  logic                 rvalid,
    output logic                 rready
);

    typedef enum logic [1:0] {IDLE, SEND_WRITE, SEND_READ} state_t;
    state_t state, next_state;

    logic [3:0] count;
    logic wr_phase;

    // Random number generation (simple LFSR for example purposes)
    logic [31:0] rand_addr;
    logic [63:0] rand_data;
    logic [3:0]  rand_id;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rand_addr <= 32'h1;
            rand_data <= 64'hDEADBEEFCAFEBABE;
            rand_id   <= 4'h1;
        end else begin
            // Very simple LFSR-like random generator
            rand_addr <= {rand_addr[30:0], rand_addr[31] ^ rand_addr[21]};
            rand_data <= {rand_data[62:0], rand_data[63] ^ rand_data[50]};
            rand_id   <= {rand_id[2:0], rand_id[3] ^ rand_id[1]};
        end
    end

    // FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= 0;
            wr_phase <= 1;
        end else begin
            state <= next_state;
            if (state == SEND_WRITE && wvalid && wready)
                count <= count + 1;
            else if (state == SEND_READ && arvalid && arready)
                count <= count + 1;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (wr_phase)
                    next_state = SEND_WRITE;
                else
                    next_state = SEND_READ;
            end
            SEND_WRITE: begin
                if (wvalid && wready && wlast)
                    next_state = IDLE;
            end
            SEND_READ: begin
                if (arvalid && arready)
                    next_state = IDLE;
            end
        endcase
    end

    // Write logic
    assign awid     = rand_id;
    assign awaddr   = rand_addr;
    assign awlen    = 4; // burst of 5 beats
    assign awsize   = 3'b011; // 8 bytes
    assign awburst  = 2'b01; // INCR
    assign awvalid  = (state == SEND_WRITE);

    assign wdata    = rand_data;
    assign wstrb    = '1;
    assign wlast    = (count == 4);
    assign wvalid   = (state == SEND_WRITE);

    assign bready   = 1'b1;

    // Read logic
    assign arid     = rand_id;
    assign araddr   = rand_addr;
    assign arlen    = 4;
    assign arsize   = 3'b011;
    assign arburst  = 2'b01;
    assign arvalid  = (state == SEND_READ);

    assign rready   = 1'b1;

    // Alternate between read/write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_phase <= 1;
        else if (state == IDLE)
            wr_phase <= ~wr_phase;
    end

endmodule
