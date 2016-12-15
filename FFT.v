module fft_256(data_in_r, data_in_i, RST, CLK, data_out_r, data_out_in);

input [15:0] data_in_r, data_in_i;
input RST, CLK;

output [15:0] data_out_r, data_out_i;

reg [6:0] RAM0_r[15:0], RAM0_i[15:0];  //128
reg [5:0] RAM1_r[15:0], RAM1_i[15:0];  //64
reg [4:0] RAM2_r[15:0], RAM2_i[15:0];  //32
reg [7:0] RAM_out[15:0];
reg [7:0] k0, 
reg f1, f3, f5, f7;
reg [1:0] f2, f4, f6;
reg input_en, stage0_compute;
	stage1_ready, stage1_compute,
	stage2_ready, stage2_compute;

always @(posedge CLK)
begin
	if(RST)
	begin
		input_en <= 1;
		stage1_ready <= 0;
		stage1_compute <= 0;
		stage2_ready <= 0;
		stage2_compute <= 0;
		out_en <= 0;
		k0 <= 0;
		k1 <= 0;
		k2 <= 0;
		l0 <= 0;
		l1 <= 0;
		l2 <= 0;
		f1 <= 0;
		f2 <= 0;
	end
	else
end

BF0 BF(.ar(Ar0),.ai(Ai0),.br(Br0),.bi(Bi0),.cr(Cr0),.ci(Ci0),.dr(Dr0),.di(Di0)) //Two inputs. Two outputs. C:Addition; D:Substraction
TF0 TJ(.tr(Tr0),.ti(Ti0),.sel(Sel0),.sr(Sr0),.si(Si0))		//only needs to implement * (-j)

always @(posedge CLK)		//STAGE 0 Store: starts at 0, loop of 256; Space: 128
begin
	if(input_en)
	begin
		if(k0 < 128)		//Input data go into RAM 0
		begin
			RAM0_r[k0] <= Data_in_r;
			RAM0_i[k0] <= Data_in_i;
			k0 <= k0+1;
			if(k0 == 127)
			begin	
				stage0_compute <= 1;	//Enable this stage's BF
				l0 <= 0;				//Address signal for BF
				stage0_tf <= 1;			//Enable this stage's Twiddle Factor Module
				t0 <= 0;				//Address signal for TF
			end
		end
		else if(k0 < 256)	
		begin
			RAM0_r[k0-128] <= Dr0;		//Subtraction part goes back io RAM0,(0-128), (1-129)...(63-191)
			RAM0_i[k0-128] <= Di0;		
			k0 <= k0+1;
			if(k0 == 255)
			begin
				stage0_compute <= 0;	//Disable this stage's BF
				k0 <= 0;
			end
		end
	end
end

always @(negedge CLK)		//STAGE 0 Butterfly: starts at 128, closes at 256; repeat
begin
	if(stage0_compute)
	begin
		if(l0 < 128)
		begin
			Ar0 <= RAM0_r[l0];		//From RAM anterior data: 0, 1, 2, ..., 127
			Ai0 <= RAM0_i[l0];
			Br0 <= Data_in_r;		//From input: 128, 129, ..., 255
			Bi0 <= Data_in_i;
			l0 <= l0+1;
		end
	end
end

always @(posedge CLK)		//STAGE 0 Twiddle Factor: starts at 128, loop of 256
begin
	if(stage0_tf)
	begin
		stage1_ready <= 1;	//Open the stage 1's RAM after data enters into tf module
		if(t0 < 128)
		begin
			Tr0 <= Cr0;		//Addition part goes to tf module: (0+128),(1+129),...(127+255)
			Ti0 <= Ci0;
			Sel0 <= 0; 	
		end
		else
		begin
			Tr0 <= RAM0_r[t0-128];
			Ti0 <= RAM0_i[t0-128];
			if(t0 < 192)
				Sel0 <= 0;
			else			//Last one quarter of the data, needs to * (-j)
				Sel0 <= 1;
		end
		t0 <= t0+1;			//t0: "255" + 1 ="0"
	end
end

BF1 BF(.ar(Ar1),.ai(Ai1),.br(Br1),.bi(Bi1),.cr(Cr1),.ci(Ci1),.dr(Dr1),.di(Di1))
TF1 TF(.tr(Tr1),.ti(Ti1),.wr(Wr1),.wi(Wi1),.sr(Sr1),.si(Si1))	//input the twiddle factor

always @(posedge CLK)		//STAGE 1 STORE: starts at 129, loop of 128; Space: 64
begin
	if(stage1_ready)		
	begin
		if(k1 < 64)		
		begin					
			begin
				RAM1_r[k1] <= Sr0;		//Fetch from the last stage's buffer
				RAM1_i[k1] <= Si0;		
			end
			k1 <= k1+1;
			if(k1 == 63)
			begin	
				stage1_compute <= 1;	//Enable this stage's BF
				l1 <= 0;
				stage1_tf <= 1;			//Enable Twiddle Factor Module
				t1 <= 0;
			end
		end
		else if (k1 < 128)			
		begin
			RAM1_r[k1-64] <= Dr1;		//From this stage's BF
			RAM1_i[k1-64] <= Di1;
			k1 <= k1+1;
			if(k1 == 127)
			begin
				stage1_compute <= 0;	//Disable this stage's BF, repeat
				k1 <= 0;
			end
		end
	end
end

always @(negedge CLK)		//STAGE 1 Butterfly:
begin
	if(stage1_compute)
	begin
		if(l1 < 64)
		begin
			Ar1 <= RAM1_r[l1];		//From this stage's RAM anterior data
			Ai1 <= RAM1_i[l1];
			Br1 <= Sr0;				//From last stage's buffer output	
			Bi1 <= Si0;
			l1 <= l1+1;
		end
	end
end

always @(posedge CLK)		//STAGE 1 Twiddle Factor: 
begin
	if(stage1_tf)
	begin
		stage2_ready <= 1;	//Open the stage 2's RAM after data enters into tf module
		if(t1 < 64)			//CC, * W(0,0,0...)
		begin
			Tr1 <= Cr1;		//Addtion: (0+128+64+192,...)
			Ti1 <= Ci1;
			Wr1 <= 1;
			Wi1 <= 0;
		end
		else if(t1 < 128)	//CD,* W(0,2,4,...,126)
		begin
			Tr1 <= RAM1_r[t1-64];		//From this stage's RAM：(0+128-(64+192))...
			Ti1 <= RAM1_i[t1-64];
			Wr1 <= TwFr1[(t1-64)*2];	//Bad solution!!!(How to assign the address)?
			Wi1 <= TwFi1[(t1-64)*2];
		end
		else if (t1 < 192)	//DC,* W(0,1,2,3,...,63)
		begin
			Tr1 <= Cr1;		//Addtion: ((0-128)+(64-192),...)
			Ti1 <= Ci1;
			Wr1 <= TwFr1[t1-128];		//Bad solution!!!(How to assign the address)?
			Wi1 <= TwFi1[t1-128];
		end
		else if (t1 < 256)	//DD,* W(0,3,6,...,189)
		begin
			Tr1 <= RAM1_r[t1-128];		//From this stage's RAM：(0-128-(64-192))...
			Ti1 <= RAM1_i[t1-128];
			Wr1 <= TwFr1[(t1-192)*3];	//Bad solution!!!(How to assign the address)?
			Wi1 <= TwFi1[(t1-192)*3];
		end
		t1 <= t1 + 1;
	end
end

//repeat....

endmodule
