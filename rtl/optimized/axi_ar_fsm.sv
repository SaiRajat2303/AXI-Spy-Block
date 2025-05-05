module axi_ar_fsm #(
    parameter ADDR_WIDTH = 16,
    parameter ID_WIDTH = 4,
    parameter ID_COUNT = 1 << ID_WIDTH
)(
    // Standard inputs
    input clk,
    input reset,
    // Start of txn
    input start_txn,
    // Configuration Inputs
    input logic [ADDR_WIDTH-1:0] cfg_araddr,
    input logic [7:0] cfg_arlen,
    // (Not adding Burst mode as of now)
    // Deallocation
    input  logic                  dealloc_req,
    input  logic [ID_WIDTH-1:0]   dealloc_id,
    // De-allocation of an ID info should be relayed from R channel via central FSM controller
    // Output Interface
    output logic arvalid,
    output logic [ID_WIDTH-1:0] arid,
    output logic [ADDR_WIDTH-1:0] araddr,
    output logic [7:0] arlen,
    // Input from Slave
    input logic arready
);

    typedef enum logic [1:0] {
        IDLE,
        ALLOC_ID,
        SEND_AR,
        WAIT_HANDSHAKE
    } ar_fsm_state_e;

    ar_fsm_state_e state, next_state; // Variables for states of FSM
    logic [ID_WIDTH-1:0] arid_reg; // latching arid post an alloc

    // ID pool wires
    logic alloc_req;
    logic alloc_valid;
    logic [ID_WIDTH-1:0] alloc_id;

    // Instantiating the ID pool for AXI Reads
    axi_id_pool #(
        .ID_WIDTH(ID_WIDTH),
        .ID_COUNT(ID_COUNT)
    ) read_id_pool (
        .clk(clk),
        .reset(reset),
        .alloc_req(alloc_req),
        .alloc_valid(alloc_valid),
        .alloc_id(alloc_id),
        .dealloc_req(dealloc_req),
        .dealloc_id(dealloc_id)
    );

    // Implementing the FSM
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            state <= IDLE;
            arid_reg <= '0;
        end
        else begin
            state <= next_state;
            if (state == ALLOC_ID && alloc_valid) begin
                arid_reg <= alloc_id;
            end
        end
    end

   // FSM next state logic and output control
    always_comb begin
        next_state = state;
        alloc_req  = 0;
        arvalid    = 0;

        case (state)
            IDLE: begin
                if (start_txn)
                    next_state = ALLOC_ID;
            end

            ALLOC_ID: begin
                alloc_req = 1;
                if (alloc_valid) begin
                    next_state = SEND_AR;
                end
            end

            SEND_AR: begin
                arvalid = 1;
                if (arready)
                    next_state = IDLE;
                else
                    next_state = WAIT_HANDSHAKE;
            end

            WAIT_HANDSHAKE: begin
                arvalid = 1;
                if (arready)
                    next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
  // AXI Signal Assignments
  assign araddr  = cfg_araddr;
  assign arlen   = cfg_arlen;
  assign arid    = arid_reg;

endmodule
