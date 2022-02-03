module metronome(
		output wire [3:0] freq,
		output wire [2:0] h,
		output wire [31:0] count_max,
		output reg [31:0] bpm,
		input wire rst, dclk12, dclk22,
		input wire up, down,
		input wire [2:0] meter
	);

	wire [31:0] ncount;
	reg [31:0] count, nbpm;
	reg [1:0] beat, nbeat, count_beat;
	//by calculating, change bpm -> Hz in FPGA
	//bpm: beat per minute, used in almost every music sheet
	assign count_max = 32'd732420/bpm;
	assign ncount = (count < count_max) ? count+1 : 32'd0;
	
	assign freq = (count < 32'd1000) ? 4'b1000 : 4'b1100;//only a short beep
	assign h = (count_beat==beat) ? 3'b100 : 3'b011;
	
	always @(posedge dclk22) begin
		if(rst) begin
			bpm <= 32'd88;
		end else begin
			bpm <= nbpm;
		end
	end
	always @(posedge dclk12) begin
		//use high clock for precise bpm
		//32-bit counter to count one beat
		//2-bit counter to count the high beat
		if(rst) begin
			count <= 32'd0;
			count_beat <= 2'b00;
			beat <= 2'b11;
		end else begin
			count <= ncount;
			count_beat <= (count==32'd0) ?
						  ((count_beat==beat) ? 2'b00 : count_beat+1) :
						  count_beat;
			beat <= nbeat;
		end
	end
	always @(*) begin
		//decode meter signature 2/4, 3/4, 4/4
		case(meter)
			3'b100: nbeat = 2'b01;
			3'b010: nbeat = 2'b10;
			3'b001: nbeat = 2'b11;
			default: nbeat = beat;
		endcase
	end
	always @(*) begin
		//change bpm by two keys
		nbpm = bpm;
		if(up | down) begin
			if(up & down) begin
				nbpm = bpm;
			end else if(up) begin
				nbpm = (bpm == 32'd220) ? bpm :bpm+1;
			end else begin
				nbpm = (bpm == 32'd40) ? bpm : bpm-1;
			end
		end
	end
endmodule