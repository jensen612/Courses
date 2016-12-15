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

BF0 BF(.ar(Ar0),.ai(Ai0),.br(Br0),.bi(Bi0),.cr(Cr0),.ci(Ci0),.dr(Dr0),.di(Di0))
TF0 TF(.tr(Tr0),.ti(Ti0),.sel(sel0),.sr(Sr0),.si(Si0))

always @(posedge CLK)		//STAGE 0 Store: 0-255 cycle, from input or this BF's substraction
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
				l0 <= 0;
				stage1_tf <= 1;			//Enable this stage's Twiddle Factor Module
				t0 <= 0;
			end
		end
		else if(k0 < 256)	//Input data directly BF with previous data, (0,128), (1,129)...(127,255)
		begin
			RAM0_r[k1-128] <= Dr0;		//Subtraction part goes back io RAM0,(0-128),(1-129)...(63-191)
			RAM0_i[k1-128] <= Di0;		
			k0 <= k0+1;
			if(k0 == 255)
			begin
				stage0_compute <= 0;	//Disable this stage's BF, repeat
				k0 <= 0;
			end
		end
	end
end

always @(negedge CLK)		//STAGE 0 Butterfly: 128+256*t - 255+256*t cycle
begin
	if(stage0_compute)
	begin
		if(l0 < 128)
		begin
			Ar0 <= RAM0_r[l0];		//From RAM anterior data
			Ai0 <= RAM0_i[l0];
			Br0 <= Data_in_r;		//From input
			Bi0 <= Data_in_i;
			l0 <= l0+1;
		end
	end
end

always @(posedge CLK)		//STAGE 0 Twiddle Factor: 
begin
	if(stage0_tf)
	begin
		stage1_ready <= 1;
		if(t0 < 128)
		begin
			Tr0 <= Cr0;
			Ti0 <= Ci0;
			Sel <= 0; 	//Whether needs to * (-j)
		end
		else
		begin
			Tr0 <= RAM0_r[t0-128];
			Ti0 <= RAM0_i[t0-128];
			if(t0 >= 192)
				Sel <= ;
		
		end
		t0 <= t0+1;
	end
end

BF1 BF(.ar(Ar1),.ai(Ai1),.br(Br1),.bi(Bi1),.cr(Cr1),.ci(Ci1),.dr(Dr1),.di(Di1))
TF0 TF(.tr(Tr0),.ti(Ti0),.wr(Wr0),.wi(Wi0),.sr(Sr0),.si(Si0))

always @(posedge CLK)		//STAGE 1 STORE: 128-255 cycle
begin
	if(stage1_ready)		
	begin
		if(k1 < 64)		
		begin					
			begin
				RAM1_r[k1] <= Sr0;	//Fetch from the last stage's buffer
				RAM1_i[k1] <= Si0;		
			end
			k1 <= k1+1;
			if(k1 == 63)
			begin	
				stage1_compute <= 1;	//Enable this stage's BF
				l1 <= 0;
				stage1_tf <= 1;			//Enable Twiddle Factor Module
				k2 <= 0;
			end
		endssds
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

always @(negedge CLK)		//STAGE 1 Compute: 193 -256 cycle
begin
	if(stage1_compute)
	begin
		if(l1 < 64)
		begin
			Ar1 <= RAM1_r[l1];		//From this stage's RAM anterior data
			Ai1 <= RAM1_i[l1];
			if(f1)					//From last stage's BF
			begin
				Br1 <= Cr0;				
				Bi1 <= Ci0;
			end
			else					//From last stage's RAM, should * (-j) (D)
			begin
				Br1 <= RAM0_r[l1+64];					
				Bi1 <= RAM0_i[l1+64];
			end
			l1 <= l1+1;
		end
	end
end

always @(posedge CLK)		//STAGE 1 Twiddle Factor: 
begin
	if(stage0_tf)
	begin
		stage1_ready <= 1;
		if(t0 < 128)
		begin
			Tr0 <= Cr0;
			Ti0 <= Ci0;
			Sel <= ; 	//Whether needs to * (-j)
		end
		else
		begin
			Tr0 <= RAM0_r[t0-128];
			Ti0 <= RAM0_i[t0-128];
			Sel <= ;
		
		end
		t0 <= t0+1;
	end
end

BF2 BF(.ar(Ar2),.ai(Ai2),.br(Br2),.bi(Bi2),.cr(Cr2),.ci(Ci2),.dr(Dr2),.di(Di2))

always @(posedge CLK)		//STAGE 2 STORE
begin
	if(stage2_ready)		
	begin
		if(k2 < 32)					
		begin
			case(f2)
			"00":		//From last stage's BF, Addition part goes to RAM2, should * W(k2*0),(CC)
			begin
				RAM2_r[k2] <= Cr1;	
				RAM2_i[k2] <= Ci1;		
			end
			"01":		//From last stage' RAM, should * W(k2*2),(CD)
			begin
				RAM2_r[k2] <= RAM1_r[k2];		
				RAM2_i[k2] <= RAM1_i[k2];
			end
			"10":		//From last stage's BF, Addition part goes to RAM2, should * W(k2*1),(DC)
			begin
				RAM2_r[k2] <= Cr1;	
				RAM2_i[k2] <= Ci1;		
			end
			"11":		//From last stage' RAM, should * W(k2*3),(DD)
			begin
				RAM2_r[k2] <= RAM1_r[k2];		
				RAM2_i[k2] <= RAM1_i[k2];
			end
			endcase
			k2 <= k2+1;
			if(k2 == 31)
			begin	
				stage2_compute <= 1;	//Enable this stage's BF
				l2 <= 0;
				stage3_ready <= 1;		//Enable next stage's RAM
				k3 <= 0;
				f2 <= f2 + 1;			//Change its source
			end
		end
		else if (k2 < 64)			
		begin
			RAM2_r[k2-32] <= Dr2;		//From this stage's BF,
			RAM2_i[k2-32] <= Di2;
			k1 <= k1+1;
			if(k2 == 63)
			begin
				stage2_compute <= 0;	//Disable this stage's BF, repeat
				k2 <= 0;
			end
		end
	end
end

always @(negedge CLK)		//STAGE 2 Compute
begin
	if(stage2_compute)
	begin
		if(l2 < 32)
		begin
			Ar2 <= RAM2_r[l2];		//From this stage's RAM anterior data
			Ai2 <= RAM2_i[l2];
			case(f2)
			"00":					//From last stage's BF, * W((l2+32)*0) (CC)
			begin
				Br2 <= Cr1;				
				Bi2 <= Ci1;
			end
			"01":					//From last stage's RAM, * W((l2+32)*2) (CD)
			begin
				Br2 <= RAM1_r[l2+32];				
				Bi2 <= RAM1_i[l2+32];
			end
			"10":					//From last stage's BF, * W((l2+32)*1) (DC)
			begin
				Br2 <= Cr1;				
				Bi2 <= Ci1;
			end
			"11":					//From last stage's RAM, * W((l2+32)*3) (DD)
			begin
				Br2 <= RAM1_r[l2+32];				
				Bi2 <= RAM1_i[l2+32];
			end
			l2 <= l2+1;
		end
	end
end

BF3 BF(.ar(Ar3),.ai(Ai3),.br(Br3),.bi(Bi3),.cr(Cr3),.ci(Ci3),.dr(Dr3),.di(Di3))

always @(posedge CLK)		//STAGE 3 STORE
begin
	if(stage3_ready)		
	begin
		if(k3 < 16)		
		begin
			if(f3)					
			begin
				RAM3_r[k3] <= Cr2;	 
				RAM3_i[k3] <= Ci2;		
			end
			else					
			begin					//Subtraction part goes from last stage
				RAM3_r[k3] <= RAM2_r[k3];		
				RAM3_i[k3] <= RAM2_i[k3];
			end
			k3 <= k3+1;
			if(k3 == 15)
			begin	
				stage3_compute <= 1;	//Enable this stage's BF
				l3 <= 0;
				stage4_ready <= 1;		//Enable next stage's RAM
				k3 <= 0;
				f3 <= f3 + 1;			//Change its source
			end
		end
		else if (k3 < 32)			
		begin
			RAM3_r[k3-64] <= Dr3;		//From this stage's BF
			RAM3_i[k3-64] <= Di3;
			k3 <= k3+1;
			if(k3 == 127)
			begin
				stage3_compute <= 0;	//Disable this stage's BF, repeat
				k3 <= 0;
			end
		end
	end
end

always @(negedge CLK)		//STAGE 3 Compute
begin
	if(stage3_compute)
	begin
		if(l3 < 64)
		begin
			Ar3 <= RAM2_r[l3];		//From this stage's RAM anterior data
			Ai3 <= RAM2_i[l3];
			if(f1)					//From last stage's BF
			begin
				Br3 <= Cr2;				
				Bi3 <= Ci2;
			end
			else					//From last stage's RAM, should * (-j) (D)
			begin
				Br3 <= RAM2_r[l3+64];					
				Bi3 <= RAM2_i[l3+64];
			end
			l3 <= l3+1;
		end
	end
end
