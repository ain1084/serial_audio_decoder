`timescale 1 ns / 1 ns
`default_nettype none

module serial_audio_decoder_tb();

    parameter STEP = 1000000000 / (44100 * 128);

    reg reset;

    reg clk128;
    initial begin
        clk128 = 1'b0;
        forever #(STEP / 2) clk128 = ~clk128;
    end

    reg lrclk = 0;
    reg sclk = 0;
    reg sdin = 0;

    wire o_valid;
    reg o_ready = 1'b1;
    wire o_is_left;
    wire [31:0] o_audio;
    wire is_error;

    serial_audio_decoder serial_audio_decoder_(
        .reset(reset),
        .is_i2s(1'b0),
        .lrclk_polarity(1'b0),
        .lrclk(lrclk),
        .sclk(sclk),
        .sdin(sdin),
        .is_error(is_error),
        .o_valid(o_valid),
        .o_ready(o_ready),
        .o_is_left(o_is_left),
        .o_audio(o_audio)
    );

    integer i;
    integer k;
    task outChannel(
    input reg [31:0] value,
    input reg [5:0] bit_count,
    input reg [7:0] wait_count);
        begin
            for (i = 0; i < bit_count; i++) begin
                sclk = 0;
                sdin = value[bit_count - 1];
                value = value << 1;
                repeat(wait_count) @(posedge clk128);
                sclk = 1;
                repeat(wait_count) @(posedge clk128);
            end
            lrclk = ~lrclk;
        end
    endtask
    

    initial begin

        $dumpfile("serial_audio_decoder_tb.vcd");
        $dumpvars;

        reset = 0;
        lrclk = 0;
        repeat(2) @(posedge clk128) reset = 1;
        reset = 0;
        repeat(2) @(posedge clk128);
        
        outChannel(16'h0000, 16, 2);		// Left
        outChannel(16'h1fed, 16 ,2);		// Right
        outChannel(16'h2eef, 16 ,2);		// Left
        outChannel(16'h3333, 16 ,2);		// Right

        outChannel(16'h0000, 16, 2);		// Left
        outChannel(16'h1fed, 16 ,2);		// Right
        outChannel(16'h2eef, 16 ,2);		// Left
        outChannel(16'h3333, 16 ,2);		// Right

        outChannel(16'h4444, 15 ,2);		// Invalid (unspported bit length)
        outChannel(16'h5500, 16 ,2);		// Ignore
        outChannel(16'h6000, 16 ,2);		// Left
        outChannel(16'h7fff, 16 ,2);		// Right

        outChannel(16'h8888, 15 ,2);		// Invalid (unsupported bit length)
        outChannel(32'h12345678, 32 ,1);	// Ignore
        outChannel(32'hAAAAAAAA, 32 ,1);	// Left
        outChannel(32'h99999999, 32 ,1);	// Right

        outChannel(16'h9876, 16 ,1);	    // Left
        outChannel(16'h1111, 15 ,1);	    // Ignore (unsupported bit length)
        outChannel(16'h2345, 16 ,1);	    // Left


        for (i = 0; i < 64; i++) begin
            sclk = 0;
            repeat(1) @(posedge clk128);
            sclk = 1;
            repeat(1) @(posedge clk128);
        end

        $finish();
    end

    reg is_error_occurred;
    always @(posedge sclk or posedge reset) begin
        if (reset) begin
            is_error_occurred <= 1'b0;
        end else if (o_valid) begin
            $write("out: is_left(%d) audio = %08h\n", o_is_left, o_audio);
        end else if (is_error) begin
            if (!is_error_occurred) begin
                $write("error\n");
                is_error_occurred <= 1'b1;
            end
        end else begin
            is_error_occurred <= 1'b0;
        end
    end

endmodule
