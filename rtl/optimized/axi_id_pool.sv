module axi_id_pool #(
    parameter integer ID_WIDTH = 4,
    parameter integer ID_COUNT = 1 << ID_WIDTH
)
(
    input clk,
    input reset,

    // Allocation signals
    output alloc_valid,
    input alloc_req,
    output reg [ID_WIDTH-1:0] alloc_id,

    // De-Allocation signals
    input dealloc_req,
    input reg [ID_WIDTH-1:0] dealloc_id

);

// Not handling the corner case where De-Alloc request comes in while all IDs are un-allocated
// Usage would happen whenever an ID appears on B or R - channel
// B or R - channel wouldnt give out an ID which hasnt been allocated

reg [ID_WIDTH-1:0] id_queue [ID_COUNT-1:0]; 
// 16 entry queue for wrapping
reg [ID_WIDTH:0] alloc_ptr ;
reg [ID_WIDTH:0] dealloc_ptr;
// Not using a wrap bit since we have a count variable

reg [ID_WIDTH:0] count; // Maintains count of free IDs

always@(posedge clk or posedge reset) begin
    if(reset) begin
        // Set up the queue upon reset
        alloc_ptr <= '0;
        dealloc_ptr <= '0;
        count <= ID_COUNT;
        for(int i=0 ; i<ID_COUNT; i=i+1) begin
            id_queue[i] <= i[ID_WIDTH-1:0];
        end
    end
    else if(alloc_req && alloc_valid) begin
        alloc_ptr <= alloc_ptr + 1;
        count <= count - 1;
        // Increment Alloc Ptr after an allocation
        // Allocation should only happen when alloc_valid = high
        // Alloc_Vld goes low when all entries in the ID_queue have been used up
        // Fifo Full case -> in summary
    end
    else if(dealloc_req) begin
        id_queue[dealloc_ptr] <= dealloc_id;
        dealloc_ptr <= dealloc_ptr + 1;
        count <= count + 1;
    end
end


assign  alloc_valid = ~((alloc_ptr[ID_WIDTH-1:0] == dealloc_ptr[ID_WIDTH-1:0]) && (alloc_ptr[ID_WIDTH] != dealloc_ptr[ID_WIDTH]));
assign  alloc_id = id_queue[alloc_ptr[ID_WIDTH-1:0]];

endmodule
