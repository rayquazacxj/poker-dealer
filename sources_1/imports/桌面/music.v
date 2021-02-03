`define silence   32'd50000000
`define lg   32'd196   // C3
`define la   32'd220   // C3
`define lb   32'd247
`define c   32'd262   // C3
`define d   32'd294
`define e   32'd330
`define f   32'd349
`define g   32'd392   // G3
`define a   32'd440
`define b   32'd494   // B3
`define hc  32'd524   // C4
`define hd  32'd588   // D4
`define he  32'd660   // E4
`define hf  32'd698   // F4
`define hg  32'd784   // G4
`define ha  32'd880   // F4
`define hb  32'd988   // G4

module speaker(
    clk, // clock from crystal
    rst, // active high reset: BTNC
    _nostop,
    _mute, // SW: Mute
    motor_state,
    audio_mclk, // master clock
    audio_lrck, // left-right clock
    audio_sck, // serial clock
    audio_sdin // serial audio data input
);

    // I/O declaration
    input clk;  // clock from the crystal
    input rst;  // active high reset
    input  _nostop,_mute;
    input [1:0] motor_state;
    output audio_mclk; // master clock
    output audio_lrck; // left-right clock
    output audio_sck; // serial clock
    output audio_sdin; // serial audio data input


    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;
    
    wire clkDiv22;
    wire [11:0] ibeatNum; // Beat counter
    wire [31:0] freqL, freqR; // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR; // Processed Frequency, adapted to the clock rate of Basys3

    assign freq_outL = 50000000 / ((_mute||(!_nostop)) ? `silence : freqL); // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_outR = 50000000 / ((_mute||(!_nostop)) ? `silence : freqR);

    clock_divider #(.n(22)) clock_22(
        .clk(clk),
        .clk_div(clkDiv22)
    );

    // Player Control
    player_control #(.LEN(512)) playerCtrl_00 ( 
        .clk(clkDiv22),
        .rst(rst),
        ._nostop(_nostop),
        .motor_state(motor_state),
        .ibeat(ibeatNum)
    );

    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    music_example music_00 (
        .ibeatNum(ibeatNum),
        .en(1'b1),
        .motor_state(motor_state),
        .toneL(freqL),
        .toneR(freqR)
    );

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), // clock from crystal
        .rst(rst), // active high reset
        .note_div_left(freq_outL),
        .note_div_right(freq_outR),
        .audio_left(audio_in_left), // left sound audio
        .audio_right(audio_in_right),
        .volume(3'b000) // 3 bits for 5 levels
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk),  // clock from the crystal
        .rst(rst),  // active high reset
        .audio_in_left(audio_in_left), // left channel audio data input
        .audio_in_right(audio_in_right), // right channel audio data input
        .audio_mclk(audio_mclk), // master clock
        .audio_lrck(audio_lrck), // left-right clock
        .audio_sck(audio_sck), // serial clock
        .audio_sdin(audio_sdin) // serial audio data input
    );

endmodule


module player_control (
	input clk,
	input rst,
    input _nostop,
    input [1:0] motor_state,
	output reg [11:0] ibeat
);
    parameter RESET=2'b00;
    parameter ROTATE=1'b01;
    parameter WAIT=2'b10;
    parameter REMAIN=2'b11;
	parameter LEN = 4095;
    reg [11:0] next_ibeat;
    reg [1:0] change;
    reg tozero;

	always @(posedge clk, posedge rst) begin
		if (rst) begin
			ibeat <= 0;
            change<=motor_state;
        end
		else begin
            ibeat <= next_ibeat;
            change<=motor_state;
		end
	end

    always @(posedge clk, posedge rst) begin
		if (rst) begin
			tozero=0;
        end
		else if((motor_state==ROTATE&&change==RESET)||(motor_state==RESET&&change==WAIT))
            tozero=1;
        else
            tozero=0;
	end

    always @* begin
        if(tozero)
            next_ibeat=0;
        else if(!_nostop)
            next_ibeat=ibeat;
        else
            next_ibeat = (ibeat + 1 < LEN) ? (ibeat + 1) : 12'd0;
    end

endmodule

module note_gen(
    clk, // clock from crystal
    rst, // active high reset
    note_div_left, // div for note generation
    note_div_right,
    audio_left,
    audio_right,
    volume
);

    // I/O declaration
    input clk; // clock from crystal
    input rst; // active low reset
    input [21:0] note_div_left, note_div_right; // div for note generation
    output [15:0] audio_left, audio_right;
    input [2:0] volume;

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
        
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here
    assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : 
                                (b_clk == 1'b0) ? 16'hE000 : 16'h2000;
    assign audio_right = (note_div_right == 22'd1) ? 16'h0000 : 
                                (c_clk == 1'b0) ? 16'hE000 : 16'h2000;
endmodule

module speaker_control(
    clk,  // clock from the crystal
    rst,  // active high reset
    audio_in_left, // left channel audio data input
    audio_in_right, // right channel audio data input
    audio_mclk, // master clock
    audio_lrck, // left-right clock, Word Select clock, or sample rate clock
    audio_sck, // serial clock
    audio_sdin // serial audio data input
);

    // I/O declaration
    input clk;  // clock from the crystal
    input rst;  // active high reset
    input [15:0] audio_in_left; // left channel audio data input
    input [15:0] audio_in_right; // right channel audio data input
    output audio_mclk; // master clock
    output audio_lrck; // left-right clock
    output audio_sck; // serial clock
    output audio_sdin; // serial audio data input
    reg audio_sdin;

    // Declare internal signal nodes 
    wire [8:0] clk_cnt_next;
    reg [8:0] clk_cnt;
    reg [15:0] audio_left, audio_right;

    // Counter for the clock divider
    assign clk_cnt_next = clk_cnt + 1'b1;

    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            clk_cnt <= 9'd0;
        else
            clk_cnt <= clk_cnt_next;

    // Assign divided clock output
    assign audio_mclk = clk_cnt[1];
    assign audio_lrck = clk_cnt[8];
    assign audio_sck = 1'b1; // use internal serial clock mode

    // audio input data buffer
    always @(posedge clk_cnt[8] or posedge rst)
        if (rst == 1'b1)
            begin
                audio_left <= 16'd0;
                audio_right <= 16'd0;
            end
        else
            begin
                audio_left <= audio_in_left;
                audio_right <= audio_in_right;
            end

    always @*
        case (clk_cnt[8:4])
            5'b00000: audio_sdin = audio_right[0];
            5'b00001: audio_sdin = audio_left[15];
            5'b00010: audio_sdin = audio_left[14];
            5'b00011: audio_sdin = audio_left[13];
            5'b00100: audio_sdin = audio_left[12];
            5'b00101: audio_sdin = audio_left[11];
            5'b00110: audio_sdin = audio_left[10];
            5'b00111: audio_sdin = audio_left[9];
            5'b01000: audio_sdin = audio_left[8];
            5'b01001: audio_sdin = audio_left[7];
            5'b01010: audio_sdin = audio_left[6];
            5'b01011: audio_sdin = audio_left[5];
            5'b01100: audio_sdin = audio_left[4];
            5'b01101: audio_sdin = audio_left[3];
            5'b01110: audio_sdin = audio_left[2];
            5'b01111: audio_sdin = audio_left[1];
            5'b10000: audio_sdin = audio_left[0];
            5'b10001: audio_sdin = audio_right[15];
            5'b10010: audio_sdin = audio_right[14];
            5'b10011: audio_sdin = audio_right[13];
            5'b10100: audio_sdin = audio_right[12];
            5'b10101: audio_sdin = audio_right[11];
            5'b10110: audio_sdin = audio_right[10];
            5'b10111: audio_sdin = audio_right[9];
            5'b11000: audio_sdin = audio_right[8];
            5'b11001: audio_sdin = audio_right[7];
            5'b11010: audio_sdin = audio_right[6];
            5'b11011: audio_sdin = audio_right[5];
            5'b11100: audio_sdin = audio_right[4];
            5'b11101: audio_sdin = audio_right[3];
            5'b11110: audio_sdin = audio_right[2];
            5'b11111: audio_sdin = audio_right[1];
            default: audio_sdin = 1'b0;
        endcase

endmodule

`define sil   32'd50000000 // slience
module music_example (
	input [11:0] ibeatNum,
	input en,
    input [1:0] motor_state,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);
    parameter RESET=2'b00;
    parameter ROTATE=1'b01;
    parameter WAIT=2'b10;
    parameter REMAIN=2'b11;

    wire _music;
    assign _music= (motor_state==RESET) ? 1'b0 : 1'b1;

    always @* begin
        if(en == 1) begin
            if(_music==1'b0) begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneR = `hg;      12'd1: toneR = `hg; // HG (half-beat)
                12'd2: toneR = `hg;      12'd3: toneR = `hg;
                12'd4: toneR = `hg;      12'd5: toneR = `hg;
                12'd6: toneR = `hg;      12'd7: toneR = `hg;
                12'd8: toneR = `he;      12'd9: toneR = `he; // HE (half-beat)
                12'd10: toneR = `he;     12'd11: toneR = `he;
                12'd12: toneR = `he;     12'd13: toneR = `he;
                12'd14: toneR = `he;     12'd15: toneR = `sil; // (Short break for repetitive notes: high E)

                12'd16: toneR = `he;     12'd17: toneR = `he; // HE (one-beat)
                12'd18: toneR = `he;     12'd19: toneR = `he;
                12'd20: toneR = `he;     12'd21: toneR = `he;
                12'd22: toneR = `he;     12'd23: toneR = `he;
                12'd24: toneR = `he;     12'd25: toneR = `he;
                12'd26: toneR = `he;     12'd27: toneR = `he;
                12'd28: toneR = `he;     12'd29: toneR = `he;
                12'd30: toneR = `he;     12'd31: toneR = `he;

                12'd32: toneR = `hf;     12'd33: toneR = `hf; // HF (half-beat)
                12'd34: toneR = `hf;     12'd35: toneR = `hf;
                12'd36: toneR = `hf;     12'd37: toneR = `hf;
                12'd38: toneR = `hf;     12'd39: toneR = `hf;
                12'd40: toneR = `hd;     12'd41: toneR = `hd; // HD (half-beat)
                12'd42: toneR = `hd;     12'd43: toneR = `hd;
                12'd44: toneR = `hd;     12'd45: toneR = `hd;
                12'd46: toneR = `hd;     12'd47: toneR = `sil; // (Short break for repetitive notes: high D)

                12'd48: toneR = `hd;     12'd49: toneR = `hd; // HD (one-beat)
                12'd50: toneR = `hd;     12'd51: toneR = `hd;
                12'd52: toneR = `hd;     12'd53: toneR = `hd;
                12'd54: toneR = `hd;     12'd55: toneR = `hd;
                12'd56: toneR = `hd;     12'd57: toneR = `hd;
                12'd58: toneR = `hd;     12'd59: toneR = `hd;
                12'd60: toneR = `hd;     12'd61: toneR = `hd;
                12'd62: toneR = `hd;     12'd63: toneR = `hd;

                // --- Measure 2 ---
                12'd64: toneR = `hc;     12'd65: toneR = `hc; // HC (half-beat)
                12'd66: toneR = `hc;     12'd67: toneR = `hc;
                12'd68: toneR = `hc;     12'd69: toneR = `hc;
                12'd70: toneR = `hc;     12'd71: toneR = `hc;
                12'd72: toneR = `hd;     12'd73: toneR = `hd; // HD (half-beat)
                12'd74: toneR = `hd;     12'd75: toneR = `hd;
                12'd76: toneR = `hd;     12'd77: toneR = `hd;
                12'd78: toneR = `hd;     12'd79: toneR = `hd;

                12'd80: toneR = `he;     12'd81: toneR = `he; // HE (half-beat)
                12'd82: toneR = `he;     12'd83: toneR = `he;
                12'd84: toneR = `he;     12'd85: toneR = `he;
                12'd86: toneR = `he;     12'd87: toneR = `he;
                12'd88: toneR = `hf;     12'd89: toneR = `hf; // HF (half-beat)
                12'd90: toneR = `hf;     12'd91: toneR = `hf;
                12'd92: toneR = `hf;     12'd93: toneR = `hf;
                12'd94: toneR = `hf;     12'd95: toneR = `hf;

                12'd96: toneR = `hg;     12'd97: toneR = `hg; // HG (half-beat)
                12'd98: toneR = `hg;     12'd99: toneR = `hg;
                12'd100: toneR = `hg;    12'd101: toneR = `hg;
                12'd102: toneR = `hg;    12'd103: toneR = `sil; // (Short break for repetitive notes: high D)
                12'd104: toneR = `hg;    12'd105: toneR = `hg; // HG (half-beat)
                12'd106: toneR = `hg;    12'd107: toneR = `hg;
                12'd108: toneR = `hg;    12'd109: toneR = `hg;
                12'd110: toneR = `hg;    12'd111: toneR = `sil; // (Short break for repetitive notes: high D)

                12'd112: toneR = `hg;    12'd113: toneR = `hg; // HG (one-beat)
                12'd114: toneR = `hg;    12'd115: toneR = `hg;
                12'd116: toneR = `hg;    12'd117: toneR = `hg;
                12'd118: toneR = `hg;    12'd119: toneR = `hg;
                12'd120: toneR = `hg;    12'd121: toneR = `hg;
                12'd122: toneR = `hg;    12'd123: toneR = `hg;
                12'd124: toneR = `hg;    12'd125: toneR = `hg;
                12'd126: toneR = `hg;    12'd127: toneR = `hg;

                 // --- Measure 3 ---
                12'd128: toneR = `hg;    12'd129: toneR = `hg;
                12'd130: toneR = `hg;    12'd131: toneR = `hg;
                12'd132: toneR = `hg;    12'd133: toneR = `hg;
                12'd134: toneR = `hg;    12'd135: toneR = `hg;
                12'd136: toneR = `he;    12'd137: toneR = `he;
                12'd138: toneR = `he;    12'd139: toneR = `he;
                12'd140: toneR = `he;    12'd141: toneR = `he;
                12'd142: toneR = `he;    12'd143: toneR = `sil;

                12'd144: toneR = `he;    12'd145: toneR = `he;
                12'd146: toneR = `he;    12'd147: toneR = `he;
                12'd148: toneR = `he;    12'd149: toneR = `he;
                12'd150: toneR = `he;    12'd151: toneR = `he;
                12'd152: toneR = `he;    12'd153: toneR = `he;
                12'd154: toneR = `he;    12'd155: toneR = `he;
                12'd156: toneR = `he;    12'd157: toneR = `he;
                12'd158: toneR = `he;    12'd159: toneR = `he;

                12'd160: toneR = `hf;    12'd161: toneR = `hf;
                12'd162: toneR = `hf;    12'd163: toneR = `hf;
                12'd164: toneR = `hf;    12'd165: toneR = `hf;
                12'd166: toneR = `hf;    12'd167: toneR = `hf;
                12'd168: toneR = `hd;    12'd169: toneR = `hd;
                12'd170: toneR = `hd;    12'd171: toneR = `hd;
                12'd172: toneR = `hd;    12'd173: toneR = `hd;
                12'd174: toneR = `hd;    12'd175: toneR = `sil;

                12'd176: toneR = `hd;    12'd177: toneR = `hd;
                12'd178: toneR = `hd;    12'd179: toneR = `hd;
                12'd180: toneR = `hd;    12'd181: toneR = `hd;
                12'd182: toneR = `hd;    12'd183: toneR = `hd;
                12'd184: toneR = `hd;    12'd185: toneR = `hd;
                12'd186: toneR = `hd;    12'd187: toneR = `hd;
                12'd188: toneR = `hd;    12'd189: toneR = `hd;
                12'd190: toneR = `hd;    12'd191: toneR = `hd;

                // --- Measure 4 ---
                12'd192: toneR = `hc;    12'd193: toneR = `hc;
                12'd194: toneR = `hc;    12'd195: toneR = `hc;
                12'd196: toneR = `hc;    12'd197: toneR = `hc;
                12'd198: toneR = `hc;    12'd199: toneR = `hc;
                12'd200: toneR = `he;    12'd201: toneR = `he;
                12'd202: toneR = `he;    12'd203: toneR = `he;
                12'd204: toneR = `he;    12'd205: toneR = `he;
                12'd206: toneR = `he;    12'd207: toneR = `he;

                12'd208: toneR = `hg;    12'd209: toneR = `hg;
                12'd210: toneR = `hg;    12'd211: toneR = `hg;
                12'd212: toneR = `hg;    12'd213: toneR = `hg;
                12'd214: toneR = `hg;    12'd215: toneR = `sil;
                12'd216: toneR = `hg;    12'd217: toneR = `hg;
                12'd218: toneR = `hg;    12'd219: toneR = `hg;
                12'd220: toneR = `hg;    12'd221: toneR = `hg;
                12'd222: toneR = `hg;    12'd223: toneR = `hg;

                12'd224: toneR = `he;    12'd225: toneR = `he;
                12'd226: toneR = `he;    12'd227: toneR = `he;
                12'd228: toneR = `he;    12'd229: toneR = `he;
                12'd230: toneR = `he;    12'd231: toneR = `he;
                12'd232: toneR = `he;    12'd233: toneR = `he;
                12'd234: toneR = `he;    12'd235: toneR = `he;
                12'd236: toneR = `he;    12'd237: toneR = `he;
                12'd238: toneR = `he;    12'd239: toneR = `he;

                12'd240: toneR = `he;    12'd241: toneR = `he;
                12'd242: toneR = `he;    12'd243: toneR = `he;
                12'd244: toneR = `he;    12'd245: toneR = `he;
                12'd246: toneR = `he;    12'd247: toneR = `he;
                12'd248: toneR = `he;    12'd249: toneR = `he;
                12'd250: toneR = `he;    12'd251: toneR = `he;
                12'd252: toneR = `he;    12'd253: toneR = `he;
                12'd254: toneR = `he;    12'd255: toneR = `he;

                 // --- Measure 5 ---
                12'd256: toneR = `hd;    12'd257: toneR = `hd;
                12'd258: toneR = `hd;    12'd259: toneR = `hd;
                12'd260: toneR = `hd;    12'd261: toneR = `hd;
                12'd262: toneR = `hd;    12'd263: toneR = `sil;
                12'd264: toneR = `hd;    12'd265: toneR = `hd;
                12'd266: toneR = `hd;    12'd267: toneR = `hd;
                12'd268: toneR = `hd;    12'd269: toneR = `hd;
                12'd270: toneR = `hd;    12'd271: toneR = `sil;


                12'd272: toneR = `hd;    12'd273: toneR = `hd;
                12'd274: toneR = `hd;    12'd275: toneR = `hd;
                12'd276: toneR = `hd;    12'd277: toneR = `hd;
                12'd278: toneR = `hd;    12'd279: toneR = `sil;
                12'd280: toneR = `hd;    12'd281: toneR = `hd;
                12'd282: toneR = `hd;    12'd283: toneR = `hd;
                12'd284: toneR = `hd;    12'd285: toneR = `hd;
                12'd286: toneR = `hd;    12'd287: toneR = `sil;


                12'd288: toneR = `hd;    12'd289: toneR = `hd;
                12'd290: toneR = `hd;    12'd291: toneR = `hd;
                12'd292: toneR = `hd;    12'd293: toneR = `hd;
                12'd294: toneR = `hd;    12'd295: toneR = `hd;
                12'd296: toneR = `he;    12'd297: toneR = `he;
                12'd298: toneR = `he;    12'd299: toneR = `he;
                12'd300: toneR = `he;    12'd301: toneR = `he;
                12'd302: toneR = `he;    12'd303: toneR = `he;


                12'd304: toneR = `hf;    12'd305: toneR = `hf;
                12'd306: toneR = `hf;    12'd307: toneR = `hf;
                12'd308: toneR = `hf;    12'd309: toneR = `hf;
                12'd310: toneR = `hf;    12'd311: toneR = `hf;
                12'd312: toneR = `hf;    12'd313: toneR = `hf;
                12'd314: toneR = `hf;    12'd315: toneR = `hf;
                12'd316: toneR = `hf;    12'd317: toneR = `hf;
                12'd318: toneR = `hf;    12'd319: toneR = `hf;

                // --- Measure 6 ---
                12'd320: toneR = `he;    12'd321: toneR = `he;
                12'd322: toneR = `he;    12'd323: toneR = `he;
                12'd324: toneR = `he;    12'd325: toneR = `he;
                12'd326: toneR = `he;    12'd327: toneR = `sil;
                12'd328: toneR = `he;    12'd329: toneR = `he;
                12'd330: toneR = `he;    12'd331: toneR = `he;
                12'd332: toneR = `he;    12'd333: toneR = `he;
                12'd334: toneR = `he;    12'd335: toneR = `sil;


                12'd336: toneR = `he;    12'd337: toneR = `he;
                12'd338: toneR = `he;    12'd339: toneR = `he;
                12'd340: toneR = `he;    12'd341: toneR = `he;
                12'd342: toneR = `he;    12'd343: toneR = `sil;
                12'd344: toneR = `he;    12'd345: toneR = `he;
                12'd346: toneR = `he;    12'd347: toneR = `he;
                12'd348: toneR = `he;    12'd349: toneR = `he;
                12'd350: toneR = `he;    12'd351: toneR = `sil;


                12'd352: toneR = `he;    12'd353: toneR = `he;
                12'd354: toneR = `he;    12'd355: toneR = `he;
                12'd356: toneR = `he;    12'd357: toneR = `he;
                12'd358: toneR = `he;    12'd359: toneR = `he;
                12'd360: toneR = `hf;    12'd361: toneR = `hf;
                12'd362: toneR = `hf;    12'd363: toneR = `hf;
                12'd364: toneR = `hf;    12'd365: toneR = `hf;
                12'd366: toneR = `hf;    12'd367: toneR = `hf;


                12'd368: toneR = `hg;    12'd369: toneR = `hg;
                12'd370: toneR = `hg;    12'd371: toneR = `hg;
                12'd372: toneR = `hg;    12'd373: toneR = `hg;
                12'd374: toneR = `hg;    12'd375: toneR = `hg;
                12'd376: toneR = `hg;    12'd377: toneR = `hg;
                12'd378: toneR = `hg;    12'd379: toneR = `hg;
                12'd380: toneR = `hg;    12'd381: toneR = `hg;
                12'd382: toneR = `hg;    12'd383: toneR = `hg;


                 // --- Measure 7 ---
                12'd384: toneR = `hg;    12'd385: toneR = `hg;
                12'd386: toneR = `hg;    12'd387: toneR = `hg;
                12'd388: toneR = `hg;    12'd389: toneR = `hg;
                12'd390: toneR = `hg;    12'd391: toneR = `hg;
                12'd392: toneR = `he;    12'd393: toneR = `he;
                12'd394: toneR = `he;    12'd395: toneR = `he;
                12'd396: toneR = `he;    12'd397: toneR = `he;
                12'd398: toneR = `he;    12'd399: toneR = `sil;


                12'd400: toneR = `he;    12'd401: toneR = `he;
                12'd402: toneR = `he;    12'd403: toneR = `he;
                12'd404: toneR = `he;    12'd405: toneR = `he;
                12'd406: toneR = `he;    12'd407: toneR = `he;
                12'd408: toneR = `he;    12'd409: toneR = `he;
                12'd410: toneR = `he;    12'd411: toneR = `he;
                12'd412: toneR = `he;    12'd413: toneR = `he;
                12'd414: toneR = `he;    12'd415: toneR = `he;


                12'd416: toneR = `hf;    12'd417: toneR = `hf;
                12'd418: toneR = `hf;    12'd419: toneR = `hf;
                12'd420: toneR = `hf;    12'd421: toneR = `hf;
                12'd422: toneR = `hf;    12'd423: toneR = `hf;
                12'd424: toneR = `hd;    12'd425: toneR = `hd;
                12'd426: toneR = `hd;    12'd427: toneR = `hd;
                12'd428: toneR = `hd;    12'd429: toneR = `hd;
                12'd430: toneR = `hd;    12'd431: toneR = `sil;


                12'd432: toneR = `hd;    12'd433: toneR = `hd;
                12'd434: toneR = `hd;    12'd435: toneR = `hd;
                12'd436: toneR = `hd;    12'd437: toneR = `hd;
                12'd438: toneR = `hd;    12'd439: toneR = `hd;
                12'd440: toneR = `hd;    12'd441: toneR = `hd;
                12'd442: toneR = `hd;    12'd443: toneR = `hd;
                12'd444: toneR = `hd;    12'd445: toneR = `hd;
                12'd446: toneR = `hd;    12'd447: toneR = `hd;


                // --- Measure 8  ---
                12'd448: toneR = `hc;    12'd449: toneR = `hc;
                12'd450: toneR = `hc;    12'd451: toneR = `hc;
                12'd452: toneR = `hc;    12'd453: toneR = `hc;
                12'd454: toneR = `hc;    12'd455: toneR = `hc;
                12'd456: toneR = `he;    12'd457: toneR = `he;
                12'd458: toneR = `he;    12'd459: toneR = `he;
                12'd460: toneR = `he;    12'd461: toneR = `he;
                12'd462: toneR = `he;    12'd463: toneR = `he;


                12'd464: toneR = `hg;    12'd465: toneR = `hg;
                12'd466: toneR = `hg;    12'd467: toneR = `hg;
                12'd468: toneR = `hg;    12'd469: toneR = `hg;
                12'd470: toneR = `hg;    12'd471: toneR = `sil;
                12'd472: toneR = `hg;    12'd473: toneR = `hg;
                12'd474: toneR = `hg;    12'd475: toneR = `hg;
                12'd476: toneR = `hg;    12'd477: toneR = `hg;
                12'd478: toneR = `hg;    12'd479: toneR = `hg;


                12'd480: toneR = `he;    12'd481: toneR = `he;
                12'd482: toneR = `he;    12'd483: toneR = `he;
                12'd484: toneR = `he;    12'd485: toneR = `he;
                12'd486: toneR = `he;    12'd487: toneR = `he;
                12'd488: toneR = `he;    12'd489: toneR = `he;
                12'd490: toneR = `he;    12'd491: toneR = `he;
                12'd492: toneR = `he;    12'd493: toneR = `he;
                12'd494: toneR = `he;    12'd495: toneR = `he;


                12'd496: toneR = `he;    12'd497: toneR = `he;
                12'd498: toneR = `he;    12'd499: toneR = `he;
                12'd500: toneR = `he;    12'd501: toneR = `he;
                12'd502: toneR = `he;    12'd503: toneR = `he;
                12'd504: toneR = `he;    12'd505: toneR = `he;
                12'd506: toneR = `he;    12'd507: toneR = `he;
                12'd508: toneR = `he;    12'd509: toneR = `he;
                12'd510: toneR = `he;    12'd511: toneR = `he;

                default: toneR = `sil;
            endcase
            end
            else begin
                case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneR = `hd;	    12'd1: toneR = `hd;
                12'd2: toneR = `hd;	    12'd3: toneR = `hd;
                12'd4: toneR = `hd;	    12'd5: toneR = `hd;
                12'd6: toneR = `hd;	    12'd7: toneR = `hd;
                12'd8: toneR = `he;	    12'd9: toneR = `he;
                12'd10: toneR = `he;	12'd11: toneR = `he;
                12'd12: toneR = `he;	12'd13: toneR = `he;
                12'd14: toneR = `he;	12'd15: toneR = `sil;

                12'd16: toneR = `he;	12'd17: toneR = `he;
                12'd18: toneR = `he;	12'd19: toneR = `he;
                12'd20: toneR = `he;	12'd21: toneR = `he;
                12'd22: toneR = `he;	12'd23: toneR = `he;
                12'd24: toneR = `he;	12'd25: toneR = `he;
                12'd26: toneR = `he;	12'd27: toneR = `he;
                12'd28: toneR = `he;	12'd29: toneR = `he;
                12'd30: toneR = `he;	12'd31: toneR = `he;

                12'd32: toneR = `hd;	12'd33: toneR = `hd;
                12'd34: toneR = `hd;	12'd35: toneR = `hd;
                12'd36: toneR = `hd;	12'd37: toneR = `hd;
                12'd38: toneR = `hd;	12'd39: toneR = `hd;
                12'd40: toneR = `he;	12'd41: toneR = `he;
                12'd42: toneR = `he;	12'd43: toneR = `he;
                12'd44: toneR = `he;	12'd45: toneR = `he;
                12'd46: toneR = `he;	12'd47: toneR = `sil;

                12'd48: toneR = `he;	12'd49: toneR = `he;
                12'd50: toneR = `he;	12'd51: toneR = `he;
                12'd52: toneR = `he;	12'd53: toneR = `he;
                12'd54: toneR = `he;	12'd55: toneR = `he;
                12'd56: toneR = `he;	12'd57: toneR = `he;
                12'd58: toneR = `he;	12'd59: toneR = `he;
                12'd60: toneR = `he;	12'd61: toneR = `he;
                12'd62: toneR = `he;	12'd63: toneR = `he;

                12'd64: toneR = `hd;	12'd65: toneR = `hd;
                12'd66: toneR = `hd;	12'd67: toneR = `hd;
                12'd68: toneR = `hd;	12'd69: toneR = `hd;
                12'd70: toneR = `hd;	12'd71: toneR = `hd;
                12'd72: toneR = `hg;	12'd73: toneR = `hg;
                12'd74: toneR = `hg;	12'd75: toneR = `hg;
                12'd76: toneR = `hg;	12'd77: toneR = `hg;
                12'd78: toneR = `hg;	12'd79: toneR = `sil;

                12'd80: toneR = `hg;	12'd81: toneR = `hg;
                12'd82: toneR = `hg;	12'd83: toneR = `hg;
                12'd84: toneR = `hg;	12'd85: toneR = `hg;
                12'd86: toneR = `hg;	12'd87: toneR = `hg;
                12'd88: toneR = `hg;	12'd89: toneR = `hg;
                12'd90: toneR = `hg;	12'd91: toneR = `hg;
                12'd92: toneR = `hg;	12'd93: toneR = `hg;
                12'd94: toneR = `hg;	12'd95: toneR = `hg;

                12'd96: toneR = `g;	    12'd97: toneR = `g;
                12'd98: toneR = `g;	    12'd99: toneR = `g;
                12'd100: toneR = `g;	12'd101: toneR = `g;
                12'd102: toneR = `g;	12'd103: toneR = `g;
                12'd104: toneR = `hg;	12'd105: toneR = `hg;
                12'd106: toneR = `hg;	12'd107: toneR = `hg;
                12'd108: toneR = `hg;	12'd109: toneR = `hg;
                12'd110: toneR = `hg;	12'd111: toneR = `sil;

                12'd112: toneR = `hg;	12'd113: toneR = `hg;
                12'd114: toneR = `hg;	12'd115: toneR = `hg;
                12'd116: toneR = `hg;	12'd117: toneR = `hg;
                12'd118: toneR = `hg;	12'd119: toneR = `hg;
                12'd120: toneR = `b;	12'd121: toneR = `b;
                12'd122: toneR = `b;	12'd123: toneR = `b;
                12'd124: toneR = `b;	12'd125: toneR = `b;
                12'd126: toneR = `b;	12'd127: toneR = `sil;

                12'd128: toneR = `b;	12'd129: toneR = `b;
                12'd130: toneR = `b;	12'd131: toneR = `b;
                12'd132: toneR = `b;	12'd133: toneR = `b;
                12'd134: toneR = `b;	12'd135: toneR = `b;
                12'd136: toneR = `hc;	12'd137: toneR = `hc;
                12'd138: toneR = `hc;	12'd139: toneR = `hc;
                12'd140: toneR = `hc;	12'd141: toneR = `hc;
                12'd142: toneR = `hc;	12'd143: toneR = `sil;

                12'd144: toneR = `hc;	12'd145: toneR = `hc;
                12'd146: toneR = `hc;	12'd147: toneR = `hc;
                12'd148: toneR = `hc;	12'd149: toneR = `hc;
                12'd150: toneR = `hc;	12'd151: toneR = `hc;
                12'd152: toneR = `hc;	12'd153: toneR = `hc;
                12'd154: toneR = `hc;	12'd155: toneR = `hc;
                12'd156: toneR = `hc;	12'd157: toneR = `hc;
                12'd158: toneR = `hc;	12'd159: toneR = `hc;

                12'd160: toneR = `b;	12'd161: toneR = `b;
                12'd162: toneR = `b;	12'd163: toneR = `b;
                12'd164: toneR = `b;	12'd165: toneR = `b;
                12'd166: toneR = `b;	12'd167: toneR = `b;
                12'd168: toneR = `hc;	12'd169: toneR = `hc;
                12'd170: toneR = `hc;	12'd171: toneR = `hc;
                12'd172: toneR = `hc;	12'd173: toneR = `hc;
                12'd174: toneR = `hc;	12'd175: toneR = `sil;

                12'd176: toneR = `hc;	12'd177: toneR = `hc;
                12'd178: toneR = `hc;	12'd179: toneR = `hc;
                12'd180: toneR = `hc;	12'd181: toneR = `hc;
                12'd182: toneR = `hc;	12'd183: toneR = `hc;
                12'd184: toneR = `hc;	12'd185: toneR = `hc;
                12'd186: toneR = `hc;	12'd187: toneR = `hc;
                12'd188: toneR = `hc;	12'd189: toneR = `hc;
                12'd190: toneR = `hc;	12'd191: toneR = `hc;

                12'd192: toneR = `b;	12'd193: toneR = `b;
                12'd194: toneR = `b;	12'd195: toneR = `b;
                12'd196: toneR = `b;	12'd197: toneR = `b;
                12'd198: toneR = `b;	12'd199: toneR = `b;
                12'd200: toneR = `hb;   12'd201: toneR = `hb;
                12'd202: toneR = `hb;   12'd203: toneR = `hb;
                12'd204: toneR = `hb;   12'd205: toneR = `hb;
                12'd206: toneR = `hb;   12'd207: toneR = `hb;

                12'd208: toneR = `ha;	12'd209: toneR = `ha;
                12'd210: toneR = `ha;	12'd211: toneR = `ha;
                12'd212: toneR = `ha;	12'd213: toneR = `ha;
                12'd214: toneR = `ha;	12'd215: toneR = `ha;
                12'd216: toneR = `hg;	12'd217: toneR = `hg;
                12'd218: toneR = `hg;	12'd219: toneR = `hg;
                12'd220: toneR = `hg;	12'd221: toneR = `hg;
                12'd222: toneR = `hg;	12'd223: toneR = `hg;

                12'd224: toneR = `sil;	12'd225: toneR = `sil;
                12'd226: toneR = `sil;	12'd227: toneR = `sil;
                12'd228: toneR = `sil;	12'd229: toneR = `sil;
                12'd230: toneR = `sil;	12'd231: toneR = `sil;
                12'd232: toneR = `he;	12'd233: toneR = `he;
                12'd234: toneR = `he;	12'd235: toneR = `he;
                12'd236: toneR = `he;	12'd237: toneR = `he;
                12'd238: toneR = `he;	12'd239: toneR = `he;

                12'd240: toneR = `hf;	12'd241: toneR = `hf;
                12'd242: toneR = `hf;	12'd243: toneR = `hf;
                12'd244: toneR = `hf;	12'd245: toneR = `hf;
                12'd246: toneR = `hf;	12'd247: toneR = `hf;
                12'd248: toneR = `hg;	12'd249: toneR = `hg;
                12'd250: toneR = `hg;	12'd251: toneR = `hg;
                12'd252: toneR = `hg;	12'd253: toneR = `hg;
                12'd254: toneR = `hg;	12'd255: toneR = `hg;

                12'd256: toneR = `ha;	12'd257: toneR = `ha;
                12'd258: toneR = `ha;	12'd259: toneR = `ha;
                12'd260: toneR = `ha;	12'd261: toneR = `ha;
                12'd262: toneR = `ha;	12'd263: toneR = `ha;
                12'd264: toneR = `ha;	12'd265: toneR = `ha;
                12'd266: toneR = `ha;	12'd267: toneR = `ha;
                12'd268: toneR = `ha;	12'd269: toneR = `ha;
                12'd270: toneR = `ha;	12'd271: toneR = `ha;

                12'd272: toneR = `ha;	12'd273: toneR = `ha;
                12'd274: toneR = `ha;	12'd275: toneR = `ha;
                12'd276: toneR = `ha;	12'd277: toneR = `ha;
                12'd278: toneR = `ha;	12'd279: toneR = `ha;
                12'd280: toneR = `ha;	12'd281: toneR = `ha;
                12'd282: toneR = `ha;	12'd283: toneR = `ha;
                12'd284: toneR = `ha;	12'd285: toneR = `ha;
                12'd286: toneR = `ha;	12'd287: toneR = `ha;

                12'd288: toneR = `hc;	12'd289: toneR = `hc;
                12'd290: toneR = `hc;	12'd291: toneR = `hc;
                12'd292: toneR = `hc;	12'd293: toneR = `hc;
                12'd294: toneR = `hc;	12'd295: toneR = `hc;
                12'd296: toneR = `hd;	12'd297: toneR = `hd;
                12'd298: toneR = `hd;	12'd299: toneR = `hd;
                12'd300: toneR = `hd;	12'd301: toneR = `hd;
                12'd302: toneR = `hd;	12'd303: toneR = `hd;

                12'd304: toneR = `he;	12'd305: toneR = `he;
                12'd306: toneR = `he;	12'd307: toneR = `he;
                12'd308: toneR = `he;	12'd309: toneR = `he;
                12'd310: toneR = `he;	12'd311: toneR = `he;
                12'd312: toneR = `hg;	12'd313: toneR = `hg;
                12'd314: toneR = `hg;	12'd315: toneR = `hg;
                12'd316: toneR = `hg;	12'd317: toneR = `hg;
                12'd318: toneR = `hg;	12'd319: toneR = `hg;

                12'd320: toneR = `hg;	12'd321: toneR = `hg;
                12'd322: toneR = `hg;	12'd323: toneR = `hg;
                12'd324: toneR = `hg;	12'd325: toneR = `hg;
                12'd326: toneR = `hg;	12'd327: toneR = `hg;
                12'd328: toneR = `hg;	12'd329: toneR = `hg;
                12'd330: toneR = `hg;	12'd331: toneR = `hg;
                12'd332: toneR = `hg;	12'd333: toneR = `hg;
                12'd334: toneR = `hg;	12'd335: toneR = `hg;

                12'd336: toneR = `hg;	12'd337: toneR = `hg;
                12'd338: toneR = `hg;	12'd339: toneR = `hg;
                12'd340: toneR = `hg;	12'd341: toneR = `hg;
                12'd342: toneR = `hg;	12'd343: toneR = `hg;
                12'd344: toneR = `hg;	12'd345: toneR = `hg;
                12'd346: toneR = `hg;	12'd347: toneR = `hg;
                12'd348: toneR = `hg;	12'd349: toneR = `hg;
                12'd350: toneR = `hg;	12'd351: toneR = `hg;

                12'd352: toneR = `hc;	12'd353: toneR = `hc;
                12'd354: toneR = `hc;	12'd355: toneR = `hc;
                12'd356: toneR = `hc;	12'd357: toneR = `hc;
                12'd358: toneR = `hc;	12'd359: toneR = `hc;
                12'd360: toneR = `hd;	12'd361: toneR = `hd;
                12'd362: toneR = `hd;	12'd363: toneR = `hd;
                12'd364: toneR = `hd;	12'd365: toneR = `hd;
                12'd366: toneR = `hd;	12'd367: toneR = `hd;

                12'd368: toneR = `he;	12'd369: toneR = `he;
                12'd370: toneR = `he;	12'd371: toneR = `he;
                12'd372: toneR = `he;	12'd373: toneR = `he;
                12'd374: toneR = `he;	12'd375: toneR = `sil;
                12'd376: toneR = `he;	12'd377: toneR = `he;
                12'd378: toneR = `he;	12'd379: toneR = `he;
                12'd380: toneR = `he;	12'd381: toneR = `he;
                12'd382: toneR = `he;	12'd383: toneR = `he;

                12'd384: toneR = `sil;	12'd385: toneR = `sil;
                12'd386: toneR = `sil;	12'd387: toneR = `sil;
                12'd388: toneR = `sil;	12'd389: toneR = `sil;
                12'd390: toneR = `sil;	12'd391: toneR = `sil;
                12'd392: toneR = `hc;	12'd393: toneR = `hc;
                12'd394: toneR = `hc;	12'd395: toneR = `hc;
                12'd396: toneR = `hc;	12'd397: toneR = `hc;
                12'd398: toneR = `hc;	12'd399: toneR = `hc;

                12'd400: toneR = `sil;	12'd401: toneR = `sil;
                12'd402: toneR = `sil;	12'd403: toneR = `sil;
                12'd404: toneR = `sil;	12'd405: toneR = `sil;
                12'd406: toneR = `sil;	12'd407: toneR = `sil;
                12'd408: toneR = `hc;	12'd409: toneR = `hc;
                12'd410: toneR = `hc;	12'd411: toneR = `hc;
                12'd412: toneR = `hc;	12'd413: toneR = `hc;
                12'd414: toneR = `hc;	12'd415: toneR = `hc;

                12'd416: toneR = `sil;	12'd417: toneR = `sil;
                12'd418: toneR = `sil;	12'd419: toneR = `sil;
                12'd420: toneR = `sil;	12'd421: toneR = `sil;
                12'd422: toneR = `sil;	12'd423: toneR = `sil;
                12'd424: toneR = `a;	12'd425: toneR = `a;
                12'd426: toneR = `a;	12'd427: toneR = `a;
                12'd428: toneR = `a;	12'd429: toneR = `a;
                12'd430: toneR = `a;	12'd431: toneR = `a;

                12'd432: toneR = `he;	12'd433: toneR = `he;
                12'd434: toneR = `he;	12'd435: toneR = `he;
                12'd436: toneR = `he;	12'd437: toneR = `he;
                12'd438: toneR = `he;	12'd439: toneR = `he;
                12'd440: toneR = `hd;	12'd441: toneR = `hd;
                12'd442: toneR = `hd;	12'd443: toneR = `hd;
                12'd444: toneR = `hd;	12'd445: toneR = `hd;
                12'd446: toneR = `hd;	12'd447: toneR = `hd;

                12'd448: toneR = `sil;	12'd449: toneR = `sil;
                12'd450: toneR = `sil;	12'd451: toneR = `sil;
                12'd452: toneR = `sil;	12'd453: toneR = `sil;
                12'd454: toneR = `sil;	12'd455: toneR = `sil;
                12'd456: toneR = `sil;	12'd457: toneR = `sil;
                12'd458: toneR = `sil;	12'd459: toneR = `sil;
                12'd460: toneR = `sil;	12'd461: toneR = `sil;
                12'd462: toneR = `sil;	12'd463: toneR = `sil;

                12'd464: toneR = `sil;	12'd465: toneR = `sil;
                12'd466: toneR = `sil;	12'd467: toneR = `sil;
                12'd468: toneR = `sil;	12'd469: toneR = `sil;
                12'd470: toneR = `sil;	12'd471: toneR = `sil;
                12'd472: toneR = `g;	12'd473: toneR = `g;
                12'd474: toneR = `g;	12'd475: toneR = `g;
                12'd476: toneR = `g;	12'd477: toneR = `g;
                12'd478: toneR = `g;	12'd479: toneR = `sil;

                12'd480: toneR = `g;	12'd481: toneR = `g;
                12'd482: toneR = `g;	12'd483: toneR = `g;
                12'd484: toneR = `g;	12'd485: toneR = `g;
                12'd486: toneR = `g;	12'd487: toneR = `g;
                12'd488: toneR = `hg;	12'd489: toneR = `hg;
                12'd490: toneR = `hg;	12'd491: toneR = `hg;
                12'd492: toneR = `hg;	12'd493: toneR = `hg;
                12'd494: toneR = `hg;	12'd495: toneR = `sil;

                12'd496: toneR = `hg;	12'd497: toneR = `hg;
                12'd498: toneR = `hg;	12'd499: toneR = `hg;
                12'd500: toneR = `hg;	12'd501: toneR = `hg;
                12'd502: toneR = `hg;	12'd503: toneR = `hg;
                12'd504: toneR = `hd;	12'd505: toneR = `hd;
                12'd506: toneR = `hd;	12'd507: toneR = `hd;
                12'd508: toneR = `hd;	12'd509: toneR = `hd;
                12'd510: toneR = `hd;	12'd511: toneR = `hd;

                default: toneR = `sil;
            endcase
            end
        end else begin
            toneR = `sil;
        end
    end

    always @(*) begin
        if(en == 1)begin
            if(_music==1'b0) begin
            case(ibeatNum)
                12'd0: toneL = `hc;  	12'd1: toneL = `hc; // HC (two-beat)
                12'd2: toneL = `hc;  	12'd3: toneL = `hc;
                12'd4: toneL = `hc;	    12'd5: toneL = `hc;
                12'd6: toneL = `hc;  	12'd7: toneL = `hc;
                12'd8: toneL = `hc;	    12'd9: toneL = `hc;
                12'd10: toneL = `hc;	12'd11: toneL = `hc;
                12'd12: toneL = `hc;	12'd13: toneL = `hc;
                12'd14: toneL = `hc;	12'd15: toneL = `hc;

                12'd16: toneL = `hc;	12'd17: toneL = `hc;
                12'd18: toneL = `hc;	12'd19: toneL = `hc;
                12'd20: toneL = `hc;	12'd21: toneL = `hc;
                12'd22: toneL = `hc;	12'd23: toneL = `hc;
                12'd24: toneL = `hc;	12'd25: toneL = `hc;
                12'd26: toneL = `hc;	12'd27: toneL = `hc;
                12'd28: toneL = `hc;	12'd29: toneL = `hc;
                12'd30: toneL = `hc;	12'd31: toneL = `hc;

                12'd32: toneL = `g;	    12'd33: toneL = `g; // G (one-beat)
                12'd34: toneL = `g;	    12'd35: toneL = `g;
                12'd36: toneL = `g;	    12'd37: toneL = `g;
                12'd38: toneL = `g;	    12'd39: toneL = `g;
                12'd40: toneL = `g;	    12'd41: toneL = `g;
                12'd42: toneL = `g;	    12'd43: toneL = `g;
                12'd44: toneL = `g;	    12'd45: toneL = `g;
                12'd46: toneL = `g;	    12'd47: toneL = `g;

                12'd48: toneL = `b;	    12'd49: toneL = `b; // B (one-beat)
                12'd50: toneL = `b;	    12'd51: toneL = `b;
                12'd52: toneL = `b;	    12'd53: toneL = `b;
                12'd54: toneL = `b;	    12'd55: toneL = `b;
                12'd56: toneL = `b;	    12'd57: toneL = `b;
                12'd58: toneL = `b;	    12'd59: toneL = `b;
                12'd60: toneL = `b;	    12'd61: toneL = `b;
                12'd62: toneL = `b;	    12'd63: toneL = `b;

                12'd64: toneL = `hc;	12'd65: toneL = `hc; // HC (two-beat)
                12'd66: toneL = `hc;    12'd67: toneL = `hc;
                12'd68: toneL = `hc;	12'd69: toneL = `hc;
                12'd70: toneL = `hc;	12'd71: toneL = `hc;
                12'd72: toneL = `hc;	12'd73: toneL = `hc;
                12'd74: toneL = `hc;	12'd75: toneL = `hc;
                12'd76: toneL = `hc;	12'd77: toneL = `hc;
                12'd78: toneL = `hc;	12'd79: toneL = `hc;

                12'd80: toneL = `hc;	12'd81: toneL = `hc;
                12'd82: toneL = `hc;    12'd83: toneL = `hc;
                12'd84: toneL = `hc;    12'd85: toneL = `hc;
                12'd86: toneL = `hc;    12'd87: toneL = `hc;
                12'd88: toneL = `hc;    12'd89: toneL = `hc;
                12'd90: toneL = `hc;    12'd91: toneL = `hc;
                12'd92: toneL = `hc;    12'd93: toneL = `hc;
                12'd94: toneL = `hc;    12'd95: toneL = `hc;

                12'd96: toneL = `g;	    12'd97: toneL = `g; // G (one-beat)
                12'd98: toneL = `g; 	12'd99: toneL = `g;
                12'd100: toneL = `g;	12'd101: toneL = `g;
                12'd102: toneL = `g;	12'd103: toneL = `g;
                12'd104: toneL = `g;	12'd105: toneL = `g;
                12'd106: toneL = `g;	12'd107: toneL = `g;
                12'd108: toneL = `g;	12'd109: toneL = `g;
                12'd110: toneL = `g;	12'd111: toneL = `g;

                12'd112: toneL = `b;	12'd113: toneL = `b; // B (one-beat)
                12'd114: toneL = `b;	12'd115: toneL = `b;
                12'd116: toneL = `b;	12'd117: toneL = `b;
                12'd118: toneL = `b;	12'd119: toneL = `b;
                12'd120: toneL = `b;	12'd121: toneL = `b;
                12'd122: toneL = `b;	12'd123: toneL = `b;
                12'd124: toneL = `b;	12'd125: toneL = `b;
                12'd126: toneL = `b;	12'd127: toneL = `b;

                12'd128: toneL = `hc;    12'd129: toneL = `hc;
                12'd130: toneL = `hc;    12'd131: toneL = `hc;
                12'd132: toneL = `hc;    12'd133: toneL = `hc;
                12'd134: toneL = `hc;    12'd135: toneL = `hc;
                12'd136: toneL = `hc;    12'd137: toneL = `hc;
                12'd138: toneL = `hc;    12'd139: toneL = `hc;
                12'd140: toneL = `hc;    12'd141: toneL = `hc;
                12'd142: toneL = `hc;    12'd143: toneL = `hc;


                12'd144: toneL = `hc;    12'd145: toneL = `hc;
                12'd146: toneL = `hc;    12'd147: toneL = `hc;
                12'd148: toneL = `hc;    12'd149: toneL = `hc;
                12'd150: toneL = `hc;    12'd151: toneL = `hc;
                12'd152: toneL = `hc;    12'd153: toneL = `hc;
                12'd154: toneL = `hc;    12'd155: toneL = `hc;
                12'd156: toneL = `hc;    12'd157: toneL = `hc;
                12'd158: toneL = `hc;    12'd159: toneL = `hc;


                12'd160: toneL = `g;    12'd161: toneL = `g;
                12'd162: toneL = `g;    12'd163: toneL = `g;
                12'd164: toneL = `g;    12'd165: toneL = `g;
                12'd166: toneL = `g;    12'd167: toneL = `g;
                12'd168: toneL = `g;    12'd169: toneL = `g;
                12'd170: toneL = `g;    12'd171: toneL = `g;
                12'd172: toneL = `g;    12'd173: toneL = `g;
                12'd174: toneL = `g;    12'd175: toneL = `g;


                12'd176: toneL = `b;    12'd177: toneL = `b;
                12'd178: toneL = `b;    12'd179: toneL = `b;
                12'd180: toneL = `b;    12'd181: toneL = `b;
                12'd182: toneL = `b;    12'd183: toneL = `b;
                12'd184: toneL = `b;    12'd185: toneL = `b;
                12'd186: toneL = `b;    12'd187: toneL = `b;
                12'd188: toneL = `b;    12'd189: toneL = `b;
                12'd190: toneL = `b;    12'd191: toneL = `b;


                12'd192: toneL = `hc;    12'd193: toneL = `hc;
                12'd194: toneL = `hc;    12'd195: toneL = `hc;
                12'd196: toneL = `hc;    12'd197: toneL = `hc;
                12'd198: toneL = `hc;    12'd199: toneL = `hc;
                12'd200: toneL = `hc;    12'd201: toneL = `hc;
                12'd202: toneL = `hc;    12'd203: toneL = `hc;
                12'd204: toneL = `hc;    12'd205: toneL = `hc;
                12'd206: toneL = `hc;    12'd207: toneL = `hc;


                12'd208: toneL = `g;    12'd209: toneL = `g;
                12'd210: toneL = `g;    12'd211: toneL = `g;
                12'd212: toneL = `g;    12'd213: toneL = `g;
                12'd214: toneL = `g;    12'd215: toneL = `g;
                12'd216: toneL = `g;    12'd217: toneL = `g;
                12'd218: toneL = `g;    12'd219: toneL = `g;
                12'd220: toneL = `g;    12'd221: toneL = `g;
                12'd222: toneL = `g;    12'd223: toneL = `g;


                12'd224: toneL = `e;    12'd225: toneL = `e;
                12'd226: toneL = `e;    12'd227: toneL = `e;
                12'd228: toneL = `e;    12'd229: toneL = `e;
                12'd230: toneL = `e;    12'd231: toneL = `e;
                12'd232: toneL = `e;    12'd233: toneL = `e;
                12'd234: toneL = `e;    12'd235: toneL = `e;
                12'd236: toneL = `e;    12'd237: toneL = `e;
                12'd238: toneL = `e;    12'd239: toneL = `e;


                12'd240: toneL = `c;    12'd241: toneL = `c;
                12'd242: toneL = `c;    12'd243: toneL = `c;
                12'd244: toneL = `c;    12'd245: toneL = `c;
                12'd246: toneL = `c;    12'd247: toneL = `c;
                12'd248: toneL = `c;    12'd249: toneL = `c;
                12'd250: toneL = `c;    12'd251: toneL = `c;
                12'd252: toneL = `c;    12'd253: toneL = `c;
                12'd254: toneL = `c;    12'd255: toneL = `c;


                12'd256: toneL = `g;    12'd257: toneL = `g;
                12'd258: toneL = `g;    12'd259: toneL = `g;
                12'd260: toneL = `g;    12'd261: toneL = `g;
                12'd262: toneL = `g;    12'd263: toneL = `g;
                12'd264: toneL = `g;    12'd265: toneL = `g;
                12'd266: toneL = `g;    12'd267: toneL = `g;
                12'd268: toneL = `g;    12'd269: toneL = `g;
                12'd270: toneL = `g;    12'd271: toneL = `g;


                12'd272: toneL = `g;    12'd273: toneL = `g;
                12'd274: toneL = `g;    12'd275: toneL = `g;
                12'd276: toneL = `g;    12'd277: toneL = `g;
                12'd278: toneL = `g;    12'd279: toneL = `g;
                12'd280: toneL = `g;    12'd281: toneL = `g;
                12'd282: toneL = `g;    12'd283: toneL = `g;
                12'd284: toneL = `g;    12'd285: toneL = `g;
                12'd286: toneL = `g;    12'd287: toneL = `g;


                12'd288: toneL = `f;    12'd289: toneL = `f;
                12'd290: toneL = `f;    12'd291: toneL = `f;
                12'd292: toneL = `f;    12'd293: toneL = `f;
                12'd294: toneL = `f;    12'd295: toneL = `f;
                12'd296: toneL = `f;    12'd297: toneL = `f;
                12'd298: toneL = `f;    12'd299: toneL = `f;
                12'd300: toneL = `f;    12'd301: toneL = `f;
                12'd302: toneL = `f;    12'd303: toneL = `f;


                12'd304: toneL = `d;    12'd305: toneL = `d;
                12'd306: toneL = `d;    12'd307: toneL = `d;
                12'd308: toneL = `d;    12'd309: toneL = `d;
                12'd310: toneL = `d;    12'd311: toneL = `d;
                12'd312: toneL = `d;    12'd313: toneL = `d;
                12'd314: toneL = `d;    12'd315: toneL = `d;
                12'd316: toneL = `d;    12'd317: toneL = `d;
                12'd318: toneL = `d;    12'd319: toneL = `d;


                12'd320: toneL = `e;    12'd321: toneL = `e;
                12'd322: toneL = `e;    12'd323: toneL = `e;
                12'd324: toneL = `e;    12'd325: toneL = `e;
                12'd326: toneL = `e;    12'd327: toneL = `e;
                12'd328: toneL = `e;    12'd329: toneL = `e;
                12'd330: toneL = `e;    12'd331: toneL = `e;
                12'd332: toneL = `e;    12'd333: toneL = `e;
                12'd334: toneL = `e;    12'd335: toneL = `e;


                12'd336: toneL = `e;    12'd337: toneL = `e;
                12'd338: toneL = `e;    12'd339: toneL = `e;
                12'd340: toneL = `e;    12'd341: toneL = `e;
                12'd342: toneL = `e;    12'd343: toneL = `e;
                12'd344: toneL = `e;    12'd345: toneL = `e;
                12'd346: toneL = `e;    12'd347: toneL = `e;
                12'd348: toneL = `e;    12'd349: toneL = `e;
                12'd350: toneL = `e;    12'd351: toneL = `e;


                12'd352: toneL = `g;    12'd353: toneL = `g;
                12'd354: toneL = `g;    12'd355: toneL = `g;
                12'd356: toneL = `g;    12'd357: toneL = `g;
                12'd358: toneL = `g;    12'd359: toneL = `g;
                12'd360: toneL = `g;    12'd361: toneL = `g;
                12'd362: toneL = `g;    12'd363: toneL = `g;
                12'd364: toneL = `g;    12'd365: toneL = `g;
                12'd366: toneL = `g;    12'd367: toneL = `g;


                12'd368: toneL = `b;    12'd369: toneL = `b;
                12'd370: toneL = `b;    12'd371: toneL = `b;
                12'd372: toneL = `b;    12'd373: toneL = `b;
                12'd374: toneL = `b;    12'd375: toneL = `b;
                12'd376: toneL = `b;    12'd377: toneL = `b;
                12'd378: toneL = `b;    12'd379: toneL = `b;
                12'd380: toneL = `b;    12'd381: toneL = `b;
                12'd382: toneL = `b;    12'd383: toneL = `b;

                12'd384: toneL = `hc;  12'd385: toneL = `hc;
                12'd386: toneL = `hc;  12'd387: toneL = `hc;
                12'd388: toneL = `hc;  12'd389: toneL = `hc;
                12'd390: toneL = `hc;  12'd391: toneL = `hc;
                12'd392: toneL = `hc;  12'd393: toneL = `hc;
                12'd394: toneL = `hc;  12'd395: toneL = `hc;
                12'd396: toneL = `hc;  12'd397: toneL = `hc;
                12'd398: toneL = `hc;  12'd399: toneL = `hc;

                12'd400: toneL = `hc;  12'd401: toneL = `hc;
                12'd402: toneL = `hc;  12'd403: toneL = `hc;
                12'd404: toneL = `hc;  12'd405: toneL = `hc;
                12'd406: toneL = `hc;  12'd407: toneL = `hc;
                12'd408: toneL = `hc;  12'd409: toneL = `hc;
                12'd410: toneL = `hc;  12'd411: toneL = `hc;
                12'd412: toneL = `hc;  12'd413: toneL = `hc;
                12'd414: toneL = `hc;  12'd415: toneL = `hc;

                12'd416: toneL = `g;  12'd417: toneL = `g;
                12'd418: toneL = `g;  12'd419: toneL = `g;
                12'd420: toneL = `g;  12'd421: toneL = `g;
                12'd422: toneL = `g;  12'd423: toneL = `g;
                12'd424: toneL = `g;  12'd425: toneL = `g;
                12'd426: toneL = `g;  12'd427: toneL = `g;
                12'd428: toneL = `g;  12'd429: toneL = `g;
                12'd430: toneL = `g;  12'd431: toneL = `g;

                12'd432: toneL = `b;  12'd433: toneL = `b;
                12'd434: toneL = `b;  12'd435: toneL = `b;
                12'd436: toneL = `b;  12'd437: toneL = `b;
                12'd438: toneL = `b;  12'd439: toneL = `b;
                12'd440: toneL = `b;  12'd441: toneL = `b;
                12'd442: toneL = `b;  12'd443: toneL = `b;
                12'd444: toneL = `b;  12'd445: toneL = `b;
                12'd446: toneL = `b;  12'd447: toneL = `b;

                12'd448: toneL = `hc;  12'd449: toneL = `hc;
                12'd450: toneL = `hc;  12'd451: toneL = `hc;
                12'd452: toneL = `hc;  12'd453: toneL = `hc;
                12'd454: toneL = `hc;  12'd455: toneL = `hc;
                12'd456: toneL = `hc;  12'd457: toneL = `hc;
                12'd458: toneL = `hc;  12'd459: toneL = `hc;
                12'd460: toneL = `hc;  12'd461: toneL = `hc;
                12'd462: toneL = `hc;  12'd463: toneL = `hc;

                12'd464: toneL = `g;  12'd465: toneL = `g;
                12'd466: toneL = `g;  12'd467: toneL = `g;
                12'd468: toneL = `g;  12'd469: toneL = `g;
                12'd470: toneL = `g;  12'd471: toneL = `g;
                12'd472: toneL = `g;  12'd473: toneL = `g;
                12'd474: toneL = `g;  12'd475: toneL = `g;
                12'd476: toneL = `g;  12'd477: toneL = `g;
                12'd478: toneL = `g;  12'd479: toneL = `g;

                12'd480: toneL = `hc;  12'd481: toneL = `hc;
                12'd482: toneL = `hc;  12'd483: toneL = `hc;
                12'd484: toneL = `hc;  12'd485: toneL = `hc;
                12'd486: toneL = `hc;  12'd487: toneL = `hc;
                12'd488: toneL = `hc;  12'd489: toneL = `hc;
                12'd490: toneL = `hc;  12'd491: toneL = `hc;
                12'd492: toneL = `hc;  12'd493: toneL = `hc;
                12'd494: toneL = `hc;  12'd495: toneL = `hc;

                12'd496: toneL = `c;  12'd497: toneL = `c;
                12'd498: toneL = `c;  12'd499: toneL = `c;
                12'd500: toneL = `c;  12'd501: toneL = `c;
                12'd502: toneL = `c;  12'd503: toneL = `c;
                12'd504: toneL = `c;  12'd505: toneL = `c;
                12'd506: toneL = `c;  12'd507: toneL = `c;
                12'd508: toneL = `c;  12'd509: toneL = `c;
                12'd510: toneL = `c;  12'd511: toneL = `c;
                default : toneL = `sil;
            endcase
            end
            else begin
                case(ibeatNum)
                12'd0: toneL = `c;	12'd1: toneL = `c;
                12'd2: toneL = `c;	12'd3: toneL = `c;
                12'd4: toneL = `c;	12'd5: toneL = `c;
                12'd6: toneL = `c;	12'd7: toneL = `c;
                12'd8: toneL = `c;	12'd9: toneL = `c;
                12'd10: toneL = `c;	12'd11: toneL = `c;
                12'd12: toneL = `c;	12'd13: toneL = `c;
                12'd14: toneL = `c;	12'd15: toneL = `c;

                12'd16: toneL = `e;	12'd17: toneL = `e;
                12'd18: toneL = `e;	12'd19: toneL = `e;
                12'd20: toneL = `e;	12'd21: toneL = `e;
                12'd22: toneL = `e;	12'd23: toneL = `e;
                12'd24: toneL = `e;	12'd25: toneL = `e;
                12'd26: toneL = `e;	12'd27: toneL = `e;
                12'd28: toneL = `e;	12'd29: toneL = `e;
                12'd30: toneL = `e;	12'd31: toneL = `e;

                12'd32: toneL = `g;	12'd33: toneL = `g;
                12'd34: toneL = `g;	12'd35: toneL = `g;
                12'd36: toneL = `g;	12'd37: toneL = `g;
                12'd38: toneL = `g;	12'd39: toneL = `g;
                12'd40: toneL = `g;	12'd41: toneL = `g;
                12'd42: toneL = `g;	12'd43: toneL = `g;
                12'd44: toneL = `g;	12'd45: toneL = `g;
                12'd46: toneL = `g;	12'd47: toneL = `g;

                12'd48: toneL = `g;	12'd49: toneL = `g;
                12'd50: toneL = `g;	12'd51: toneL = `g;
                12'd52: toneL = `g;	12'd53: toneL = `g;
                12'd54: toneL = `g;	12'd55: toneL = `g;
                12'd56: toneL = `g;	12'd57: toneL = `g;
                12'd58: toneL = `g;	12'd59: toneL = `g;
                12'd60: toneL = `g;	12'd61: toneL = `g;
                12'd62: toneL = `g;	12'd63: toneL = `g;

                12'd64: toneL = `lb;	12'd65: toneL = `lb;
                12'd66: toneL = `lb;	12'd67: toneL = `lb;
                12'd68: toneL = `lb;	12'd69: toneL = `lb;
                12'd70: toneL = `lb;	12'd71: toneL = `lb;
                12'd72: toneL = `lb;	12'd73: toneL = `lb;
                12'd74: toneL = `lb;	12'd75: toneL = `lb;
                12'd76: toneL = `lb;	12'd77: toneL = `lb;
                12'd78: toneL = `lb;	12'd79: toneL = `lb;

                12'd80: toneL = `d;	12'd81: toneL = `d;
                12'd82: toneL = `d;	12'd83: toneL = `d;
                12'd84: toneL = `d;	12'd85: toneL = `d;
                12'd86: toneL = `d;	12'd87: toneL = `d;
                12'd88: toneL = `d;	12'd89: toneL = `d;
                12'd90: toneL = `d;	12'd91: toneL = `d;
                12'd92: toneL = `d;	12'd93: toneL = `d;
                12'd94: toneL = `d;	12'd95: toneL = `d;

                12'd96: toneL = `g;	12'd97: toneL = `g;
                12'd98: toneL = `g;	12'd99: toneL = `g;
                12'd100: toneL = `g;	12'd101: toneL = `g;
                12'd102: toneL = `g;	12'd103: toneL = `g;
                12'd104: toneL = `g;	12'd105: toneL = `g;
                12'd106: toneL = `g;	12'd107: toneL = `g;
                12'd108: toneL = `g;	12'd109: toneL = `g;
                12'd110: toneL = `g;	12'd111: toneL = `g;

                12'd112: toneL = `g;	12'd113: toneL = `g;
                12'd114: toneL = `g;	12'd115: toneL = `g;
                12'd116: toneL = `g;	12'd117: toneL = `g;
                12'd118: toneL = `g;	12'd119: toneL = `g;
                12'd120: toneL = `g;	12'd121: toneL = `g;
                12'd122: toneL = `g;	12'd123: toneL = `g;
                12'd124: toneL = `g;	12'd125: toneL = `g;
                12'd126: toneL = `g;	12'd127: toneL = `g;

                12'd128: toneL = `la;	12'd129: toneL = `la;
                12'd130: toneL = `la;	12'd131: toneL = `la;
                12'd132: toneL = `la;	12'd133: toneL = `la;
                12'd134: toneL = `la;	12'd135: toneL = `la;
                12'd136: toneL = `la;	12'd137: toneL = `la;
                12'd138: toneL = `la;	12'd139: toneL = `la;
                12'd140: toneL = `la;	12'd141: toneL = `la;
                12'd142: toneL = `la;	12'd143: toneL = `la;

                12'd144: toneL = `c;	12'd145: toneL = `c;
                12'd146: toneL = `c;	12'd147: toneL = `c;
                12'd148: toneL = `c;	12'd149: toneL = `c;
                12'd150: toneL = `c;	12'd151: toneL = `c;
                12'd152: toneL = `c;	12'd153: toneL = `c;
                12'd154: toneL = `c;	12'd155: toneL = `c;
                12'd156: toneL = `c;	12'd157: toneL = `c;
                12'd158: toneL = `c;	12'd159: toneL = `c;

                12'd160: toneL = `g;	12'd161: toneL = `g;
                12'd162: toneL = `g;	12'd163: toneL = `g;
                12'd164: toneL = `g;	12'd165: toneL = `g;
                12'd166: toneL = `g;	12'd167: toneL = `g;
                12'd168: toneL = `g;	12'd169: toneL = `g;
                12'd170: toneL = `g;	12'd171: toneL = `g;
                12'd172: toneL = `g;	12'd173: toneL = `g;
                12'd174: toneL = `g;	12'd175: toneL = `g;

                12'd176: toneL = `e;	12'd177: toneL = `e;
                12'd178: toneL = `e;	12'd179: toneL = `e;
                12'd180: toneL = `e;	12'd181: toneL = `e;
                12'd182: toneL = `e;	12'd183: toneL = `e;
                12'd184: toneL = `e;	12'd185: toneL = `e;
                12'd186: toneL = `e;	12'd187: toneL = `e;
                12'd188: toneL = `e;	12'd189: toneL = `e;
                12'd190: toneL = `e;	12'd191: toneL = `e;

                12'd192: toneL = `g;	12'd193: toneL = `g;
                12'd194: toneL = `g;	12'd195: toneL = `g;
                12'd196: toneL = `g;	12'd197: toneL = `g;
                12'd198: toneL = `g;	12'd199: toneL = `g;
                12'd200: toneL = `g;	12'd201: toneL = `g;
                12'd202: toneL = `g;	12'd203: toneL = `g;
                12'd204: toneL = `g;	12'd205: toneL = `g;
                12'd206: toneL = `g;	12'd207: toneL = `g;

                12'd208: toneL = `d;	12'd209: toneL = `d;
                12'd210: toneL = `d;	12'd211: toneL = `d;
                12'd212: toneL = `d;	12'd213: toneL = `d;
                12'd214: toneL = `d;	12'd215: toneL = `d;
                12'd216: toneL = `d;	12'd217: toneL = `d;
                12'd218: toneL = `d;	12'd219: toneL = `d;
                12'd220: toneL = `d;	12'd221: toneL = `d;
                12'd222: toneL = `d;	12'd223: toneL = `d;

                12'd224: toneL = `lb;	12'd225: toneL = `lb;
                12'd226: toneL = `lb;	12'd227: toneL = `lb;
                12'd228: toneL = `lb;	12'd229: toneL = `lb;
                12'd230: toneL = `lb;	12'd231: toneL = `lb;
                12'd232: toneL = `lb;	12'd233: toneL = `lb;
                12'd234: toneL = `lb;	12'd235: toneL = `lb;
                12'd236: toneL = `lb;	12'd237: toneL = `lb;
                12'd238: toneL = `lb;	12'd239: toneL = `lb;

                12'd240: toneL = `lb;	12'd241: toneL = `lb;
                12'd242: toneL = `lb;	12'd243: toneL = `lb;
                12'd244: toneL = `lb;	12'd245: toneL = `lb;
                12'd246: toneL = `lb;	12'd247: toneL = `lb;
                12'd248: toneL = `lb;	12'd249: toneL = `lb;
                12'd250: toneL = `lb;	12'd251: toneL = `lb;
                12'd252: toneL = `lb;	12'd253: toneL = `lb;
                12'd254: toneL = `lb;	12'd255: toneL = `lb;

                12'd256: toneL = `f;	12'd257: toneL = `f;
                12'd258: toneL = `f;	12'd259: toneL = `f;
                12'd260: toneL = `f;	12'd261: toneL = `f;
                12'd262: toneL = `f;	12'd263: toneL = `f;
                12'd264: toneL = `f;	12'd265: toneL = `f;
                12'd266: toneL = `f;	12'd267: toneL = `f;
                12'd268: toneL = `f;	12'd269: toneL = `f;
                12'd270: toneL = `f;	12'd271: toneL = `f;

                12'd272: toneL = `a;	12'd273: toneL = `a;
                12'd274: toneL = `a;	12'd275: toneL = `a;
                12'd276: toneL = `a;	12'd277: toneL = `a;
                12'd278: toneL = `a;	12'd279: toneL = `a;
                12'd280: toneL = `a;	12'd281: toneL = `a;
                12'd282: toneL = `a;	12'd283: toneL = `a;
                12'd284: toneL = `a;	12'd285: toneL = `a;
                12'd286: toneL = `a;	12'd287: toneL = `a;

                12'd288: toneL = `hc;	12'd289: toneL = `hc;
                12'd290: toneL = `hc;	12'd291: toneL = `hc;
                12'd292: toneL = `hc;	12'd293: toneL = `hc;
                12'd294: toneL = `hc;	12'd295: toneL = `hc;
                12'd296: toneL = `hc;	12'd297: toneL = `hc;
                12'd298: toneL = `hc;	12'd299: toneL = `hc;
                12'd300: toneL = `hc;	12'd301: toneL = `hc;
                12'd302: toneL = `hc;	12'd303: toneL = `hc;

                12'd304: toneL = `hc;	12'd305: toneL = `hc;
                12'd306: toneL = `hc;	12'd307: toneL = `hc;
                12'd308: toneL = `hc;	12'd309: toneL = `hc;
                12'd310: toneL = `hc;	12'd311: toneL = `hc;
                12'd312: toneL = `hc;	12'd313: toneL = `hc;
                12'd314: toneL = `hc;	12'd315: toneL = `hc;
                12'd316: toneL = `hc;	12'd317: toneL = `hc;
                12'd318: toneL = `hc;	12'd319: toneL = `hc;

                12'd320: toneL = `e;	12'd321: toneL = `e;
                12'd322: toneL = `e;	12'd323: toneL = `e;
                12'd324: toneL = `e;	12'd325: toneL = `e;
                12'd326: toneL = `e;	12'd327: toneL = `e;
                12'd328: toneL = `e;	12'd329: toneL = `e;
                12'd330: toneL = `e;	12'd331: toneL = `e;
                12'd332: toneL = `e;	12'd333: toneL = `e;
                12'd334: toneL = `e;	12'd335: toneL = `e;

                12'd336: toneL = `g;	12'd337: toneL = `g;
                12'd338: toneL = `g;	12'd339: toneL = `g;
                12'd340: toneL = `g;	12'd341: toneL = `g;
                12'd342: toneL = `g;	12'd343: toneL = `g;
                12'd344: toneL = `g;	12'd345: toneL = `g;
                12'd346: toneL = `g;	12'd347: toneL = `g;
                12'd348: toneL = `g;	12'd349: toneL = `g;
                12'd350: toneL = `g;	12'd351: toneL = `g;

                12'd352: toneL = `c;	12'd353: toneL = `c;
                12'd354: toneL = `c;	12'd355: toneL = `c;
                12'd356: toneL = `c;	12'd357: toneL = `c;
                12'd358: toneL = `c;	12'd359: toneL = `c;
                12'd360: toneL = `c;	12'd361: toneL = `c;
                12'd362: toneL = `c;	12'd363: toneL = `c;
                12'd364: toneL = `c;	12'd365: toneL = `c;
                12'd366: toneL = `c;	12'd367: toneL = `c;

                12'd368: toneL = `c;	12'd369: toneL = `c;
                12'd370: toneL = `c;	12'd371: toneL = `c;
                12'd372: toneL = `c;	12'd373: toneL = `c;
                12'd374: toneL = `c;	12'd375: toneL = `c;
                12'd376: toneL = `c;	12'd377: toneL = `c;
                12'd378: toneL = `c;	12'd379: toneL = `c;
                12'd380: toneL = `c;	12'd381: toneL = `c;
                12'd382: toneL = `c;	12'd383: toneL = `c;

                12'd384: toneL = `d;	12'd385: toneL = `d;
                12'd386: toneL = `d;	12'd387: toneL = `d;
                12'd388: toneL = `d;	12'd389: toneL = `d;
                12'd390: toneL = `d;	12'd391: toneL = `d;
                12'd392: toneL = `d;	12'd393: toneL = `d;
                12'd394: toneL = `d;	12'd395: toneL = `d;
                12'd396: toneL = `d;	12'd397: toneL = `d;
                12'd398: toneL = `d;	12'd399: toneL = `d;

                12'd400: toneL = `g;	12'd401: toneL = `g;
                12'd402: toneL = `g;	12'd403: toneL = `g;
                12'd404: toneL = `g;	12'd405: toneL = `g;
                12'd406: toneL = `g;	12'd407: toneL = `g;
                12'd408: toneL = `g;	12'd409: toneL = `g;
                12'd410: toneL = `g;	12'd411: toneL = `g;
                12'd412: toneL = `g;	12'd413: toneL = `g;
                12'd414: toneL = `g;	12'd415: toneL = `g;

                12'd416: toneL = `d;	12'd417: toneL = `d;
                12'd418: toneL = `d;	12'd419: toneL = `d;
                12'd420: toneL = `d;	12'd421: toneL = `d;
                12'd422: toneL = `d;	12'd423: toneL = `d;
                12'd424: toneL = `d;	12'd425: toneL = `d;
                12'd426: toneL = `d;	12'd427: toneL = `d;
                12'd428: toneL = `d;	12'd429: toneL = `d;
                12'd430: toneL = `d;	12'd431: toneL = `d;

                12'd432: toneL = `la;	12'd433: toneL = `la;
                12'd434: toneL = `la;	12'd435: toneL = `la;
                12'd436: toneL = `la;	12'd437: toneL = `la;
                12'd438: toneL = `la;	12'd439: toneL = `la;
                12'd440: toneL = `la;	12'd441: toneL = `la;
                12'd442: toneL = `la;	12'd443: toneL = `la;
                12'd444: toneL = `la;	12'd445: toneL = `la;
                12'd446: toneL = `la;	12'd447: toneL = `la;

                12'd448: toneL = `lg;	12'd449: toneL = `lg;
                12'd450: toneL = `lg;	12'd451: toneL = `lg;
                12'd452: toneL = `lg;	12'd453: toneL = `lg;
                12'd454: toneL = `lg;	12'd455: toneL = `lg;
                12'd456: toneL = `lg;	12'd457: toneL = `lg;
                12'd458: toneL = `lg;	12'd459: toneL = `lg;
                12'd460: toneL = `lg;	12'd461: toneL = `lg;
                12'd462: toneL = `lg;	12'd463: toneL = `lg;

                12'd464: toneL = `lb;	12'd465: toneL = `lb;
                12'd466: toneL = `lb;	12'd467: toneL = `lb;
                12'd468: toneL = `lb;	12'd469: toneL = `lb;
                12'd470: toneL = `lb;	12'd471: toneL = `lb;
                12'd472: toneL = `lb;	12'd473: toneL = `lb;
                12'd474: toneL = `lb;	12'd475: toneL = `lb;
                12'd476: toneL = `lb;	12'd477: toneL = `lb;
                12'd478: toneL = `lb;	12'd479: toneL = `lb;

                12'd480: toneL = `d;	12'd481: toneL = `d;
                12'd482: toneL = `d;	12'd483: toneL = `d;
                12'd484: toneL = `d;	12'd485: toneL = `d;
                12'd486: toneL = `d;	12'd487: toneL = `d;
                12'd488: toneL = `d;	12'd489: toneL = `d;
                12'd490: toneL = `d;	12'd491: toneL = `d;
                12'd492: toneL = `d;	12'd493: toneL = `d;
                12'd494: toneL = `d;	12'd495: toneL = `d;

                12'd496: toneL = `d;	12'd497: toneL = `d;
                12'd498: toneL = `d;	12'd499: toneL = `d;
                12'd500: toneL = `d;	12'd501: toneL = `d;
                12'd502: toneL = `d;	12'd503: toneL = `d;
                12'd504: toneL = `d;	12'd505: toneL = `d;
                12'd506: toneL = `d;	12'd507: toneL = `d;
                12'd508: toneL = `d;	12'd509: toneL = `d;
                12'd510: toneL = `d;	12'd511: toneL = `d;
                default : toneL = `sil;
            endcase
            end
        end
        else begin
            toneL = `sil;
        end
    end
endmodule