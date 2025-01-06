module KeyInCtrl (
    input clk, i_tx_keypad_proc,
    input [2:0] i_keypad_col,
    output [2:0] o_keypad_row,
    output [7:0] o_key,
    output o_tx_key_send,
    output [8:0] detectedKeys
);
    parameter KEY_WASD = 32'h77617364;

    wire [8:0] w_detected_keys;
    wire [3:0] w_pressed_key;

    reg r_tx_key_send = 1'b0;
    reg [7:0] r_key = 8'd0;

    assign o_tx_key_send = r_tx_key_send;
    assign o_key = r_key;
    assign detectedKeys = w_detected_keys;

    KeypadDriver Driver (
        .clk(clk),
        .keypadCol(i_keypad_col),
        .keypadRow(o_keypad_row),
        .detectedKeys(w_detected_keys)
        );

    pulse KeyPressedW (
        .flag(w_detected_keys[7]),
        .clk(clk),
        .pulse(w_pressed_key[3])
    );
    pulse KeyPressedA (
        .flag(w_detected_keys[5]),
        .clk(clk),
        .pulse(w_pressed_key[2])
    );
    pulse KeyPressedS (
        .flag(w_detected_keys[1]),
        .clk(clk),
        .pulse(w_pressed_key[1])
    );
    pulse KeyPressedD (
        .flag(w_detected_keys[3]),
        .clk(clk),
        .pulse(w_pressed_key[0])
    );

    always @(posedge clk) begin
        if (w_pressed_key != 4'd0) begin
            r_tx_key_send <= 1'b1;

            if (w_pressed_key[3])      r_key <= KEY_WASD[31:24];
            else if (w_pressed_key[2]) r_key <= KEY_WASD[23:16];
            else if (w_pressed_key[1]) r_key <= KEY_WASD[15:8 ];
            else if (w_pressed_key[0]) r_key <= KEY_WASD[7 :0 ];

        end else if (i_tx_keypad_proc) begin
            r_tx_key_send <= 1'b0;
            r_key <= 8'd0;
        end
    end

endmodule

module KeypadDriver (
    input clk,
    input [2:0] keypadCol,         // 3 列輸入
    output reg [2:0] keypadRow,    // 3 行輸出
    output reg [8:0] detectedKeys   //output
);

    reg [1:0] currentRow;          // 用於行掃描 (僅需 2-bit，對應 3 行)
    reg [31:0] clk_count = 32'd0;

    always @(posedge clk) begin

        if (clk_count < 32'd10_000) begin
            clk_count <= clk_count + 32'd1;
        end else begin
            clk_count <= 32'd0;
            // 行掃描：依次激活每一行
            case (currentRow)
                2'b00: keypadRow <= 3'bzz0;  // 激活第 0 行
                2'b01: keypadRow <= 3'bz0z;  // 激活第 1 行
                2'b10: keypadRow <= 3'b0zz;  // 激活第 2 行
                default: keypadRow <= 3'bzzz;
            endcase

            // 偵測按鍵，更新對應行列的按鍵狀態
            case (currentRow)
                2'b01: detectedKeys[2:0]   <= keypadCol ^ 3'b111; // 第 0 行
                2'b10: detectedKeys[5:3]   <= keypadCol ^ 3'b111; // 第 1 行
                2'b11: detectedKeys[8:6]   <= keypadCol ^ 3'b111; // 第 2 行
                default:;
            endcase

            // 行掃描移到下一行
            currentRow <= currentRow + 2'd1;
        end
    end
endmodule