module Tuner(
		output reg [3:0] freq,
		output reg [2:0] h,
		input wire rst, dclk,
		input wire high, low,
		input wire [12:0] freq_in,
		input wire [4:0] h_in
	);
		
	parameter C  = 4'b0000;
	parameter Cs = 4'b0001;
	parameter D  = 4'b0010;
	parameter Ds = 4'b0011;
	parameter E  = 4'b0100;
	parameter F  = 4'b0101;
	parameter Fs = 4'b0110;
	parameter G  = 4'b0111;
	parameter Gs = 4'b1000;
	parameter A  = 4'b1001;
	parameter As = 4'b1010;
	parameter B  = 4'b1011;
	parameter X  = 4'b1100;
	
	reg [3:0] nfreq;
	reg [2:0] nh;
	
	always @(posedge dclk) begin
		if(rst) begin
			freq = A;
			h = 3'b010;
		end else begin
			freq = nfreq;
			h = nh;
		end
	end
	
	always @(*) begin
		nfreq = freq;
		if(high | low) begin
			//use two key to change semitone
			if(high & low) begin
				nfreq = freq;
			end else if(high) begin
				if(freq == B) nfreq = C;
				else nfreq = freq+1'b1;
			end else begin
				if(freq == C) nfreq = B;
				else nfreq = freq-1'b1;
			end
		end else begin
			//or directly change it by 12*5 one hot
			case(freq_in)
				13'b0_0000_0000_0001: nfreq = C;
				13'b0_0000_0000_0010: nfreq = Cs;
				13'b0_0000_0000_0100: nfreq = D;
				13'b0_0000_0000_1000: nfreq = Ds;
				13'b0_0000_0001_0000: nfreq = E;
				13'b0_0000_0010_0000: nfreq = F;
				13'b0_0000_0100_0000: nfreq = Fs;
				13'b0_0000_1000_0000: nfreq = G;
				13'b0_0001_0000_0000: nfreq = Gs;
				13'b0_0010_0000_0000: nfreq = A;
				13'b0_0100_0000_0000: nfreq = As;
				13'b0_1000_0000_0000: nfreq = B;
				13'b1_0000_0000_0000: nfreq = X;
				default: nfreq = freq;
			endcase
		end
	end
	
	always @(*) begin
		//decode
		nh = h;
		case(h_in)
			5'b00001: nh = 3'b100;
			5'b00010: nh = 3'b011;
			5'b00100: nh = 3'b010;
			5'b01000: nh = 3'b001;
			5'b10000: nh = 3'b000;
		endcase
		if(high && (freq == B)) begin
			if(h == 3'd4) nh = 3'd0;
			else nh = h+1'b1;
		end
		if(low && (freq == C)) begin
			if(h == 3'd0) nh = 3'd4;
			else nh = h-1'b1;
		end
	end
endmodule