module uart_tx #(parameter CLK_PER_BIT) (
    input [7:0] i_data,
	input clk, i_send,
    output o_tx, o_done, o_busy
);
    parameter STATE_IDLE = 3'd0;
    parameter STATE_START_BIT = 3'd1;
    parameter STATE_PAYLOAD_BITS = 3'd2;
    parameter STATE_STOP_BIT = 3'd3;
    parameter STATE_CLEAN = 3'd4;

    reg [7:0] r_data = 8'd0;
    reg [2:0] r_data_ind = 3'd0;
    reg [2:0] r_state = 3'd0;
    reg [15:0] r_clk_count = 16'd0;
    reg r_done = 1'b0;  //high when operation is done for 1clk
    reg r_tx = 1'b0;
    reg r_busy = 1'b0;

    assign o_done = r_done;
    assign o_tx = r_tx;
    assign o_busy = r_busy;

    always @(posedge clk) begin
        case (r_state)
            STATE_IDLE: begin
                r_tx <= 1'b1;
                r_clk_count <= 16'd0;
                r_done <= 1'b0;
                r_data_ind <= 3'd0;

                if (i_send) begin
                    r_state <= STATE_START_BIT;
                    r_data <= i_data;
                    r_busy <= 1'b1;
                end
                else r_state <= STATE_IDLE;
            end
            STATE_START_BIT: begin
                r_tx <= 1'b0;
                
                if (r_clk_count < CLK_PER_BIT-1) begin
                    r_clk_count <= r_clk_count + 16'd1;
                    r_state <= STATE_START_BIT;
                end else begin
                    r_clk_count <= 16'd0;
                    r_state <= STATE_PAYLOAD_BITS;
                end
            end
            STATE_PAYLOAD_BITS: begin
                r_tx <= r_data[r_data_ind];

                if (r_clk_count < CLK_PER_BIT-1) begin
                    r_clk_count <= r_clk_count + 16'd1;
                    r_state <= STATE_PAYLOAD_BITS;
                end else begin
                    r_clk_count <= 16'd0;  

                    if (r_data_ind < 7) begin
                        r_data_ind = r_data_ind + 3'd1;
                        r_state <= STATE_PAYLOAD_BITS;  
                    end else begin
                        r_data_ind <= 3'd0;
                        r_state <= STATE_STOP_BIT;
                    end
                end
            end
            STATE_STOP_BIT: begin
                r_tx <= 1'b1;

                if (r_clk_count < CLK_PER_BIT-1) begin
                    r_clk_count <= r_clk_count + 16'd1;
                    r_state <= STATE_STOP_BIT;
                end else begin
                    r_clk_count <= 16'd0;
                    r_state <= STATE_CLEAN;
                    r_done <= 1'b1;
                    r_busy <= 1'b1;
                end
            end
            STATE_CLEAN: begin
                r_done <= 1'b0;
                r_busy <= 1'b0;
                r_state <= STATE_IDLE;
            end
            default: r_state <= STATE_IDLE;
        endcase
    end

endmodule
