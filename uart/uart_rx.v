module uart_rx #(parameter CLK_PER_BIT) (
    input i_rx, clk,
    output [7:0] o_data,
    output o_recv, o_conn
);
    parameter STATE_LOST = 3'd0;
    parameter STATE_IDLE = 3'd1;
    parameter STATE_START_BIT = 3'd2;
    parameter STATE_PAYLOAD_BITS = 3'd3;
    parameter STATE_STOP_BIT = 3'd4;
    parameter STATE_CLEAN = 3'd5;

    reg r_rx_buf = 1'b0;
    reg r_rx = 1'b0;

    reg [7:0] r_data = 8'd0;
    reg [2:0] r_data_ind = 3'd0;
    reg [2:0] r_state = 3'd0;
    reg [15:0] r_clk_count = 16'd0;
    reg r_recv = 1'b0;
    reg r_conn = 1'b0;

    assign o_data = r_data;
    assign o_recv = r_recv;
    assign o_conn = r_conn;

    always @(posedge clk) begin //idk why
        r_rx <= r_rx_buf;
        r_rx_buf <= i_rx;
    end

    always @(posedge clk) begin
        case (r_state)
            STATE_LOST: begin
                r_recv <= 1'b0;
                r_clk_count <= 16'd0;
                r_data_ind <= 3'd0;
                r_conn <= 1'b0;

                if (r_rx) r_state <= STATE_IDLE;
                else r_state <= STATE_LOST;
            end
            STATE_IDLE: begin
                r_recv <= 1'b0;
                r_clk_count <= 16'd0;
                r_data_ind <= 3'd0;
                r_conn <= 1'b1;

                if (r_rx) r_state <= STATE_IDLE;
                else r_state <= STATE_START_BIT;
            end
            STATE_START_BIT: begin
                if (r_clk_count == (CLK_PER_BIT-1)/2) begin //middle of data
                    if (r_rx == 1'b0) begin
                        r_clk_count <= 16'd0;
                        r_state <= STATE_PAYLOAD_BITS;
                    end
                    else r_state <= STATE_IDLE;
                end else begin
                    r_clk_count <= r_clk_count + 16'd1;
                    r_state <= STATE_START_BIT;
                end
            end
            STATE_PAYLOAD_BITS: begin
                if (r_clk_count < CLK_PER_BIT-1) begin
                    r_state <= STATE_PAYLOAD_BITS;
                    r_clk_count <= r_clk_count + 16'd1;
                end else begin
                    r_clk_count <= 16'd0;
                    r_data[r_data_ind] <= r_rx;

                    if (r_data_ind < 3'd7) begin
                        r_state <= STATE_PAYLOAD_BITS;
                        r_data_ind <= r_data_ind + 3'd1;
                    end else begin
                        r_state <= STATE_STOP_BIT;
                        r_data_ind <= 3'd0;
                    end
                end
            end
            STATE_STOP_BIT: begin
                if (r_clk_count < CLK_PER_BIT-1) begin
                    r_state <= STATE_STOP_BIT;
                    r_clk_count <= r_clk_count + 16'd1;
                end else if (r_rx) begin
                    r_recv <= 1'b1;
                    r_clk_count <= 16'd0;
                    r_state <= STATE_CLEAN;
                    r_conn <= 1'b1;
                end else begin
                    r_recv <= 1'b0;
                    r_clk_count <= 16'd0;
                    r_state <= STATE_LOST;
                    r_conn <= 1'b0;
                end
            end 
            STATE_CLEAN: begin
                r_recv <= 1'b0;
                r_state <= STATE_IDLE;
            end
            default: r_state <= STATE_IDLE;
        endcase
    end
    
endmodule