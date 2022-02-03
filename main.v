module Top(
    output wire [3:0] an,
    output wire [6:0] seg,
	output wire [15:0] led,
	output wire ja1, ja2, ja4,
	input  clk_r,
	input  rst_r,
	inout wire PS2Data,
	inout wire PS2Clk
	);
	parameter BTN_F1    = 9'b0_0000_0101;
	parameter BTN_F2    = 9'b0_0000_0110;
	parameter BTN_F3    = 9'b0_0000_0100;
	parameter BTN_F4    = 9'b0_0000_1100;
	parameter BTN_WAVE  = 9'b0_0000_1110;
    parameter BTN_0     = 9'b0_0100_0101;
    parameter BTN_1     = 9'b0_0001_0110;
    parameter BTN_2     = 9'b0_0001_1110;
    parameter BTN_3     = 9'b0_0010_0110;
    parameter BTN_4     = 9'b0_0010_0101;
    parameter BTN_5     = 9'b0_0010_1110;
    parameter BTN_6     = 9'b0_0011_0110;
    parameter BTN_7     = 9'b0_0011_1101;
    parameter BTN_8     = 9'b0_0011_1110;
    parameter BTN_9     = 9'b0_0100_0110;
    parameter BTN_SUB   = 9'b0_0100_1110;
    parameter BTN_PLUS  = 9'b0_0101_0101;
    parameter BTN_Q     = 9'b0_0001_0101;
    parameter BTN_A     = 9'b0_0001_1100;
    parameter BTN_Z     = 9'b0_0001_1010;
    parameter BTN_W     = 9'b0_0001_1101;
    parameter BTN_S     = 9'b0_0001_1011;
    parameter BTN_X     = 9'b0_0010_0010;
    parameter BTN_E     = 9'b0_0010_0100;
    parameter BTN_D     = 9'b0_0010_0011;
    parameter BTN_C     = 9'b0_0010_0001;
    parameter BTN_R     = 9'b0_0010_1101;
    parameter BTN_F     = 9'b0_0010_1011;
    parameter BTN_V     = 9'b0_0010_1010;
    parameter BTN_P     = 9'b0_0100_1101;
    parameter BTN_LEFT  = 9'b0_0101_0100;
    parameter BTN_RIGHT = 9'b0_0101_1011;
    parameter BTN_ENTER = 9'b0_0101_1010;
    parameter BTN_R1     = 9'b0_0110_1001;
    parameter BTN_R2     = 9'b0_0111_0010;
    parameter BTN_R3     = 9'b0_0111_1010;
    parameter BTN_R4     = 9'b0_0110_1011;
    parameter BTN_R5     = 9'b0_0111_0011;
    parameter BTN_R6     = 9'b0_0111_0100;
    parameter BTN_R7     = 9'b0_0110_1100;
    parameter BTN_R8     = 9'b0_0111_0101;
    
    //top
    wire dclk12, dclk18, dclk22, dclk23, rst;
    declock dc0(.Oclk(dclk12), .Iclk(clk_r), .n(5'd12));
    declock dc1(.Oclk(dclk18), .Iclk(clk_r), .n(5'd18));
    declock dc2(.Oclk(dclk22), .Iclk(clk_r), .n(5'd22));
    declock dc3(.Oclk(dclk23), .Iclk(clk_r), .n(5'd23));
    
    debounce db1(.Out(rst), .In(rst_r), .mclk(clk_r));
    reg [1:0] mode, nmode;
    wire mode1_on, mode2_on, mode3_on;
    assign mode1_on = (mode == 2'b01) ? 1'b1 : 1'b0;
    assign mode2_on = (mode == 2'b10) ? 1'b1 : 1'b0;
    assign mode3_on = (mode == 2'b11) ? 1'b1 : 1'b0;
    
    //keyboard
    wire [511:0] key_down, key_down_op;
	wire [8:0] last_change;
	wire been_ready;
	KeyboardDecoder key_de(
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2Data),
		.PS2_CLK(PS2Clk),
		.rst(rst),
		.clk(clk_r)
	);
	wire F1_op, F2_op, F3_op, F4_op;
	onepulse op1(.sign(F1_op), .In(key_down[BTN_F1]), .dclk(dclk18));
	onepulse op2(.sign(F2_op), .In(key_down[BTN_F2]), .dclk(dclk18));
	onepulse op3(.sign(F3_op), .In(key_down[BTN_F3]), .dclk(dclk18));
	onepulse op4(.sign(F4_op), .In(key_down[BTN_F4]), .dclk(dclk18));
	
    //audio
    wire [3:0] freq_out1, freq_out2, freq_out3;
	reg [3:0] freq_out_top;
	wire [2:0] h_out1, h_out2, h_out3;
	reg [2:0] h_out_top;
    wire [12:0] freq_in;
    assign freq_in = {
		key_down[BTN_WAVE],
		key_down[BTN_V],
		key_down[BTN_C],
		key_down[BTN_X],
		key_down[BTN_Z],
		key_down[BTN_F],
		key_down[BTN_D],
		key_down[BTN_S],
		key_down[BTN_A],
		key_down[BTN_R],
		key_down[BTN_E],
		key_down[BTN_W],
		key_down[BTN_Q]
	};
	wire [4:0] h_in;
	assign h_in = {
		key_down[BTN_1],
		key_down[BTN_2],
		key_down[BTN_3],
		key_down[BTN_4],
		key_down[BTN_5]
	};
	speaker spk(
		.clk(clk_r), .rst(rst),
		.freq(freq_out_top),
		.h(h_out_top),
		.duty(10'd512), .PWM(ja1)
	);
	
	assign ja2 = 1'b1;
	assign ja4 = (mode==2'b00) ? 1'b0 : 1'b1;
	
	//Tuner
	Tuner tn1(.freq(freq_out1), .h(h_out1),
		  .rst(rst), .dclk(dclk23),
		  .high(key_down[BTN_PLUS] & mode1_on),
		  .low(key_down[BTN_SUB] & mode1_on),
		  .freq_in(freq_in & {12{mode1_on}}),
		  .h_in(h_in & {5{mode1_on}})
	);
	
	//Metronome
	wire [31:0] tempo, bpm;
	metronome mtr(
		.freq(freq_out2), .h(h_out2),
		.count_max(tempo), .bpm(bpm),
		.rst(rst), .dclk12(dclk12), .dclk22(dclk22),
		.up(key_down[BTN_PLUS] &  mode2_on),
		.down(key_down[BTN_SUB] & mode2_on),
		.meter({key_down[BTN_1], key_down[BTN_2], key_down[BTN_3]} & {3{mode2_on}})
	);
	
	//Composer
	wire [7:0] len_in;
	assign len_in = {
		key_down[BTN_R1],
		key_down[BTN_R2],
		key_down[BTN_R3],
		key_down[BTN_R4],
		key_down[BTN_R5],
		key_down[BTN_R6],
		key_down[BTN_R7],
		key_down[BTN_R8]
	};
	wire [6:0] pos;
	wire composing;
	assign led[15:0] = {16{~composing}};
	Composer cmp(
		.freq(freq_out3), .h(h_out3),
		.pos(pos), .composing(composing),
		.rst(rst), .dclk12(dclk12),
		.high(key_down[BTN_PLUS] & mode3_on),
		.low(key_down[BTN_SUB] & mode3_on),
		.left(key_down[BTN_LEFT] & mode3_on),
		.right(key_down[BTN_RIGHT] & mode3_on),
		.freq_in(freq_in & {12{mode3_on}}),
		.h_in(h_in & {5{mode3_on}}),
		.len_in(len_in),
		.tempo(tempo),
		.play(key_down[BTN_ENTER] & mode3_on),
		.to_start(key_down[BTN_P] & mode3_on)
	);
	
	//Display
    reg [12:0] to_display;
    DisplayDigit dd(.an(an), .seg(seg),
    				.rst(rst), .value(to_display),
    				.dclk18(dclk18), .clk_r(clk_r)
    );
    
    always @(posedge dclk18) begin
        if(rst)begin
        	mode <= 2'b00;
        end else begin
        	mode <= nmode;
        end
    end
    always @(*) begin
    	nmode = mode;
    	if(F1_op|F2_op) begin
    		if(F1_op) nmode = 2'b01;
    		else nmode = 2'b10;
    	end else if(F3_op|F4_op) begin
    		if(F3_op) nmode = 2'b11;
    		else nmode = 2'b00;
    	end
    end
    always @(*) begin
    	case(mode)
    		2'b00: begin
    			freq_out_top = 4'b1100;
    			h_out_top = 3'b010;
    			to_display = {13{1'b0}};
    		end
    		2'b01: begin
    			freq_out_top = freq_out1;
    			h_out_top = h_out1;
    			to_display = {13{1'b0}};
    		end
    		2'b10: begin
    			freq_out_top = freq_out2;
    			h_out_top = h_out2;
    			to_display = bpm[12:0];
    		end
    		2'b11: begin
    			freq_out_top = freq_out3;
    			h_out_top = h_out3;
    			to_display = {6'b000000, pos}+1'b1;
    		end
    	endcase
    end
endmodule