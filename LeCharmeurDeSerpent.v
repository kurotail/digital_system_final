module LeCharmeurDeSerpent (
    input sys_rx, sys_clk,
    output sys_tx,

    output [41:0] o_seven_segments,

    output [7:0] o_dot_matrix_row,
    output [15:0] o_dot_matrix_col,

    input [2:0] i_keypad_col,
    output [2:0] o_keypad_row,

    //debug
    output [8:0] detectedKeys
);
    parameter SYS_CLK_FREQUENCY = 50_000_000;
    parameter BAUD_RATE = 9600;
    parameter CONN_TIMEOUT = 25_000_000;
    parameter LOST_DOTS = 128'h8EEE_8A84_8A84_8A84_8AE4_8A24_8A24_EEE4;

    reg [31:0] r_timeout_counter = 32'd0;
    reg r_lost_conn = 1'b0;

    wire w_tx_key_send;
    wire w_tx_keypad_proc;
    wire w_rx_ctrl_conn;
    wire w_rx_recv;
    wire [7:0] w_tx_key;
    wire [15:0] w_score_bin;
    wire [19:0] w_score_bcd;
    wire [127:0] w_rx_dot;
    wire [127:0] w_dots = r_lost_conn ? LOST_DOTS:w_rx_dot;
    
    seven_seg #(6) SevenEncoder (
        .num({4'd0, w_score_bcd}),
        .rst(~r_lost_conn),
        .sig_out(o_seven_segments)
        );

    bin2bcd #(16) BcdEncoder (
        .bin(w_score_bin),
        .bcd(w_score_bcd)
        );


    RXCtrl #(.CLK_PER_BIT(SYS_CLK_FREQUENCY/BAUD_RATE)) RX (
        .i_rx(sys_rx), 
        .i_rst_reg(r_lost_conn),
        .clk(sys_clk),
        .o_ctrl_conn(w_rx_ctrl_conn),
        .o_score(w_score_bin),
        .o_dot(w_rx_dot),
        .o_state_count(),
        .o_recv(w_rx_recv)
        );

    TXCtrl #(.CLK_PER_BIT(SYS_CLK_FREQUENCY/BAUD_RATE)) TX (
	    .clk(sys_clk),
        .i_ctrl_conn(w_rx_ctrl_conn),
        .i_lost(r_lost_conn),
        .i_keypad_data(w_tx_key),
        .i_keypad_send(w_tx_key_send),
        .o_tx(sys_tx),
        .o_keypad_proc(w_tx_keypad_proc),
        .o_state_count()
        );

    DotMatrixControl DotMatCtrl (
        .clk(sys_clk),
        .dotmatrix_reg(w_dots),
        .row_select(o_dot_matrix_row),
        .col_output(o_dot_matrix_col)
        );

    KeyInCtrl KeypadInput (
        .clk(sys_clk),
        .i_tx_keypad_proc(w_tx_keypad_proc),
        .i_keypad_col(i_keypad_col),
        .o_keypad_row(o_keypad_row),
        .o_key(w_tx_key),
        .o_tx_key_send(w_tx_key_send),
        .detectedKeys(detectedKeys)
        );

    always @(posedge sys_clk) begin
        if (r_timeout_counter < CONN_TIMEOUT) begin
            if (w_rx_recv) r_timeout_counter <= 32'd0;
            else  r_timeout_counter <= r_timeout_counter + 32'd1;

            r_lost_conn <= 1'b0;
        end else begin
            if (w_rx_recv) r_timeout_counter <= 32'd0;
            else r_lost_conn <= 1'b1;
        end
    end
    
endmodule

module seven_seg #(parameter DIGITS = 1) (
	input [DIGITS*4-1:0] num,
    input rst,
	output reg [DIGITS*7-1:0] sig_out
);
    integer i;

	always @(*)
        if (rst) begin
            for (i = 0; i < DIGITS; i = i + 1) begin
                case(num[(i+1)*4-1-:4])
                    0 : sig_out[(i+1)*7-1 -:7] <= 7'b1000000;
                    1 : sig_out[(i+1)*7-1 -:7] <= 7'b1111001;
                    2 : sig_out[(i+1)*7-1 -:7] <= 7'b0100100;
                    3 : sig_out[(i+1)*7-1 -:7] <= 7'b0110000;
                    4 : sig_out[(i+1)*7-1 -:7] <= 7'b0011001;
                    5 : sig_out[(i+1)*7-1 -:7] <= 7'b0010010;
                    6 : sig_out[(i+1)*7-1 -:7] <= 7'b0000010;
                    7 : sig_out[(i+1)*7-1 -:7] <= 7'b1111000;
                    8 : sig_out[(i+1)*7-1 -:7] <= 7'b0000000;
                    9 : sig_out[(i+1)*7-1 -:7] <= 7'b0010000;
                    10: sig_out[(i+1)*7-1 -:7] <= 7'b0001000;
                    11: sig_out[(i+1)*7-1 -:7] <= 7'b0000011;
                    12: sig_out[(i+1)*7-1 -:7] <= 7'b1000110;
                    13: sig_out[(i+1)*7-1 -:7] <= 7'b0100001;
                    14: sig_out[(i+1)*7-1 -:7] <= 7'b0000110;
                    15: sig_out[(i+1)*7-1 -:7] <= 7'b0001110;
                endcase 
            end
        end else begin
            for (i = 0; i < DIGITS; i = i + 1) begin
                sig_out[(i+1)*7-1 -:7] <= 7'b0111111;
            end
        end
endmodule

module pulse (
    input flag, clk,
    output reg pulse
);
    reg triggered = 1'b0;
    always @(posedge clk) begin
        if (triggered) begin
            pulse <= 1'b0;
            if (flag) begin
                triggered <= 1'b1;
                pulse <= 1'b0;
            end else begin
                triggered <= 1'b0;
                pulse <= 1'b0;
            end
        end
        else begin
            if (flag) begin
                triggered <= 1'b1;
                pulse <= 1'b1;
            end else begin
                triggered <= 1'b0;
                pulse <= 1'b0;
            end
        end
    end
endmodule
