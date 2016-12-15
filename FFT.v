module fft_256(Data_in_r, Data_in_i, RST, CLK, Data_out_r, Data_out_in);

// ========== change
input [15:0] Data_in_r;
input [15:0] Data_in_i;
input RST;
input CLK;

output [15:0] Data_out_r;
output [15:0] Data_out_i;  // ========== d -> D

reg [31:0] RAM0_r [127:0];
reg [31:0] RAM0_i [127:0];  // 128*16 bit
reg [31:0] RAM1_r [63:0];
reg [31:0] RAM1_i [63:0];   // 64*16 bit
reg [31:0] RAM2_r [31:0];
reg [31:0] RAM2_i [31:0];   // 32*16 bit
reg [31:0] RAM3_r [15:0];   
reg [31:0] RAM3_i [15:0];   // 16*16 bit
reg [31:0] RAM4_r [7:0];
reg [31:0] RAM4_i [7:0];    // 8*16 bit
reg [31:0] RAM5_r [3:0];
reg [31:0] RAM5_i [3:0];    // 4*16 bit
reg [31:0] RAM6_r [1:0];   
reg [31:0] RAM6_i [1:0];    // 2*16 bit
reg [31:0] RAM7_r;
reg [31:0] RAM7_i;          // 1*16 bit
// ========== change


// ***** reset
always @(posedge CLK)
begin
	if(RST)
	begin
		
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
			RAM0_r[RAM0_addr] <= {9{Data_in_r[15]},Data_in_r[14:0],8{1'b0}};  
			RAM0_i[RAM0_addr] <= {9{Data_in_i[15]},Data_in_i[14:0],8{1'b0}};  //Directly do signed extension 
			RAM0_addr <= RAM0_addr+1;
			if(RAM0_addr == 127)
			begin	
				bf_0_en   <= 1;		//Enable this stage's BF (stage 0)			
				tf_0_en   <= 1;		//Enable this stage's Twiddle Factor Module
				input_0_flag <= 0;
				RAM0_addr <= 0;
			end
		end
		else //input_0_flag == 0, fetch from butterfly
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
		Br0 <= {9{Data_in_r[15]},Data_in_r[14:0],8{1'b0}};		//From input: 128, 129, ..., 255
		Bi0 <= {9{Data_in_i[15]},Data_in_i[14:0],8{1'b0}};		//Directly do signed extension
		bf_0_addr <= bf_0_addr+1;
		if(bf_0_addr == 127)
		begin
			bf_0_addr <= 0;
		end
	end
end

always @(posedge CLK or posedge RST)		//STAGE 0 Twiddle Factor: starts at 128, loop of 128
begin
	if(RST)
	begin
		tf_0_addr <= 0;			//Address rest
		stage1_input_en <= 0;	//Disable input into stage1
	end
	else if(tf_0_en)					//Open the stage 0's tf module
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

//*****stage 1
BF1 BF(.ar(Ar1),.ai(Ai1),.br(Br1),.bi(Bi1),.cr(Cr1),.ci(Ci1),.dr(Dr1),.di(Di1))
TF1 TF(.tr(Tr1),.ti(Ti1),.wr(Wr1),.wi(Wi1),.sr(Sr1),.si(Si1))	//input the twiddle factor

always @(posedge CLK or posedge RST)	//STAGE 1 STORE: starts at 129, loop of 64; Space: 64
begin
	if(RST)
	begin
		bf_1_en   <= 0;			//Disable stage 1's BF (stage 1)			
		tf_1_en   <= 0;			//Disable stage 1's Twiddle Factor Module
		input_1_flag <= 1;		//Initial mode: input from Sr0, Si0
		RAM1_addr <= 0;			//Address Reset	
	end
	else if(stage1_input_en)		
	begin
		if(input_1_flag)							
		begin
			RAM1_r[RAM1_addr] <= Sr0;		//Fetch from the last stage's buffer
			RAM1_i[RAM1_addr] <= Si0;		
			RAM1_addr <= RAM1_addr+1;
			if(RAM1_addr == 63)
			begin	
				bf_1_en   <= 1;		//Enable stage 1's BF (stage 0)			
				tf_1_en   <= 1;		//Enable stage 1's Twiddle Factor Module
				input_1_flag <= 0;
				RAM1_addr <= 0;
			end
		end
		else	//input_1_flag == 0, fetch from butterfly		
		begin
			RAM1_r[RAM1_addr] <= Dr1;		//From this stage's BF		
			RAM1_i[RAM1_addr] <= Di1;
			RAM1_addr <= RAM1_addr+1;
			if(RAM1_addr == 63)
			begin
				bf_1_en <= 0;		//Disable stage 1's BF, repeat
				RAM1_addr <= 0;
				input_0_flag <= 1;
			end
		end
	end
end

always @(negedge CLK or posedge RST)	
begin
    if(RST) 
    begin
        bf_1_addr <= 0;   //Address signal for BF reset
    end
    else if(bf_1_en)
	begin
		Ar1 <= RAM1_r[bf_1_addr];		//From RAM anterior data: 0, 1, 2, ..., 127
		Ai1 <= RAM1_i[bf_1_addr];
		Br1 <= Sr0;						//From tf0's output
		Bi1 <= Si0;
		bf_1_addr <= bf_1_addr+1;
		if(bf_1_addr == 63)
		begin
			bf_1_addr <= 0;
		end
	end
end

always @(posedge CLK or posedge RST)		//STAGE 1 Twiddle Factor
begin
	if(RST)
	begin
		tf_1_addr <= 0;			//Address reset
		stage2_input_en <= 0;	//Disable input into stage2
		tf_1_flag <= 0;			//control tf 
	end
	else if(tf_1_en)			//Open the stage 1's tf module
	begin
		stage2_input_en <= 1;	//Open the stage 2's RAM after data enters into tf module
		if(bf_1_en)
		begin
			Tr1 <= Cr1;		//Addition part goes to tf module: (0+128),(1+129),...(127+255)
			Ti1 <= Ci1;
			tf_1_addr <= tf_1_addr + 1;
			if(tf_1_flag == 0)	//CC, * W(0,0,0...)
			begin
				Wr1 <= 1;
				Wi1 <= 0;
			end
			else				//DC,* W(0,1,2,3,...,63)			
			begin
				Wr1 <= tf_ROM1_r[tf_1_addr];		
				Wi1 <= tf_ROM1_i[tf_1_addr];
			end
			if(tf_1_addr == 63)
			begin
				tf_1_addr <= 0;
			end
		end
		else	//bf_1_en == 0, receiving data from RAM1
		begin
			Tr1 <= RAM1_r[tf_1_addr];
			Ti1 <= RAM1_i[tf_1_addr];
			tf_1_addr <= tf_1_addr + 1;
			if(tf_1_flag == 0)	//CD,* W(0,2,4,...,126)
			begin
				Wr1 <= tf_ROM1_r[tf_1_addr*2];		
				Wi1 <= tf_ROM1_i[tf_1_addr*2];
			end
			else				//DD,* W(0,3,6,...,189)
			begin
				Wr1 <= tf_ROM1_r[tf_1_addr*3];		
				Wi1 <= tf_ROM1_i[tf_1_addr*3];
			end
			if(tf_1_addr == 63)
			begin
				tf_1_flag <= tf_1_flag+1;	//Switch flag after cycle of 128 	
				tf_1_addr <= 0;
			end
		end
	end
end

// ***** stage 2
BF2 BF(.ar(Ar2),.ai(Ai2),.br(Br2),.bi(Bi2),.cr(Cr2),.ci(Ci2),.dr(Dr2),.di(Di2)) //Two inputs. Two outputs. C:Addition; D:Substraction
TF2 TJ(.tr(Tr2),.ti(Ti2),.sel(Sel2),.sr(Sr2),.si(Si2))		//only needs to implement * (-j)

always @(posedge CLK or posedge RST)		//STAGE 2 Store: loop of 32
begin
	if(RST)
	begin
		bf_2_en   <= 0;			//Disable this stage's BF (stage 2)			
		tf_2_en   <= 0;			//Disable this stage's Twiddle Factor Module
		input_2_flag <= 1;		//Initial mode: input from Data_in
		RAM2_addr <= 0;			//Address Reset	
	end
	else if(input_en)
	begin
		if(input_2_flag == 1)		// Input data go into RAM 2   
		begin
			RAM2_r[RAM2_addr] <= Sr1;  
			RAM2_i[RAM2_addr] <= Si1;  //Directly do signed extension 
			RAM2_addr <= RAM2_addr+1;
			if(RAM2_addr == 31)
			begin	
				bf_2_en   <= 1;		//Enable this stage's BF (stage 2)			
				tf_2_en   <= 1;		//Enable this stage's Twiddle Factor Module
				input_2_flag <= 0;
				RAM2_addr <= 0;
			end
		end
		else //input_2_flag == 0, fetch from butterfly
		begin
			RAM2_r[RAM2_addr] <= Dr2;		//Subtraction part goes back io RAM2
			RAM2_i[RAM2_addr] <= Di2;		
			RAM2_addr <= RAM2_addr+1;
			if(RAM2_addr == 31)
			begin
				bf_2_en <= 0;	//Disable this stage's BF
				RAM2_addr <= 0;
				input_2_flag <= 1;
			end
		end
	end
end

	always @(negedge CLK or posedge RST)		//STAGE 2 Butterfly: loop of 32
begin
    if(RST) 
    begin
        bf_2_addr <= 0;   //Address signal for BF reset
    end
    else if(bf_2_en)
	begin
		Ar2 <= RAM2_r[bf_2_addr];	//From RAM anterior data: 
		Ai2 <= RAM2_i[bf_2_addr];
		Br2 <= Sr1;		//From input: 128, 129, ..., 255
		Bi2 <= Si1;		//Directly do signed extension
		bf_2_addr <= bf_2_addr+1;
		if(bf_2_addr == 31)
		begin
			bf_2_addr <= 0;
		end
	end
end

	always @(posedge CLK or posedge RST)		//STAGE 2 Twiddle Factor: loop of 32
begin
	if(RST)
	begin
		tf_2_addr <= 0;			//Address rest
		stage3_input_en <= 0;	//Disable input into stage3
	end
	else if(tf_2_en)					//Open the stage 2's tf module
	begin
		stage3_input_en <= 1;	//Open the stage 1's RAM after data enters into tf module
		if(bf_2_en)
		begin
			Tr2 <= Cr2;		//Addition part goes to tf module
			Ti2 <= Ci2;
			Sel2 <= 0; 	
			tf_2_addr <= tf_2_addr + 1;
			if(tf_2_addr == 31)
			begin
				tf_2_addr <= 0;
			end
		end
		else	//bf_2_en == 0, receiving data from RAM2
		begin
			Tr2 <= RAM2_r[tf_2_addr];
			Ti2 <= RAM2_i[tf_2_addr];
			tf_2_addr <= tf_2_addr + 1;
			if(tf_2_addr < 16)
			begin
				Sel2 <= 0;
			end
			else			//Last one quarter of the data, needs to * (-j)
			begin
				Sel2 <= 1;
			end
			if(tf_2_addr == 31)
			begin
				tf_2_addr <= 0;
			end
		end
	end
end

//*****stage 3
BF3 BF(.ar(Ar3),.ai(Ai3),.br(Br3),.bi(Bi3),.cr(Cr3),.ci(Ci3),.dr(Dr3),.di(Di3))
TF3 TF(.tr(Tr3),.ti(Ti3),.wr(Wr3),.wi(Wi3),.sr(Sr3),.si(Si3))	//input the twiddle factor

always @(posedge CLK or posedge RST)	//STAGE 3 STORE: loop of 16
begin
	if(RST)
	begin
		bf_3_en   <= 0;			//Disable stage 3's BF (stage 3)			
		tf_3_en   <= 0;			//Disable stage 3's Twiddle Factor Module
		input_3_flag <= 1;		//Initial mode: input from Sr0, Si0
		RAM3_addr <= 0;			//Address Reset	
	end
	else if(stage3_input_en)		
	begin
		if(input_3_flag)							
		begin
			RAM3_r[RAM3_addr] <= Sr2;		//Fetch from the last stage's buffer
			RAM3_i[RAM3_addr] <= Si2;		
			RAM3_addr <= RAM3_addr+1;
			if(RAM3_addr == 15)
			begin	
				bf_3_en   <= 1;		//Enable stage 3's BF (stage 0)			
				tf_3_en   <= 1;		//Enable stage 3's Twiddle Factor Module
				input_3_flag <= 0;
				RAM3_addr <= 0;
			end
		end
		else	//input_3_flag == 0, fetch from butterfly		
		begin
			RAM3_r[RAM3_addr] <= Dr3;		//From this stage's BF		
			RAM3_i[RAM3_addr] <= Di3;
			RAM3_addr <= RAM3_addr+1;
			if(RAM3_addr == 15)
			begin
				bf_3_en <= 0;		//Disable stage 3's BF, repeat
				RAM3_addr <= 0;
				input_0_flag <= 1;
			end
		end
	end
end

	always @(negedge CLK or posedge RST)			//STAGE 3 Butterfly: loop of 16
begin
    if(RST) 
    begin
        bf_3_addr <= 0;   //Address signal for BF reset
    end
    else if(bf_3_en)
	begin
		Ar3 <= RAM3_r[bf_3_addr];		//From RAM anterior data
		Ai3 <= RAM3_i[bf_3_addr];
		Br3 <= Sr2;				//From tf2's output
		Bi3 <= Si2;
		bf_3_addr <= bf_3_addr+1;
		if(bf_3_addr == 15)
		begin
			bf_3_addr <= 0;
		end
	end
end

	always @(posedge CLK or posedge RST)		//STAGE 3 Twiddle Factor: loop of 16
begin
	if(RST)
	begin
		tf_3_addr <= 0;			//Address reset
		stage3_input_en <= 0;	//Disable input into stage2
		tf_3_flag <= 0;			//control tf 
	end
	else if(tf_3_en)			//Open the stage 3's tf module
	begin
		stage4_input_en <= 1;	//Open the stage 4's RAM after data enters into tf module
		if(bf_3_en)
		begin
			Tr3 <= Cr3;		//Addition part goes to tf module
			Ti3 <= Ci3;
			tf_3_addr <= tf_3_addr + 1;
			if(tf_3_flag == 0)	//CC, * W(0,0,0...)
			begin
				Wr3 <= 1;
				Wi3 <= 0;
			end
			else				//DC,* W(0,1,2,3,...,15)			
			begin
				Wr3 <= tf_ROM3_r[tf_3_addr];		
				Wi3 <= tf_ROM3_i[tf_3_addr];
			end
			if(tf_3_addr == 15)
			begin
				tf_3_addr <= 0;
			end
		end
		else	//bf_3_en == 0, receiving data from RAM3
		begin
			Tr3 <= RAM3_r[tf_3_addr];
			Ti3 <= RAM3_i[tf_3_addr];
			tf_3_addr <= tf_3_addr + 1;
			if(tf_3_flag == 0)	//CD,* W(0,2,4,...,30)
			begin
				Wr3 <= tf_ROM3_r[tf_3_addr*2];		
				Wi3 <= tf_ROM3_i[tf_3_addr*2];
			end
			else				//DD,* W(0,3,6,...,45)
			begin
				Wr3 <= tf_ROM3_r[tf_3_addr*3];		
				Wi3 <= tf_ROM3_i[tf_3_addr*3];
			end
			if(tf_3_addr == 15)
			begin
				tf_3_flag <= tf_3_flag+1;	//Switch flag after cycle of 32 	
				tf_3_addr <= 0;
			end
		end
	end
end
	
//repeat....
	
// ***** stage 4
BF4 BF(.ar(Ar4),.ai(Ai4),.br(Br4),.bi(Bi4),.cr(Cr4),.ci(Ci4),.dr(Dr4),.di(Di4)) //Two inputs. Two outputs. C:Addition; D:Substraction
TF4 TJ(.tr(Tr4),.ti(Ti4),.sel(Sel4),.sr(Sr4),.si(Si4))		//only needs to implement * (-j)

always @(posedge CLK or posedge RST)		//STAGE 4 Store: loop of 8
begin
	if(RST)
	begin
		bf_4_en   <= 0;			//Disable this stage's BF (stage 4)			
		tf_4_en   <= 0;			//Disable this stage's Twiddle Factor Module
		input_4_flag <= 1;		//Initial mode: input from Data_in
		RAM4_addr <= 0;			//Address Reset	
	end
	else if(input_en)
	begin
		if(input_4_flag == 1)		// Input data go into RAM 4   
		begin
			RAM4_r[RAM4_addr] <= Sr3;  
			RAM4_i[RAM4_addr] <= Si3;  
			RAM4_addr <= RAM4_addr+1;
			if(RAM4_addr == 7)
			begin	
				bf_4_en   <= 1;		//Enable this stage's BF (stage 4)			
				tf_4_en   <= 1;		//Enable this stage's Twiddle Factor Module
				input_4_flag <= 0;
				RAM4_addr <= 0;
			end
		end
		else //input_4_flag == 0, fetch from butterfly
		begin
			RAM4_r[RAM4_addr] <= Dr4;		//Subtraction part goes back io RAM4
			RAM4_i[RAM4_addr] <= Di4;		
			RAM4_addr <= RAM4_addr+1;
			if(RAM4_addr == 7)
			begin
				bf_4_en <= 0;	//Disable this stage's BF
				RAM4_addr <= 0;
				input_4_flag <= 1;
			end
		end
	end
end

always @(negedge CLK or posedge RST)		//STAGE 4 Butterfly: loop of 8
begin
    if(RST) 
    begin
        bf_4_addr <= 0;   //Address signal for BF reset
    end
    else if(bf_4_en)
	begin
		Ar4 <= RAM0_r[bf_4_addr];	//From RAM anterior data: 
		Ai4 <= RAM0_i[bf_4_addr];
		Br4 <= Sr3;		
		Bi4 <= Si3;			//From stage 3 buffer
		bf_4_addr <= bf_4_addr+1;
		if(bf_4_addr == 7)
		begin
			bf_4_addr <= 0;
		end
	end
end

	always @(posedge CLK or posedge RST)		//STAGE 4 Twiddle Factor: loop of 8
begin
	if(RST)
	begin
		tf_4_addr <= 0;			//Address rest
		stage5_input_en <= 0;	//Disable input into stage3
	end
	else if(tf_4_en)					//Open the stage 4's tf module
	begin
		stage5_input_en <= 1;	//Open the stage 1's RAM after data enters into tf module
		if(bf_4_en)
		begin
			Tr4 <= Cr4;		//Addition part goes to tf module
			Ti4 <= Ci4;
			Sel4 <= 0; 	
			tf_4_addr <= tf_4_addr + 1;
			if(tf_4_addr == 7)
			begin
				tf_4_addr <= 0;
			end
		end
		else	//bf_4_en == 0, receiving data from RAM4
		begin
			Tr4 <= RAM4_r[tf_4_addr];
			Ti4 <= RAM4_i[tf_4_addr];
			tf_4_addr <= tf_4_addr + 1;
			if(tf_4_addr < 4)
			begin
				Sel4 <= 0;
			end
			else			//Last one quarter of the data, needs to * (-j)
			begin
				Sel4 <= 1;
			end
			if(tf_4_addr == 7)
			begin
				tf_4_addr <= 0;
			end
		end
	end
end

//*****stage 5
BF5 BF(.ar(Ar5),.ai(Ai5),.br(Br5),.bi(Bi5),.cr(Cr5),.ci(Ci5),.dr(Dr5),.di(Di5))
TF5 TF(.tr(Tr5),.ti(Ti5),.wr(Wr5),.wi(Wi5),.sr(Sr5),.si(Si5))	//input the twiddle factor

always @(posedge CLK or posedge RST)	//STAGE 5 STORE: loop of 4
begin
	if(RST)
	begin
		bf_5_en   <= 0;			//Disable stage 5's BF (stage 5)			
		tf_5_en   <= 0;			//Disable stage 5's Twiddle Factor Module
		input_5_flag <= 1;		//Initial mode: input from Sr0, Si0
		RAM5_addr <= 0;			//Address Reset	
	end
	else if(stage5_input_en)		
	begin
		if(input_5_flag)							
		begin
			RAM5_r[RAM5_addr] <= Sr4;		//Fetch from the last stage's buffer
			RAM5_i[RAM5_addr] <= Si4;		
			RAM5_addr <= RAM5_addr+1;
			if(RAM5_addr == 3)
			begin	
				bf_5_en   <= 1;		//Enable stage 5's BF (stage 0)			
				tf_5_en   <= 1;		//Enable stage 5's Twiddle Factor Module
				input_5_flag <= 0;
				RAM5_addr <= 0;
			end
		end
		else	//input_5_flag == 0, fetch from butterfly		
		begin
			RAM5_r[RAM5_addr] <= Dr5;		//From this stage's BF		
			RAM5_i[RAM5_addr] <= Di5;
			RAM5_addr <= RAM5_addr+1;
			if(RAM5_addr == 3)
			begin
				bf_5_en <= 0;		//Disable stage 5's BF, repeat
				RAM5_addr <= 0;
				input_0_flag <= 1;
			end
		end
	end
end

always @(negedge CLK or posedge RST)			//STAGE 5 Butterfly: loop of 4
begin
    if(RST) 
    begin
        bf_5_addr <= 0;   //Address signal for BF reset
    end
    else if(bf_5_en)
	begin
		Ar5 <= RAM5_r[bf_5_addr];		//From RAM anterior data
		Ai5 <= RAM5_i[bf_5_addr];
		Br5 <= Sr4;				//From tf4's output
		Bi5 <= Si4;
		bf_5_addr <= bf_5_addr+1;
		if(bf_5_addr == 3)
		begin
			bf_5_addr <= 0;
		end
	end
end

	always @(posedge CLK or posedge RST)		//STAGE 5 Twiddle Factor: loop of 4
begin
	if(RST)
	begin
		tf_5_addr <= 0;			//Address reset
		stage5_input_en <= 0;	//Disable input into stage2
		tf_5_flag <= 0;			//control tf 
	end
	else if(tf_5_en)			//Open the stage 5's tf module
	begin
		stageF_input_en <= 1;	//Open the stage 4's RAM after data enters into tf module
		if(bf_5_en)
		begin
			Tr5 <= Cr5;		//Addition part goes to tf module
			Ti5 <= Ci5;
			tf_5_addr <= tf_5_addr + 1;
			if(tf_5_flag == 0)	//CC, * W(0,0,0...)
			begin
				Wr5 <= 1;
				Wi5 <= 0;
			end
			else				//DC,* W(0,1,2,3,...,15)			
			begin
				Wr5 <= tf_ROM5_r[tf_5_addr];		
				Wi5 <= tf_ROM5_i[tf_5_addr];
			end
			if(tf_5_addr == 3)
			begin
				tf_5_addr <= 0;
			end
		end
		else	//bf_5_en == 0, receiving data from RAM5
		begin
			Tr5 <= RAM5_r[tf_5_addr];
			Ti5 <= RAM5_i[tf_5_addr];
			tf_5_addr <= tf_5_addr + 1;
			if(tf_5_flag == 0)	//CD,* W(0,2,4,...,30)
			begin
				Wr5 <= tf_ROM5_r[tf_5_addr*2];		
				Wi5 <= tf_ROM5_i[tf_5_addr*2];
			end
			else				//DD,* W(0,3,6,...,45)
			begin
				Wr5 <= tf_ROM5_r[tf_5_addr*3];		
				Wi5 <= tf_ROM5_i[tf_5_addr*3];
			end
			if(tf_5_addr == 3)
			begin
				tf_5_flag <= tf_5_flag+1;	//Switch flag after cycle of 8 	
				tf_5_addr <= 0;
			end
		end
	end
end	
	
endmodule
