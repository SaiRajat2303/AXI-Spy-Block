// Master Module for Generating AXI Traffic 
// Inputs driven by the Testbench

module axi_master_gen #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input  logic              ACLK,
    input  logic              ARESETN,

    // Write address channel
    output logic [ID_WIDTH-1:0]    AWID,
    output logic [ADDR_WIDTH-1:0]  AWADDR,
    output logic [7:0]             AWLEN,
    output logic [2:0]             AWSIZE,
    output logic [1:0]             AWBURST,
    output logic                   AWVALID,
    input  logic                   AWREADY,

    // Write data channel
    output logic [DATA_WIDTH-1:0]  WDATA,
    output logic                   WVALID,
    output logic                   WLAST,
    output logic [(DATA_WIDTH/8)-1:0] WSTRB,
    input  logic                   WREADY,

    // Write response channel
    input  logic [1:0]             BRESP,
    input  logic                   BVALID,
    output logic                   BREADY,

    // Read address channel
    output logic [ID_WIDTH-1:0]    ARID,
    output logic [ADDR_WIDTH-1:0]  ARADDR,
    output logic [7:0]             ARLEN,
    output logic [2:0]             ARSIZE,
    output logic [1:0]             ARBURST,
    output logic                   ARVALID,
    input  logic                   ARREADY,

    // Read data channel
    input  logic [DATA_WIDTH-1:0]  RDATA,
    input  logic                   RVALID,
    input  logic                   RLAST,
    output logic                   RREADY
);

    typedef enum logic [1:0] {
        IDLE, SEND_WRITE, SEND_READ
    } state_t;

    state_t state;
    int burst_count;
    logic [ADDR_WIDTH-1:0] base_addr;

    always_ff @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            state       <= IDLE;
            AWVALID     <= 0;
            WVALID      <= 0;
            ARVALID     <= 0;
            BREADY      <= 0;
            RREADY      <= 0;
            burst_count <= 0;
            base_addr   <= 32'h0000_0000;
        end else begin
            case (state)
                IDLE: begin
                    // Send a write transaction
                    AWID    <= 0;
                    AWADDR  <= base_addr;
                    AWLEN   <= 4;  // 5-beat burst
                    AWSIZE  <= 3'b010;  // 4 bytes
                    AWBURST <= 2'b01;   // INCR
                    AWVALID <= 1;
                    state   <= SEND_WRITE;
                end

                SEND_WRITE: begin
                    if (AWREADY && AWVALID) begin
                        AWVALID <= 0;
                        burst_count <= 0;
                        WVALID <= 1;
                        WSTRB <= '1;
                        WDATA <= 32'hA5A5A5A5;
                    end
                    if (WREADY && WVALID) begin
                        burst_count <= burst_count + 1;
                        if (burst_count == 4) begin
                            WLAST <= 1;
                        end else begin
                            WLAST <= 0;
                        end
                        if (burst_count == 5) begin
                            WVALID <= 0;
                            WLAST <= 0;
                            BREADY <= 1;
                        end
                    end
                    if (BVALID && BREADY) begin
                        BREADY <= 0;
                        // Start a read transaction
                        ARID    <= 0;
                        ARADDR  <= base_addr;
                        ARLEN   <= 4;
                        ARSIZE  <= 3'b010;
                        ARBURST <= 2'b01;
                        ARVALID <= 1;
                        state   <= SEND_READ;
                    end
                end

                SEND_READ: begin
                    if (ARVALID && ARREADY) begin
                        ARVALID <= 0;
                        RREADY <= 1;
                    end
                    if (RVALID && RREADY) begin
                        if (RLAST) begin
                            RREADY <= 0;
                            base_addr <= base_addr + 32'h0000_0020;
                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end

endmodule