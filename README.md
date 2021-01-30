# serial_audio_decoder
Serial audio data (I2S or Left justified) decoder.Using valid-ready handshake.

![serial_audio_decoder](https://user-images.githubusercontent.com/14823909/106344647-61f33780-62ee-11eb-9559-37f03dec33aa.png)

|Name|Direction|Description|
|--|--|--|
|reset|input|reset (high active)|
|sclk|input|Serial data (sdin) clock|
|lrclk|input|Left-right clock (0 = left. See also lrclk_polarity)|
|sdin|input|Serial data|
|is_i2s|input|Serial format (0: Left justified / 1: I2S)|
|lrclk_polarity|input|Left-right clock polarity (0: low = left / 1: low = right)|
|is_error|output|error status (0: normal / 1: error)|
|o_valid|output|Output data valid signal (1: valid)|
|o_ready|input|Incoming ready signal (1: ready)|
|o_is_left|output|Channel (0: Right / 1: Left)
|o_data[31:0]|output|Audio data (Left justified) |
