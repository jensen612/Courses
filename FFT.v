module fft_256(Data_in_r, Data_in_i, RST, CLK, Data_out_r, Data_out_in);

// ========== change
input [15:0] Data_in_r;
input [15:0] Data_in_i;
input RST;
input CLK;

output [15:0] Data_out_r;
output [15:0] Data_out_i;  // ========== d -> D

reg [15:0] RAM0_r [127:0];
reg [15:0] RAM0_i [127:0];  // 128*16 bit
reg [15:0] RAM1_r [63:0];
reg [15:0] RAM1_i [63:0];   // 64*16 bit
reg [15:0] RAM2_r [31:0];
reg [15:0] RAM2_i [31:0];   // 32*16 bit
reg [15:0] RAM3_r [15:0];   
reg [15:0] RAM3_i [15:0];   // 16*16 bit
 reg [15:0] RAM4_r [7:0];
reg [15:0] RAM4_i [7:0];    // 8*16 bit
reg [15:0] RAM5_r [3:0];
reg [15:0] RAM5_i [3:0];    // 4*16 bit
reg [15:0] RAM6_r [1:0];   
reg [15:0] RAM6_i [1:0];    // 2*16 bit
reg [15:0] RAM7_r;
reg [15:0] RAM7_i;          // 1*16 bit
// ========== change

reg [7:0] RAM_out[15:0];
reg [7:0] k0, 
reg f1, f3, f5, f7;
reg [1:0] f2, f4, f6;
reg input_en, stage0_compute;
	stage1_ready, stage1_compute,
	stage2_ready, stage2_compute;

// ***** reset
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

// ***** stage 0
BF0 BF(.ar(Ar0),.ai(Ai0),.br(Br0),.bi(Bi0),.cr(Cr0),.ci(Ci0),.dr(Dr0),.di(Di0)) //Two inputs. Two outputs. C:Addition; D:Substraction
TF0 TJ(.tr(Tr0),.ti(Ti0),.sel(Sel0),.sr(Sr0),.si(Si0))		//only needs to implement * (-j)

always @(posedge CLK or posedge RST)		//STAGE 0 Store: starts at 0, loop of 256; Space: 128
begin
	if(RST)
	begin
		bf_0_en   <= 0;			//Disable this stage's BF (stage 0)			
		tf_0_en   <= 0;			//Disable this stage's Twiddle Factor Module
		input_0_flag <= 1;		//Initial mode: input from Data_in
		RAM0_addr <= 0;			//Address Reset	
	end
	else if(input_en)
	begin
		if(input_0_flag == 1)		// Input data go into RAM 0  // if (input_0_flag == 1) input from Data_in  // if (input_0_flag == 0) input from BF0
		begin
			RAM0_r[RAM0_addr] <= Data_in_r;  
			RAM0_i[RAM0_addr] <= Data_in_i;   
			RAM0_addr <= RAM0_addr+1;
			if(RAM0_addr == 127)
			begin	
				bf_0_en   <= 1;		//Enable this stage's BF (stage 0)			
				tf_0_en   <= 1;		//Enable this stage's Twiddle Factor Module
				input_0_flag <= 0;
				RAM0_addr <= 0;
			end
		end
		else //input_0_flag == 0
		begin
			RAM0_r[RAM0_addr] <= Dr0;		//Subtraction part goes back io RAM0,(0-128), (1-129)...(63-191)
			RAM0_i[RAM0_addr] <= Di0;		
			RAM0_addr <= RAM0_addr+1;
			if(RAM0_addr == 127)
			begin
				bf_0_en <= 0;	//Disable this stage's BF
				RAM0_addr <= 0;
				input_0_flag <= 1;
			end
		end
	end
end

always @(negedge CLK or posedge RST)		//STAGE 0 Butterfly: starts at 128, closes at 256; repeat
begin
    if(RST) 
    begin
        bf_0_addr <= 0;   //Address signal for BF reset
    end
    else if(bf_0_en)
	begin
		Ar0 <= RAM0_r[bf_0_addr];		//From RAM anterior data: 0, 1, 2, ..., 127
		Ai0 <= RAM0_i[bf_0_addr];
		Br0 <= Data_in_r;		//From input: 128, 129, ..., 255
		Bi0 <= Data_in_i;
		bf_0_addr <= bf_0_addr+1;
		if(bf_0_addr == 127)
		begin
			bf_0_addr <= 0;
		end
	end
end

always @(posedge CLK or posedge RST)		//STAGE 0 Twiddle Factor: starts at 128, loop of 256
begin
	if(RST)
	begin
		tf_0_addr <= 0;			//Address rest
		stage1_input_en <= 0;	//Disable input into stage1
	end
	if(tf_0_en)					//Open the stage 0's tf module
	begin
		stage1_input_en <= 1;	//Open the stage 1's RAM after data enters into tf module
		if(bf_0_en)
		begin
			Tr0 <= Cr0;		//Addition part goes to tf module: (0+128),(1+129),...(127+255)
			Ti0 <= Ci0;
			Sel0 <= 0; 	
			tf_0_addr <= tf_0_addr + 1;
			if(tf_0_addr == 127)
			begin
				tf_0_addr <= 0;
			end
		end
		else	//bf_0_en == 0, receiving data from RAM0
		begin
			Tr0 <= RAM0_r[tf_0_addr];
			Ti0 <= RAM0_i[tf_0_addr];
			tf_0_addr <= tf_0_addr + 1;
			if(tf_0_addr < 64)
			begin
				Sel0 <= 0;
			end
			else			//Last one quarter of the data, needs to * (-j)
			begin
				Sel0 <= 1;
			end
			if(tf_0_addr == 127)
			begin
				tf_0_addr <= 0;
			end
		end
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
