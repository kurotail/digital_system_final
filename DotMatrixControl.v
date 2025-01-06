module DotMatrixControl(
    input clk,
    input [127:0] dotmatrix_reg, // 128 bits input, each bit controls a point
    output [7:0] row_select,     // Row select signals
    output [15:0] col_output     // Column data output
);

    // Internal signals
    reg [15:0] clk_div_counter = 16'd0;   // Clock divider counter
    reg clk_div = 1'b0;                   // Clock divider output
    reg [2:0] current_row = 3'd0;         // Current row being scanned (0-7)
    
    // Row and column signals
    reg [7:0] row_select_reg = 8'b0;
    reg [15:0] col_output_reg = 16'b0;

    // Clock divider to generate ~10 kHz clock
    always @(posedge clk) begin
        if (clk_div_counter == 16'd2499) begin
            clk_div_counter <= 16'd0;
            clk_div <= ~clk_div;
        end else begin
            clk_div_counter <= clk_div_counter + 16'd1;
        end
    end

    // Assign outputs
    assign row_select = ~row_select_reg;
    assign col_output = col_output_reg;

    // Scanning Logic
    always @(posedge clk_div) begin
        // Increment current row
        current_row <= current_row + 3'd1;

        // Update row select signal (one-hot encoding)
        row_select_reg <= 8'b00000001 << current_row;

        // Extract corresponding 16 bits from dotmatrix_reg for the current row
        col_output_reg <= dotmatrix_reg[(current_row+1)*16-1 -: 16];
    end

endmodule

