`default_nettype none

module serial_audio_decoder #(parameter audio_width = 32)(
    input wire sclk,
    input wire reset,
    input wire lrclk,
    input wire sdin,
    input wire is_i2s,
    input wire lrclk_polarity,
    output reg is_error,
    output reg o_valid,
    input wire o_ready,
    output reg o_is_left,
    output reg [audio_width-1:0] o_audio);

    reg [4:0] bit_count;
    reg [31:0] shift_data;
    reg [1:0] lr_history;

    wire is_current_channel_left = lrclk == lrclk_polarity;
    wire is_lr_changed = is_i2s ? (lr_history[0] != lr_history[1]) : (lr_history[0] != is_current_channel_left);

    localparam [31:0] ZERO = 0;

    always @(posedge sclk or posedge reset) begin
        if (reset) begin
            o_is_left <= lrclk_polarity;
            bit_count <= 0;
            lr_history <= 2'b00;
            shift_data <= 0;
            o_audio <= 0;
            is_error <= 1'b0;
            o_valid <= 1'b0;
        end else begin
            shift_data <= { shift_data[30:0], sdin };
            lr_history <= { lr_history[0], is_current_channel_left };
            bit_count <= is_lr_changed ? 1'b0 : bit_count + 1'b1;

            if (is_lr_changed && o_is_left != lr_history[1]) begin
                case (bit_count)
                    5'd31: begin // 32bit
                        o_audio <= shift_data[31:32 - audio_width];
                        is_error <= 1'b0;
                        o_is_left <= lr_history[1];
                        o_valid <= 1'b1;
                    end
                    5'd23: begin // 24bit
                        o_audio <= (audio_width > 24) ? { shift_data[23:0], ZERO[audio_width - 1 - 24:0] } : shift_data[23:24 - audio_width];
                        is_error <= 1'b0;
                        o_is_left <= lr_history[1];
                        o_valid <= 1'b1;
                    end
                    5'd15: begin // 16bit
                        o_audio <= (audio_width > 16) ? { shift_data[15:0], ZERO[audio_width - 1 - 16:0] } : shift_data[15:16 - audio_width];
                        is_error <= 1'b0;
                        o_is_left <= lr_history[1];
                        o_valid <= 1'b1;
                    end
                    default: begin  //error
                        o_audio <= shift_data[31:32 - audio_width];
                        is_error <= 1'b1;
                        o_is_left <= lrclk_polarity;
                        o_valid <= 1'b0;
                    end
                endcase
            end else if (o_valid && o_ready) begin
                o_valid <= 1'b0;
            end
        end
    end	
endmodule