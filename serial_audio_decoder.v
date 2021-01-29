`default_nettype none

module serial_audio_decoder(
    input wire sclk,
    input wire reset,
    input wire lrclk,
    input wire sdin,
    input wire is_i2s,
    input wire lrclk_polarity,
    output reg is_error,
    output reg o_valid,
    input wire o_ready,
    output wire o_is_left,
    output reg [31:0] o_audio);

    reg [4:0] channel_bit_count;
    reg [31:0] audio_shift_data;
    reg is_left_channel;
    reg [1:0] channel_history;
    reg [2:0] audio_shift_flag;

    // valid-ready handshake
    always @(posedge sclk or posedge reset) begin
        if (reset)
            o_valid <= 1'b0;
        else if (o_valid && o_ready)
                o_valid <= 1'b0;
        else if (audio_shift_flag == 3'b001)
            o_valid <= 1'b1;
    end

    assign o_is_left = is_left_channel;
    wire is_current_channel_left = lrclk == lrclk_polarity;
    wire is_channel_changing = is_i2s ? (channel_history[0] != channel_history[1]) : (channel_history[0] != is_current_channel_left);

    always @(posedge sclk or posedge reset) begin
        if (reset) begin
            is_left_channel <= lrclk_polarity;
            channel_bit_count <= 0;
            channel_history <= 2'b00;
            audio_shift_flag <= 3'b000;
            audio_shift_data <= 0;
            o_audio <= 0;
            is_error <= 1'b1;
        end else begin
            audio_shift_data <= { audio_shift_data[30:0], sdin };
            channel_history <= { channel_history[0], is_current_channel_left };
            channel_bit_count <= is_channel_changing ? 1'b0 : channel_bit_count + 1'b1;

            if (is_channel_changing && is_left_channel != channel_history[1]) begin
                case (channel_bit_count)
                    5'd31: begin // 32bit
                        audio_shift_flag <= 3'b001;
                        is_error <= 1'b0;
                        is_left_channel <= ~is_left_channel;
                    end
                    5'd23: begin // 24bit
                        audio_shift_flag <= 3'b010;
                        is_error <= 1'b0;
                        is_left_channel <= ~is_left_channel;
                    end
                    5'd15: begin // 16bit
                        audio_shift_flag <= 3'b100;
                        is_error <= 1'b0;
                        is_left_channel <= ~is_left_channel;
                    end
                    default: begin  //error
                        audio_shift_flag <= 3'b000;
                        is_error <= 1'b1;
                        is_left_channel <= 1'b0;
                    end
                endcase
                o_audio <= audio_shift_data;
            end else begin
                if (|audio_shift_flag[2:1]) begin
                    o_audio <= o_audio << 8;
                end
                audio_shift_flag <= audio_shift_flag >> 1;
            end
        end
    end	
endmodule