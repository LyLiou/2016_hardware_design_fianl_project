module Composer(
		output wire [3:0] freq,
		output reg [6:0] pos,
		output reg composing,
		output wire [2:0] h,
		input wire rst, dclk12,
		input wire high, low, left, right,
		input wire [12:0] freq_in,
		input wire [4:0] h_in,
		input wire [7:0] len_in,
		input wire [31:0] tempo,
		input wire play,
		input wire to_start
	);
	
	wire play_op, left_op, right_op, to_start_op;
	onepulse op1(.sign(play_op), .In(play), .dclk(dclk12));
	onepulse op2(.sign(to_start_op), .In(to_start), .dclk(dclk12));
	onepulse op3(.sign(left_op), .In(left), .dclk(dclk12));
	onepulse op4(.sign(right_op), .In(right), .dclk(dclk12));
	
	reg ncomposing; //composing or playing?
	reg [3:0] nfreq_ram;
	reg [2:0] nh_ram;
	reg [7:0] nlen_ram;//next value for 3 RAM on current position
	reg [3:0] freq_ram[0:127];
	reg [2:0] h_ram[0:127];
	reg [7:0] len_ram[0:127];//3 RAM to restore a song
	
	wire [3:0] freq_tuner;
	wire [2:0] h_tuner;
	
	reg [6:0] npos;
	reg [31:0] count, ncount, len;
	
	//mute a while to divide same tone
	assign freq = (len-count < 32'd500) ? 4'b1100 : freq_ram[pos];
	assign h = h_ram[pos];
	
	Tuner(
		.freq(freq_tuner),
		.h(h_tuner),
		.rst(rst), .dclk(dclk12),
		.high(), .low(),
		.freq_in(freq_in),
		.h_in(h_in)
	);//use a tuner as decoder: 5*12->5'one hot+12'one hot
		
	always @(posedge dclk12) begin //DFF
		if(rst) begin
			composing <= 1'b1;
			pos <= 7'b000_0000;
			count <= 0;
		end else begin
			composing <= ncomposing;
			pos <= npos;
			count <= ncount;
			freq_ram[pos] <= nfreq_ram;
			h_ram[pos] <= nh_ram;
			len_ram[pos] <= nlen_ram;
		end
	end
	
	always @(*) begin
	//if is composing and there are any input, update value in RAM
		nfreq_ram = (composing & (|{freq_in, h_in, len_in})) ?
					freq_tuner :
					freq_ram[pos];
		nh_ram    = (composing & (|{freq_in, h_in, len_in})) ?
				    h_tuner :
			   	    h_ram[pos];
		nlen_ram  = (composing & |len_in)
				    ? len_in :
				    len_ram[pos];
	end
	
	always @(*) begin
	//decode the length input
	//these are most often use in music
		case(len_ram[pos])
			8'b00000001: len = (tempo/3)*2;
			8'b00000010: len = tempo/3;
			8'b00000100: len = tempo/4;
			8'b00001000: len = tempo/2;
			8'b00010000: len = tempo;
			8'b00100000: len = (tempo/2)*3;
			8'b01000000: len = tempo*2;
			8'b10000000: len = tempo*3;
			default: len = tempo;
		endcase
	end
	always @(*) begin
		//play or stop
		if(play_op) ncomposing = ~composing;
		else ncomposing = composing;
	end
	always @(*) begin
		//count is use to play a note
		//the length of a note = count from 0 to len
		if(composing) begin
			//set count to 0 -> to play this note again
			//if there are any input, play again that user can check
			ncount = (|{freq_in, h_in, len_in, left_op, right_op}) ?
					 32'd0 :
					 ((count<len) ? count+1 : len);
		end else begin
			//loop from 0 to len while playing
			ncount = (count<len) ? count+1 : 0;
		end
	end
	always @(*) begin
		//here to change the position in RAM
		//each position is a note
		if(composing==1'b1) begin
			npos = pos;
			//left right to change one position
			if(left_op | right_op) begin
				if(left_op & right_op) begin
					npos = pos;
				end else if(right_op) begin
					if(pos == 7'd127) npos = pos;
					else npos = pos+1;
				end else begin
					if(pos == 7'd0) npos = pos;
					else npos = pos-1;
				end
			end
			//to the beginning
			if(to_start_op) npos = 0;
		end else begin
			//while playing, change position after a note is finished
			npos = pos;
			if(count==len) npos = (pos == 7'd127) ? pos : pos+1;
		end
	end
endmodule