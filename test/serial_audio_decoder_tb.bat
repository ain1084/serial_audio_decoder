@echo off
iverilog ../serial_audio_decoder.v serial_audio_decoder_tb.v
if not errorlevel 1 (
	vvp a.out
	del a.out
)
