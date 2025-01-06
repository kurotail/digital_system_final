//control signal: 0x00,    0x01,       0x02
//                connect, sync score, sync map
//return:         0xff,    none,       none

module RXCtrl #(parameter CLK_PER_BIT) (
    input i_rx, clk, i_rst_reg,
    output o_ctrl_conn, o_recv,
    output [15:0] o_score,
    output [127:0] o_dot,
    output [4:0] o_state_count
);
    parameter STATE_IDLE = 2'd0;
    parameter STATE_CONNECT = 2'd1;
    parameter STATE_SYNC_SCORE = 2'd2;
    parameter STATE_SYNC_MAP = 2'd3;

    parameter CTRL_CONN = 8'h00;
    parameter CTRL_SYNC_SCORE = 8'h01;
    parameter CTRL_SYNC_SCORE_LEN = 2;
    parameter CTRL_SYNC_MAP = 8'h02;
    parameter CTRL_SYNC_MAP_LEN = 16;

    integer i;

    reg [1:0] r_state = 2'd0;
    reg [4:0] r_state_count = 5'd0;  assign o_state_count = r_state_count;
    reg [15:0] r_score = 16'd0;
    reg [127:0] r_dot = 128'd0;
    reg r_ctrl_conn = 1'b0;

    wire w_rx_recv;
    wire [7:0] w_rx_payload;

    assign o_ctrl_conn = r_ctrl_conn;
    assign o_score = r_score;
    assign o_dot = r_dot;
    assign o_recv = w_rx_recv;

    uart_rx #(CLK_PER_BIT) RX (
        .i_rx(i_rx),
        .clk(clk),
        .o_data(w_rx_payload),
        .o_recv(w_rx_recv)
        );

    always @(posedge clk) begin
        case (r_state)
            STATE_IDLE: begin
                r_ctrl_conn <= 1'b0;
                r_state_count <= 5'd0;

                if (i_rst_reg) begin
                    r_score <= 16'd0;
                    r_dot = 128'd0;
                end

                if (w_rx_recv) begin
                    case (w_rx_payload)
                        CTRL_CONN: r_state <= STATE_CONNECT;
                        CTRL_SYNC_SCORE: r_state <= STATE_SYNC_SCORE;
                        CTRL_SYNC_MAP: r_state <= STATE_SYNC_MAP;
                        default: r_state <= STATE_IDLE;
                    endcase
                end
                else r_state <= STATE_IDLE;
            end
            STATE_CONNECT: begin
                r_state <= STATE_IDLE;
                r_ctrl_conn <= 1'b1;
            end
            STATE_SYNC_SCORE: begin
                if (r_state_count < CTRL_SYNC_SCORE_LEN) begin
                    if (w_rx_recv) begin
                        r_state <= STATE_SYNC_SCORE;
                        r_state_count <= r_state_count + 5'd1;
                        for (i = 0; i < CTRL_SYNC_SCORE_LEN; i = i + 1) begin
                            if (r_state_count == i[4:0]) r_score[(CTRL_SYNC_SCORE_LEN-i)*8-1 -:8] <= w_rx_payload;
                        end
                    end 
                    else r_state <= STATE_SYNC_SCORE;
                end else begin
                    r_state <= STATE_IDLE;
                    r_state_count <= 5'd0;
                end
            end
            STATE_SYNC_MAP: begin
                if (r_state_count < CTRL_SYNC_MAP_LEN)begin
                    if (w_rx_recv) begin
                        r_state <= STATE_SYNC_MAP;
                        r_state_count <= r_state_count + 5'd1;
                        for (i = 0; i < CTRL_SYNC_MAP_LEN; i = i + 1) begin
                            if (r_state_count == i[4:0]) r_dot[(CTRL_SYNC_MAP_LEN-i)*8-1 -:8] <= w_rx_payload;
                        end
                    end
                    else r_state <= STATE_SYNC_MAP;
                end else begin
                    r_state <= STATE_IDLE;
                    r_state_count <= 5'd0;
                end
            end
            default: r_state <= STATE_IDLE;
        endcase
    end

endmodule
