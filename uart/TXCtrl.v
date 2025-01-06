module TXCtrl #(parameter CLK_PER_BIT) (
    input clk, i_ctrl_conn, i_lost, i_keypad_send,
    input [7:0] i_keypad_data,
    output o_tx, o_keypad_proc,
    output [1:0] o_state_count
);
    parameter STATE_LOST = 2'd0;
    parameter STATE_IDLE = 2'd1;
    parameter STATE_START_CLK = 2'd2;
    parameter STATE_BUSY = 2'd3;

    reg [7:0] r_data = 8'd0;
    reg [1:0] r_state = 2'd0;  assign o_state_count = r_state;
    reg r_tx_flag = 1'b0;
    reg r_ctrl_conn = 1'b0;
    reg r_keypad_proc = 1'b0;

    wire w_tx_busy;

    assign o_keypad_proc = r_keypad_proc;

    uart_tx #(CLK_PER_BIT) TX (
        .i_data(r_data),
        .clk(clk),
        .i_send(r_tx_flag),
        .o_tx(o_tx),
        .o_done(),
        .o_busy(w_tx_busy)
        );
    
    always @(posedge clk) begin
        if (i_ctrl_conn) r_ctrl_conn <= 1'b1;

        case (r_state)
            STATE_LOST: begin
                if (r_ctrl_conn) begin
                    r_state <= STATE_START_CLK;
                    r_tx_flag <= 1'b1;
                    r_data <= 8'hff;
                    r_ctrl_conn <= 1'b0;
                end
                else if (i_lost) r_state <= STATE_LOST;
                else r_state <= STATE_IDLE;
            end
            STATE_IDLE: begin
                if (r_ctrl_conn) begin
                    r_state <= STATE_START_CLK;
                    r_tx_flag <= 1'b1;
                    r_data <= 8'hff;
                    r_ctrl_conn <= 1'b0;
                end
                else if (i_lost) r_state <= STATE_LOST;
                else if (i_keypad_send) begin
                    r_state <= STATE_START_CLK;
                    r_tx_flag <= 1'b1;
                    r_data <= i_keypad_data;
                    r_keypad_proc <= 1'b1;
                end
            end
            STATE_START_CLK: begin
                r_state <= STATE_BUSY;
                r_tx_flag <= 1'b0;
                r_keypad_proc <= 1'b0;
            end
            STATE_BUSY: begin
                if (w_tx_busy) r_state <= STATE_BUSY;
                else r_state <= STATE_IDLE;
            end
            default: r_state <= STATE_LOST;
        endcase
    end
    
endmodule