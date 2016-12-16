	
module BF(ar, ai, br, bi, cr, ci, dr, di);
input  [31:0] ar;
input  [31:0] ai;
input  [31:0] br;
input  [31:0] bi;
output [31:0] cr;
output [31:0] ci;
output [31:0] dr;
output [31:0] di;

assign cr = ar + br;
assign ci = ai + bi;
assign dr = ar - br;
assign di = ai - bi;
endmodule

module TJ(tr, ti, sel, sr, si);		//only needs to implement * (-j)
    // input output
input [31:0] tr;
input [31:0] ti;
input sel;

output [31:0] sr;
output [31:0] si;

    // calculation
wire [63:0] aug_minus_tr = $signed(32'hFFFF_FFFF) * $signed(tr);
wire [31:0] minus_tr = {aug_minus_tr[63], aug_minus_tr[46:16]};

assign sr = sel ?       ti : tr;
assign si = sel ? minus_tr : ti;
	    
endmodule

module TF(tr, ti, wr, wi, sr, si);
    // input output
input [31:0] tr;
input [31:0] ti;
input [31:0] wr;
input [31:0] wi;

output [31:0] sr;
output [31:0] si;

    // calculation
wire [63:0] aug_sr = $signed(tr) * $signed(wr) - $signed(ti) * $signed(wi);
wire [63:0] aug_si = $signed(tr) * $signed(wi) + $signed(ti) * $signed(wr);

assign sr = {aug_sr[63], aug_sr[46:16]};
assign si = {aug_si[63], aug_si[46:16]};
endmodule

module fft_256(Data_in_r, Data_in_i, RST, CLK, Data_out_r, Data_out_i, out_ready);

// ========== change
input [15:0] Data_in_r;
input [15:0] Data_in_i;
input RST;
input CLK;

output [15:0] Data_out_r;
output [15:0] Data_out_i;  // ========== d -> D
output out_ready;

integer m;
//stage 0
reg input_en;
reg [31:0] RAM0_r [127:0];
reg [31:0] RAM0_i [127:0];  // 128*32 bit
reg [6:0] RAM0_addr;
reg [6:0] bf_0_addr;
reg [6:0] tf_0_addr;
reg [31:0] Ar0;
reg [31:0] Ai0;
reg [31:0] Br0;
reg [31:0] Bi0; 
wire [31:0] Cr0;
wire [31:0] Ci0;
wire [31:0] Dr0; 
wire [31:0] Di0;
reg [31:0] Tr0;
reg [31:0] Ti0;
reg Sel0;
wire [31:0] Sr0; 
wire [31:0] Si0;
reg bf_0_en;
reg tf_0_en;
reg input_0_flag;
//stage 1
reg stage1_input_en;
reg [31:0] RAM1_r [63:0];
reg [31:0] RAM1_i [63:0];   // 64*32 bit
reg [5:0] RAM1_addr;
reg [5:0] bf_1_addr;
reg [5:0] tf_1_addr;
reg [31:0] Ar1;
reg [31:0] Ai1;
reg [31:0] Br1;
reg [31:0] Bi1; 
wire [31:0] Cr1;
wire [31:0] Ci1;
wire [31:0] Dr1; 
wire [31:0] Di1;
reg [31:0] Tr1;
reg [31:0] Ti1;
reg [31:0] Wr1;
reg [31:0] Wi1;
wire [31:0] Sr1; 
wire [31:0] Si1;	
reg bf_1_en;
reg tf_1_en;
reg tf_1_flag;
reg input_1_flag;	
//stage 2	
reg stage2_input_en;
reg [31:0] RAM2_r [31:0];
reg [31:0] RAM2_i [31:0];   // 32*32 bit
reg [4:0] RAM2_addr;
reg [4:0] bf_2_addr;
reg [4:0] tf_2_addr;
reg [31:0] Ar2;
reg [31:0] Ai2;
reg [31:0] Br2;
reg [31:0] Bi2; 
wire [31:0] Cr2;
wire [31:0] Ci2;
wire [31:0] Dr2; 
wire [31:0] Di2;
reg [31:0] Tr2;
reg [31:0] Ti2;
reg Sel2;
wire [31:0] Sr2; 
wire [31:0] Si2;
reg bf_2_en;
reg tf_2_en;
reg input_2_flag;
//stage 3
reg stage3_input_en;
reg [31:0] RAM3_r [15:0];   
reg [31:0] RAM3_i [15:0];   // 16*32 bit
reg [3:0] RAM3_addr;
reg [3:0] bf_3_addr;
reg [3:0] tf_3_addr;
reg [31:0] Ar3;
reg [31:0] Ai3;
reg [31:0] Br3;
reg [31:0] Bi3; 
wire [31:0] Cr3;
wire [31:0] Ci3;
wire [31:0] Dr3; 
wire [31:0] Di3;
reg [31:0] Tr3;
reg [31:0] Ti3;
reg [31:0] Wr3;
reg [31:0] Wi3;
wire [31:0] Sr3; 
wire [31:0] Si3;	
reg bf_3_en;
reg tf_3_en;
reg tf_3_flag;
reg input_3_flag;	
//stage 4
reg stage4_input_en;
reg [31:0] RAM4_r [7:0];
reg [31:0] RAM4_i [7:0];    // 8*32 bit
reg [2:0] RAM4_addr;
reg [2:0] bf_4_addr;
reg [2:0] tf_4_addr;
reg [31:0] Ar4;
reg [31:0] Ai4;
reg [31:0] Br4;
reg [31:0] Bi4; 
wire [31:0] Cr4;
wire [31:0] Ci4;
wire [31:0] Dr4; 
wire [31:0] Di4;
reg [31:0] Tr4;
reg [31:0] Ti4;
reg Sel4;
wire [31:0] Sr4; 
wire [31:0] Si4;
reg bf_4_en;
reg tf_4_en;
reg input_4_flag;
//stage 5
reg stage5_input_en;
reg [31:0] RAM5_r [3:0];
reg [31:0] RAM5_i [3:0];    // 4*32 bit
reg [1:0] RAM5_addr;
reg [1:0] bf_5_addr;
reg [1:0] tf_5_addr;
reg [31:0] Ar5;
reg [31:0] Ai5;
reg [31:0] Br5;
reg [31:0] Bi5; 
wire [31:0] Cr5;
wire [31:0] Ci5;
wire [31:0] Dr5; 
wire [31:0] Di5;
reg [31:0] Tr5;
reg [31:0] Ti5;
reg [31:0] Wr5;
reg [31:0] Wi5;
wire [31:0] Sr5; 
wire [31:0] Si5;	
reg bf_5_en;
reg tf_5_en;
reg tf_5_flag;
reg input_5_flag;	
//stage 6
reg stage6_input_en;
reg [31:0] RAM6_r [1:0];   
reg [31:0] RAM6_i [1:0];    // 2*32 bit
reg RAM6_addr;
reg bf_6_addr;
reg tf_6_addr;
reg [31:0] Ar6;
reg [31:0] Ai6;
reg [31:0] Br6;
reg [31:0] Bi6; 
wire [31:0] Cr6;
wire [31:0] Ci6;
wire [31:0] Dr6; 
wire [31:0] Di6;
reg [31:0] Tr6;
reg [31:0] Ti6;
reg Sel6;
wire [31:0] Sr6; 
wire [31:0] Si6;
reg bf_6_en;
reg tf_6_en;
reg input_6_flag;
//stage 7
reg stage7_input_en;
reg [31:0] RAM7_r;
reg [31:0] RAM7_i;          // 1*32 bit
reg [31:0] Ar7;
reg [31:0] Ai7;
reg [31:0] Br7;
reg [31:0] Bi7; 
wire [31:0] Cr7;
wire [31:0] Ci7;
wire [31:0] Dr7; 
wire [31:0] Di7;
reg bf_7_en;
reg tf_7_en;
reg input_7_flag;
//output
reg output_RAM_en;
reg [5:0] output_RAM_addr;
reg [15:0] output_RAM_r [255:0];
reg [15:0] output_RAM_i [255:0];	//256*16 bit
reg [1:0] output_RAM_flag;
reg output_buffer_en;
reg [15:0] output_buffer_r [255:0];
reg [15:0] output_buffer_i [255:0];	//256*16 bit
reg output_en;
reg [7:0] output_ptr;
reg output_ready;
reg [15:0] data_o_r;
reg [15:0] data_o_i;
// ========== change
wire [31:0] tf_ROM_r[189:0];
assign tf_ROM_r[0] = 32'h00010000;
assign tf_ROM_r[1] = 32'h0000FFEC;
assign tf_ROM_r[2] = 32'h0000FFB1;
assign tf_ROM_r[3] = 32'h0000FF4E;
assign tf_ROM_r[4] = 32'h0000FEC4;
assign tf_ROM_r[5] = 32'h0000FE13;
assign tf_ROM_r[6] = 32'h0000FD3A;
assign tf_ROM_r[7] = 32'h0000FC3B;
assign tf_ROM_r[8] = 32'h0000FB14;
assign tf_ROM_r[9] = 32'h0000F9C7;
assign tf_ROM_r[10] = 32'h0000F853;
assign tf_ROM_r[11] = 32'h0000F6BA;
assign tf_ROM_r[12] = 32'h0000F4FA;
assign tf_ROM_r[13] = 32'h0000F314;
assign tf_ROM_r[14] = 32'h0000F109;
assign tf_ROM_r[15] = 32'h0000EED8;
assign tf_ROM_r[16] = 32'h0000EC83;
assign tf_ROM_r[17] = 32'h0000EA09;
assign tf_ROM_r[18] = 32'h0000E76B;
assign tf_ROM_r[19] = 32'h0000E4AA;
assign tf_ROM_r[20] = 32'h0000E1C5;
assign tf_ROM_r[21] = 32'h0000DEBE;
assign tf_ROM_r[22] = 32'h0000DB94;
assign tf_ROM_r[23] = 32'h0000D848;
assign tf_ROM_r[24] = 32'h0000D4DB;
assign tf_ROM_r[25] = 32'h0000D14D;
assign tf_ROM_r[26] = 32'h0000CD9F;
assign tf_ROM_r[27] = 32'h0000C9D1;
assign tf_ROM_r[28] = 32'h0000C5E4;
assign tf_ROM_r[29] = 32'h0000C1D8;
assign tf_ROM_r[30] = 32'h0000BDAE;
assign tf_ROM_r[31] = 32'h0000B968;
assign tf_ROM_r[32] = 32'h0000B504;
assign tf_ROM_r[33] = 32'h0000B085;
assign tf_ROM_r[34] = 32'h0000ABEB;
assign tf_ROM_r[35] = 32'h0000A736;
assign tf_ROM_r[36] = 32'h0000A267;
assign tf_ROM_r[37] = 32'h00009D7F;
assign tf_ROM_r[38] = 32'h0000987F;
assign tf_ROM_r[39] = 32'h00009368;
assign tf_ROM_r[40] = 32'h00008E39;
assign tf_ROM_r[41] = 32'h000088F5;
assign tf_ROM_r[42] = 32'h0000839C;
assign tf_ROM_r[43] = 32'h00007E2E;
assign tf_ROM_r[44] = 32'h000078AD;
assign tf_ROM_r[45] = 32'h00007319;
assign tf_ROM_r[46] = 32'h00006D74;
assign tf_ROM_r[47] = 32'h000067BD;
assign tf_ROM_r[48] = 32'h000061F7;
assign tf_ROM_r[49] = 32'h00005C22;
assign tf_ROM_r[50] = 32'h0000563E;
assign tf_ROM_r[51] = 32'h0000504D;
assign tf_ROM_r[52] = 32'h00004A50;
assign tf_ROM_r[53] = 32'h00004447;
assign tf_ROM_r[54] = 32'h00003E33;
assign tf_ROM_r[55] = 32'h00003817;
assign tf_ROM_r[56] = 32'h000031F1;
assign tf_ROM_r[57] = 32'h00002BC4;
assign tf_ROM_r[58] = 32'h00002590;
assign tf_ROM_r[59] = 32'h00001F56;
assign tf_ROM_r[60] = 32'h00001917;
assign tf_ROM_r[61] = 32'h000012D5;
assign tf_ROM_r[62] = 32'h00000C8F;
assign tf_ROM_r[63] = 32'h00000648;
assign tf_ROM_r[64] = 32'h00000000;
assign tf_ROM_r[65] = 32'hFFFFF9B8;
assign tf_ROM_r[66] = 32'hFFFFF371;
assign tf_ROM_r[67] = 32'hFFFFED2B;
assign tf_ROM_r[68] = 32'hFFFFE6E9;
assign tf_ROM_r[69] = 32'hFFFFE0AA;
assign tf_ROM_r[70] = 32'hFFFFDA70;
assign tf_ROM_r[71] = 32'hFFFFD43C;
assign tf_ROM_r[72] = 32'hFFFFCE0F;
assign tf_ROM_r[73] = 32'hFFFFC7E9;
assign tf_ROM_r[74] = 32'hFFFFC1CD;
assign tf_ROM_r[75] = 32'hFFFFBBB9;
assign tf_ROM_r[76] = 32'hFFFFB5B0;
assign tf_ROM_r[77] = 32'hFFFFAFB3;
assign tf_ROM_r[78] = 32'hFFFFA9C2;
assign tf_ROM_r[79] = 32'hFFFFA3DE;
assign tf_ROM_r[80] = 32'hFFFF9E09;
assign tf_ROM_r[81] = 32'hFFFF9843;
assign tf_ROM_r[82] = 32'hFFFF928C;
assign tf_ROM_r[83] = 32'hFFFF8CE7;
assign tf_ROM_r[84] = 32'hFFFF8753;
assign tf_ROM_r[85] = 32'hFFFF81D2;
assign tf_ROM_r[86] = 32'hFFFF7C64;
assign tf_ROM_r[87] = 32'hFFFF770B;
assign tf_ROM_r[88] = 32'hFFFF71C7;
assign tf_ROM_r[89] = 32'hFFFF6C98;
assign tf_ROM_r[90] = 32'hFFFF6781;
assign tf_ROM_r[91] = 32'hFFFF6281;
assign tf_ROM_r[92] = 32'hFFFF5D99;
assign tf_ROM_r[93] = 32'hFFFF58CA;
assign tf_ROM_r[94] = 32'hFFFF5415;
assign tf_ROM_r[95] = 32'hFFFF4F7B;
assign tf_ROM_r[96] = 32'hFFFF4AFC;
assign tf_ROM_r[97] = 32'hFFFF4698;
assign tf_ROM_r[98] = 32'hFFFF4252;
assign tf_ROM_r[99] = 32'hFFFF3E28;
assign tf_ROM_r[100] = 32'hFFFF3A1C;
assign tf_ROM_r[101] = 32'hFFFF362F;
assign tf_ROM_r[102] = 32'hFFFF3261;
assign tf_ROM_r[103] = 32'hFFFF2EB3;
assign tf_ROM_r[104] = 32'hFFFF2B25;
assign tf_ROM_r[105] = 32'hFFFF27B8;
assign tf_ROM_r[106] = 32'hFFFF246C;
assign tf_ROM_r[107] = 32'hFFFF2142;
assign tf_ROM_r[108] = 32'hFFFF1E3B;
assign tf_ROM_r[109] = 32'hFFFF1B56;
assign tf_ROM_r[110] = 32'hFFFF1895;
assign tf_ROM_r[111] = 32'hFFFF15F7;
assign tf_ROM_r[112] = 32'hFFFF137D;
assign tf_ROM_r[113] = 32'hFFFF1128;
assign tf_ROM_r[114] = 32'hFFFF0EF7;
assign tf_ROM_r[115] = 32'hFFFF0CEC;
assign tf_ROM_r[116] = 32'hFFFF0B06;
assign tf_ROM_r[117] = 32'hFFFF0946;
assign tf_ROM_r[118] = 32'hFFFF07AD;
assign tf_ROM_r[119] = 32'hFFFF0639;
assign tf_ROM_r[120] = 32'hFFFF04EC;
assign tf_ROM_r[121] = 32'hFFFF03C5;
assign tf_ROM_r[122] = 32'hFFFF02C6;
assign tf_ROM_r[123] = 32'hFFFF01ED;
assign tf_ROM_r[124] = 32'hFFFF013C;
assign tf_ROM_r[125] = 32'hFFFF00B2;
assign tf_ROM_r[126] = 32'hFFFF004F;
assign tf_ROM_r[127] = 32'hFFFF0014;
assign tf_ROM_r[128] = 32'hFFFF0000;
assign tf_ROM_r[129] = 32'hFFFF0014;
assign tf_ROM_r[130] = 32'hFFFF004F;
assign tf_ROM_r[131] = 32'hFFFF00B2;
assign tf_ROM_r[132] = 32'hFFFF013C;
assign tf_ROM_r[133] = 32'hFFFF01ED;
assign tf_ROM_r[134] = 32'hFFFF02C6;
assign tf_ROM_r[135] = 32'hFFFF03C5;
assign tf_ROM_r[136] = 32'hFFFF04EC;
assign tf_ROM_r[137] = 32'hFFFF0639;
assign tf_ROM_r[138] = 32'hFFFF07AD;
assign tf_ROM_r[139] = 32'hFFFF0946;
assign tf_ROM_r[140] = 32'hFFFF0B06;
assign tf_ROM_r[141] = 32'hFFFF0CEC;
assign tf_ROM_r[142] = 32'hFFFF0EF7;
assign tf_ROM_r[143] = 32'hFFFF1128;
assign tf_ROM_r[144] = 32'hFFFF137D;
assign tf_ROM_r[145] = 32'hFFFF15F7;
assign tf_ROM_r[146] = 32'hFFFF1895;
assign tf_ROM_r[147] = 32'hFFFF1B56;
assign tf_ROM_r[148] = 32'hFFFF1E3B;
assign tf_ROM_r[149] = 32'hFFFF2142;
assign tf_ROM_r[150] = 32'hFFFF246C;
assign tf_ROM_r[151] = 32'hFFFF27B8;
assign tf_ROM_r[152] = 32'hFFFF2B25;
assign tf_ROM_r[153] = 32'hFFFF2EB3;
assign tf_ROM_r[154] = 32'hFFFF3261;
assign tf_ROM_r[155] = 32'hFFFF362F;
assign tf_ROM_r[156] = 32'hFFFF3A1C;
assign tf_ROM_r[157] = 32'hFFFF3E28;
assign tf_ROM_r[158] = 32'hFFFF4252;
assign tf_ROM_r[159] = 32'hFFFF4698;
assign tf_ROM_r[160] = 32'hFFFF4AFC;
assign tf_ROM_r[161] = 32'hFFFF4F7B;
assign tf_ROM_r[162] = 32'hFFFF5415;
assign tf_ROM_r[163] = 32'hFFFF58CA;
assign tf_ROM_r[164] = 32'hFFFF5D99;
assign tf_ROM_r[165] = 32'hFFFF6281;
assign tf_ROM_r[166] = 32'hFFFF6781;
assign tf_ROM_r[167] = 32'hFFFF6C98;
assign tf_ROM_r[168] = 32'hFFFF71C7;
assign tf_ROM_r[169] = 32'hFFFF770B;
assign tf_ROM_r[170] = 32'hFFFF7C64;
assign tf_ROM_r[171] = 32'hFFFF81D2;
assign tf_ROM_r[172] = 32'hFFFF8753;
assign tf_ROM_r[173] = 32'hFFFF8CE7;
assign tf_ROM_r[174] = 32'hFFFF928C;
assign tf_ROM_r[175] = 32'hFFFF9843;
assign tf_ROM_r[176] = 32'hFFFF9E09;
assign tf_ROM_r[177] = 32'hFFFFA3DE;
assign tf_ROM_r[178] = 32'hFFFFA9C2;
assign tf_ROM_r[179] = 32'hFFFFAFB3;
assign tf_ROM_r[180] = 32'hFFFFB5B0;
assign tf_ROM_r[181] = 32'hFFFFBBB9;
assign tf_ROM_r[182] = 32'hFFFFC1CD;
assign tf_ROM_r[183] = 32'hFFFFC7E9;
assign tf_ROM_r[184] = 32'hFFFFCE0F;
assign tf_ROM_r[185] = 32'hFFFFD43C;
assign tf_ROM_r[186] = 32'hFFFFDA70;
assign tf_ROM_r[187] = 32'hFFFFE0AA;
assign tf_ROM_r[188] = 32'hFFFFE6E9;
assign tf_ROM_r[189] = 32'hFFFFED2B;

wire [31:0] tf_ROM_i[189:0];
assign tf_ROM_i[0] = 32'h00000000;
assign tf_ROM_i[1] = 32'hFFFFF9B8;
assign tf_ROM_i[2] = 32'hFFFFF371;
assign tf_ROM_i[3] = 32'hFFFFED2B;
assign tf_ROM_i[4] = 32'hFFFFE6E9;
assign tf_ROM_i[5] = 32'hFFFFE0AA;
assign tf_ROM_i[6] = 32'hFFFFDA70;
assign tf_ROM_i[7] = 32'hFFFFD43C;
assign tf_ROM_i[8] = 32'hFFFFCE0F;
assign tf_ROM_i[9] = 32'hFFFFC7E9;
assign tf_ROM_i[10] = 32'hFFFFC1CD;
assign tf_ROM_i[11] = 32'hFFFFBBB9;
assign tf_ROM_i[12] = 32'hFFFFB5B0;
assign tf_ROM_i[13] = 32'hFFFFAFB3;
assign tf_ROM_i[14] = 32'hFFFFA9C2;
assign tf_ROM_i[15] = 32'hFFFFA3DE;
assign tf_ROM_i[16] = 32'hFFFF9E09;
assign tf_ROM_i[17] = 32'hFFFF9843;
assign tf_ROM_i[18] = 32'hFFFF928C;
assign tf_ROM_i[19] = 32'hFFFF8CE7;
assign tf_ROM_i[20] = 32'hFFFF8753;
assign tf_ROM_i[21] = 32'hFFFF81D2;
assign tf_ROM_i[22] = 32'hFFFF7C64;
assign tf_ROM_i[23] = 32'hFFFF770B;
assign tf_ROM_i[24] = 32'hFFFF71C7;
assign tf_ROM_i[25] = 32'hFFFF6C98;
assign tf_ROM_i[26] = 32'hFFFF6781;
assign tf_ROM_i[27] = 32'hFFFF6281;
assign tf_ROM_i[28] = 32'hFFFF5D99;
assign tf_ROM_i[29] = 32'hFFFF58CA;
assign tf_ROM_i[30] = 32'hFFFF5415;
assign tf_ROM_i[31] = 32'hFFFF4F7B;
assign tf_ROM_i[32] = 32'hFFFF4AFC;
assign tf_ROM_i[33] = 32'hFFFF4698;
assign tf_ROM_i[34] = 32'hFFFF4252;
assign tf_ROM_i[35] = 32'hFFFF3E28;
assign tf_ROM_i[36] = 32'hFFFF3A1C;
assign tf_ROM_i[37] = 32'hFFFF362F;
assign tf_ROM_i[38] = 32'hFFFF3261;
assign tf_ROM_i[39] = 32'hFFFF2EB3;
assign tf_ROM_i[40] = 32'hFFFF2B25;
assign tf_ROM_i[41] = 32'hFFFF27B8;
assign tf_ROM_i[42] = 32'hFFFF246C;
assign tf_ROM_i[43] = 32'hFFFF2142;
assign tf_ROM_i[44] = 32'hFFFF1E3B;
assign tf_ROM_i[45] = 32'hFFFF1B56;
assign tf_ROM_i[46] = 32'hFFFF1895;
assign tf_ROM_i[47] = 32'hFFFF15F7;
assign tf_ROM_i[48] = 32'hFFFF137D;
assign tf_ROM_i[49] = 32'hFFFF1128;
assign tf_ROM_i[50] = 32'hFFFF0EF7;
assign tf_ROM_i[51] = 32'hFFFF0CEC;
assign tf_ROM_i[52] = 32'hFFFF0B06;
assign tf_ROM_i[53] = 32'hFFFF0946;
assign tf_ROM_i[54] = 32'hFFFF07AD;
assign tf_ROM_i[55] = 32'hFFFF0639;
assign tf_ROM_i[56] = 32'hFFFF04EC;
assign tf_ROM_i[57] = 32'hFFFF03C5;
assign tf_ROM_i[58] = 32'hFFFF02C6;
assign tf_ROM_i[59] = 32'hFFFF01ED;
assign tf_ROM_i[60] = 32'hFFFF013C;
assign tf_ROM_i[61] = 32'hFFFF00B2;
assign tf_ROM_i[62] = 32'hFFFF004F;
assign tf_ROM_i[63] = 32'hFFFF0014;
assign tf_ROM_i[64] = 32'hFFFF0000;
assign tf_ROM_i[65] = 32'hFFFF0014;
assign tf_ROM_i[66] = 32'hFFFF004F;
assign tf_ROM_i[67] = 32'hFFFF00B2;
assign tf_ROM_i[68] = 32'hFFFF013C;
assign tf_ROM_i[69] = 32'hFFFF01ED;
assign tf_ROM_i[70] = 32'hFFFF02C6;
assign tf_ROM_i[71] = 32'hFFFF03C5;
assign tf_ROM_i[72] = 32'hFFFF04EC;
assign tf_ROM_i[73] = 32'hFFFF0639;
assign tf_ROM_i[74] = 32'hFFFF07AD;
assign tf_ROM_i[75] = 32'hFFFF0946;
assign tf_ROM_i[76] = 32'hFFFF0B06;
assign tf_ROM_i[77] = 32'hFFFF0CEC;
assign tf_ROM_i[78] = 32'hFFFF0EF7;
assign tf_ROM_i[79] = 32'hFFFF1128;
assign tf_ROM_i[80] = 32'hFFFF137D;
assign tf_ROM_i[81] = 32'hFFFF15F7;
assign tf_ROM_i[82] = 32'hFFFF1895;
assign tf_ROM_i[83] = 32'hFFFF1B56;
assign tf_ROM_i[84] = 32'hFFFF1E3B;
assign tf_ROM_i[85] = 32'hFFFF2142;
assign tf_ROM_i[86] = 32'hFFFF246C;
assign tf_ROM_i[87] = 32'hFFFF27B8;
assign tf_ROM_i[88] = 32'hFFFF2B25;
assign tf_ROM_i[89] = 32'hFFFF2EB3;
assign tf_ROM_i[90] = 32'hFFFF3261;
assign tf_ROM_i[91] = 32'hFFFF362F;
assign tf_ROM_i[92] = 32'hFFFF3A1C;
assign tf_ROM_i[93] = 32'hFFFF3E28;
assign tf_ROM_i[94] = 32'hFFFF4252;
assign tf_ROM_i[95] = 32'hFFFF4698;
assign tf_ROM_i[96] = 32'hFFFF4AFC;
assign tf_ROM_i[97] = 32'hFFFF4F7B;
assign tf_ROM_i[98] = 32'hFFFF5415;
assign tf_ROM_i[99] = 32'hFFFF58CA;
assign tf_ROM_i[100] = 32'hFFFF5D99;
assign tf_ROM_i[101] = 32'hFFFF6281;
assign tf_ROM_i[102] = 32'hFFFF6781;
assign tf_ROM_i[103] = 32'hFFFF6C98;
assign tf_ROM_i[104] = 32'hFFFF71C7;
assign tf_ROM_i[105] = 32'hFFFF770B;
assign tf_ROM_i[106] = 32'hFFFF7C64;
assign tf_ROM_i[107] = 32'hFFFF81D2;
assign tf_ROM_i[108] = 32'hFFFF8753;
assign tf_ROM_i[109] = 32'hFFFF8CE7;
assign tf_ROM_i[110] = 32'hFFFF928C;
assign tf_ROM_i[111] = 32'hFFFF9843;
assign tf_ROM_i[112] = 32'hFFFF9E09;
assign tf_ROM_i[113] = 32'hFFFFA3DE;
assign tf_ROM_i[114] = 32'hFFFFA9C2;
assign tf_ROM_i[115] = 32'hFFFFAFB3;
assign tf_ROM_i[116] = 32'hFFFFB5B0;
assign tf_ROM_i[117] = 32'hFFFFBBB9;
assign tf_ROM_i[118] = 32'hFFFFC1CD;
assign tf_ROM_i[119] = 32'hFFFFC7E9;
assign tf_ROM_i[120] = 32'hFFFFCE0F;
assign tf_ROM_i[121] = 32'hFFFFD43C;
assign tf_ROM_i[122] = 32'hFFFFDA70;
assign tf_ROM_i[123] = 32'hFFFFE0AA;
assign tf_ROM_i[124] = 32'hFFFFE6E9;
assign tf_ROM_i[125] = 32'hFFFFED2B;
assign tf_ROM_i[126] = 32'hFFFFF371;
assign tf_ROM_i[127] = 32'hFFFFF9B8;
assign tf_ROM_i[128] = 32'h00000000;
assign tf_ROM_i[129] = 32'h00000648;
assign tf_ROM_i[130] = 32'h00000C8F;
assign tf_ROM_i[131] = 32'h000012D5;
assign tf_ROM_i[132] = 32'h00001917;
assign tf_ROM_i[133] = 32'h00001F56;
assign tf_ROM_i[134] = 32'h00002590;
assign tf_ROM_i[135] = 32'h00002BC4;
assign tf_ROM_i[136] = 32'h000031F1;
assign tf_ROM_i[137] = 32'h00003817;
assign tf_ROM_i[138] = 32'h00003E33;
assign tf_ROM_i[139] = 32'h00004447;
assign tf_ROM_i[140] = 32'h00004A50;
assign tf_ROM_i[141] = 32'h0000504D;
assign tf_ROM_i[142] = 32'h0000563E;
assign tf_ROM_i[143] = 32'h00005C22;
assign tf_ROM_i[144] = 32'h000061F7;
assign tf_ROM_i[145] = 32'h000067BD;
assign tf_ROM_i[146] = 32'h00006D74;
assign tf_ROM_i[147] = 32'h00007319;
assign tf_ROM_i[148] = 32'h000078AD;
assign tf_ROM_i[149] = 32'h00007E2E;
assign tf_ROM_i[150] = 32'h0000839C;
assign tf_ROM_i[151] = 32'h000088F5;
assign tf_ROM_i[152] = 32'h00008E39;
assign tf_ROM_i[153] = 32'h00009368;
assign tf_ROM_i[154] = 32'h0000987F;
assign tf_ROM_i[155] = 32'h00009D7F;
assign tf_ROM_i[156] = 32'h0000A267;
assign tf_ROM_i[157] = 32'h0000A736;
assign tf_ROM_i[158] = 32'h0000ABEB;
assign tf_ROM_i[159] = 32'h0000B085;
assign tf_ROM_i[160] = 32'h0000B504;
assign tf_ROM_i[161] = 32'h0000B968;
assign tf_ROM_i[162] = 32'h0000BDAE;
assign tf_ROM_i[163] = 32'h0000C1D8;
assign tf_ROM_i[164] = 32'h0000C5E4;
assign tf_ROM_i[165] = 32'h0000C9D1;
assign tf_ROM_i[166] = 32'h0000CD9F;
assign tf_ROM_i[167] = 32'h0000D14D;
assign tf_ROM_i[168] = 32'h0000D4DB;
assign tf_ROM_i[169] = 32'h0000D848;
assign tf_ROM_i[170] = 32'h0000DB94;
assign tf_ROM_i[171] = 32'h0000DEBE;
assign tf_ROM_i[172] = 32'h0000E1C5;
assign tf_ROM_i[173] = 32'h0000E4AA;
assign tf_ROM_i[174] = 32'h0000E76B;
assign tf_ROM_i[175] = 32'h0000EA09;
assign tf_ROM_i[176] = 32'h0000EC83;
assign tf_ROM_i[177] = 32'h0000EED8;
assign tf_ROM_i[178] = 32'h0000F109;
assign tf_ROM_i[179] = 32'h0000F314;
assign tf_ROM_i[180] = 32'h0000F4FA;
assign tf_ROM_i[181] = 32'h0000F6BA;
assign tf_ROM_i[182] = 32'h0000F853;
assign tf_ROM_i[183] = 32'h0000F9C7;
assign tf_ROM_i[184] = 32'h0000FB14;
assign tf_ROM_i[185] = 32'h0000FC3B;
assign tf_ROM_i[186] = 32'h0000FD3A;
assign tf_ROM_i[187] = 32'h0000FE13;
assign tf_ROM_i[188] = 32'h0000FEC4;
assign tf_ROM_i[189] = 32'h0000FF4E;	    
// =========
assign Data_out_r = data_o_r;
assign Data_out_i = data_o_i;
assign out_ready = output_ready;
// ***** reset
always @(posedge CLK or posedge RST)
begin
	if(RST)
	begin
		input_en <= 1;			//reset for new input
	end
end

// ***** stage 0
		BF BF0(.ar(Ar0),.ai(Ai0),.br(Br0),.bi(Bi0),.cr(Cr0),.ci(Ci0),.dr(Dr0),.di(Di0)); //Two inputs. Two outputs. C:Addition; D:Substraction
		TJ TF0(.tr(Tr0),.ti(Ti0),.sel(Sel0),.sr(Sr0),.si(Si0));		//only needs to implement * (-j)

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
			RAM0_r[RAM0_addr] <= {{9{Data_in_r[15]}},Data_in_r[14:0],{8{1'b0}}};  
			RAM0_i[RAM0_addr] <= {{9{Data_in_i[15]}},Data_in_i[14:0],{8{1'b0}}};  //Directly do signed extension 
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
		Br0 <= {{9{Data_in_r[15]}},Data_in_r[14:0],{8{1'b0}}};		//From input: 128, 129, ..., 255
		Bi0 <= {{9{Data_in_i[15]}},Data_in_i[14:0],{8{1'b0}}};		//Directly do signed extension
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
	BF BF1(.ar(Ar1),.ai(Ai1),.br(Br1),.bi(Bi1),.cr(Cr1),.ci(Ci1),.dr(Dr1),.di(Di1));
	TF TF1(.tr(Tr1),.ti(Ti1),.wr(Wr1),.wi(Wi1),.sr(Sr1),.si(Si1));	//input the twiddle factor

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
				Wr1 <= tf_ROM_r[tf_1_addr];		
				Wi1 <= tf_ROM_i[tf_1_addr];
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
				Wr1 <= tf_ROM_r[tf_1_addr*2];		
				Wi1 <= tf_ROM_i[tf_1_addr*2];
			end
			else				//DD,* W(0,3,6,...,189)
			begin
				Wr1 <= tf_ROM_r[tf_1_addr*3];		
				Wi1 <= tf_ROM_i[tf_1_addr*3];
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
	BF BF2(.ar(Ar2),.ai(Ai2),.br(Br2),.bi(Bi2),.cr(Cr2),.ci(Ci2),.dr(Dr2),.di(Di2)); //Two inputs. Two outputs. C:Addition; D:Substraction
	TJ TF2(.tr(Tr2),.ti(Ti2),.sel(Sel2),.sr(Sr2),.si(Si2));		//only needs to implement * (-j)

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
	BF BF3(.ar(Ar3),.ai(Ai3),.br(Br3),.bi(Bi3),.cr(Cr3),.ci(Ci3),.dr(Dr3),.di(Di3));
	TF TF3(.tr(Tr3),.ti(Ti3),.wr(Wr3),.wi(Wi3),.sr(Sr3),.si(Si3));	//input the twiddle factor

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
				Wr3 <= tf_ROM_r[tf_3_addr*4];		
				Wi3 <= tf_ROM_i[tf_3_addr*4];
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
				Wr3 <= tf_ROM_r[tf_3_addr*8];		
				Wi3 <= tf_ROM_i[tf_3_addr*8];
			end
			else				//DD,* W(0,3,6,...,45)
			begin
				Wr3 <= tf_ROM_r[tf_3_addr*12];		
				Wi3 <= tf_ROM_i[tf_3_addr*12];
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
	BF BF4(.ar(Ar4),.ai(Ai4),.br(Br4),.bi(Bi4),.cr(Cr4),.ci(Ci4),.dr(Dr4),.di(Di4)); //Two inputs. Two outputs. C:Addition; D:Substraction
	TJ TF4(.tr(Tr4),.ti(Ti4),.sel(Sel4),.sr(Sr4),.si(Si4));	//only needs to implement * (-j)

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
	BF BF5(.ar(Ar5),.ai(Ai5),.br(Br5),.bi(Bi5),.cr(Cr5),.ci(Ci5),.dr(Dr5),.di(Di5));
	TF TF5(.tr(Tr5),.ti(Ti5),.wr(Wr5),.wi(Wi5),.sr(Sr5),.si(Si5));	//input the twiddle factor

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
		stage6_input_en <= 1;	//Open the stage 6's RAM after data enters into tf module
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
				Wr5 <= tf_ROM_r[tf_5_addr*16];		
				Wi5 <= tf_ROM_i[tf_5_addr*16];
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
				Wr5 <= tf_ROM_r[tf_5_addr*32];		
				Wi5 <= tf_ROM_i[tf_5_addr*32];
			end
			else				//DD,* W(0,3,6,...,45)
			begin
				Wr5 <= tf_ROM_r[tf_5_addr*48];		
				Wi5 <= tf_ROM_i[tf_5_addr*48];
			end
			if(tf_5_addr == 3)
			begin
				tf_5_flag <= tf_5_flag+1;	//Switch flag after cycle of 8 	
				tf_5_addr <= 0;
			end
		end
	end
end	

// ***** stage 6
	BF BF6(.ar(Ar6),.ai(Ai6),.br(Br6),.bi(Bi6),.cr(Cr6),.ci(Ci6),.dr(Dr6),.di(Di6)); //Two inputs. Two outputs. C:Addition; D:Substraction
	TJ TF6(.tr(Tr6),.ti(Ti6),.sel(Sel6),.sr(Sr6),.si(Si6));		//only needs to implement * (-j)

always @(posedge CLK or posedge RST)		//STAGE 6 Store: loop of 2
begin
	if(RST)
	begin
		bf_6_en   <= 0;			//Disable this stage's BF (stage 6)			
		tf_6_en   <= 0;			//Disable this stage's Twiddle Factor Module
		input_6_flag <= 1;		//Initial mode: input from Data_in
		RAM6_addr <= 0;			//Address Reset	
	end
	else if(input_en)
	begin
		if(input_6_flag == 1)		// Input data go into RAM 6   
		begin
			RAM6_r[RAM6_addr] <= Sr5;  
			RAM6_i[RAM6_addr] <= Si5;  
			RAM6_addr <= RAM6_addr+1;
			if(RAM6_addr == 1)
			begin	
				bf_6_en   <= 1;		//Enable this stage's BF (stage 6)			
				tf_6_en   <= 1;		//Enable this stage's Twiddle Factor Module
				input_6_flag <= 0;
				RAM6_addr <= 0;
			end
		end
		else //input_6_flag == 0, fetch from butterfly
		begin
			RAM6_r[RAM6_addr] <= Dr6;		//Subtraction part goes back io RAM6
			RAM6_i[RAM6_addr] <= Di6;		
			RAM6_addr <= RAM6_addr+1;
			if(RAM6_addr == 1)
			begin
				bf_6_en <= 0;	//Disable this stage's BF
				RAM6_addr <= 0;
				input_6_flag <= 1;
			end
		end
	end
end

always @(negedge CLK or posedge RST)		//STAGE 6 Butterfly: loop of 2
begin
    if(RST) 
    begin
        bf_6_addr <= 0;   //Address signal for BF reset
    end
	else if(bf_6_en)
	begin
		Ar6 <= RAM0_r[bf_6_addr];	//From RAM anterior data: 
		Ai6 <= RAM0_i[bf_6_addr];
		Br6 <= Sr5;		
		Bi6 <= Si5;			//From stage 3 buffer
		bf_6_addr <= bf_6_addr+1;
		if(bf_6_addr == 1)
		begin
			bf_6_addr <= 0;
		end
	end
end

always @(posedge CLK or posedge RST)		//STAGE 6 Twiddle Factor: loop of 2
begin
	if(RST)
	begin
		tf_6_addr <= 0;			//Address rest
		stage7_input_en <= 0;	//Disable input into stage3
	end
	else if(tf_6_en)					//Open the stage 6's tf module
	begin
		stage7_input_en <= 1;	//Open the stage 1's RAM after data enters into tf module
		if(bf_6_en)
		begin
			Tr6 <= Cr6;		//Addition part goes to tf module
			Ti6 <= Ci6;
			Sel6 <= 0; 	
			tf_6_addr <= tf_6_addr + 1;
			if(tf_6_addr == 1)
			begin
				tf_6_addr <= 0;
			end
		end
		else	//bf_6_en == 0, receiving data from RAM6
		begin
			Tr6 <= RAM6_r[tf_6_addr];
			Ti6 <= RAM6_i[tf_6_addr];
			tf_6_addr <= tf_6_addr + 1;
			if(tf_6_addr < 1)		//tf_6_addr == 0, sel6 = 0
			begin
				Sel6 <= 0;
			end
			else				//tf_6_addr == 1, sel6 = 1
			begin		
				Sel6 <= 1;
			end
			if(tf_6_addr == 1)
			begin
				tf_6_addr <= 0;
			end
		end
	end
end

//*****stage 7
	BF BF7(.ar(Ar7),.ai(Ai7),.br(Br7),.bi(Bi7),.cr(Cr7),.ci(Ci7),.dr(Dr7),.di(Di7));
//No need for TF module
//No need for address

always @(posedge CLK or posedge RST)	//STAGE 7 STORE: loop of 1
begin
	if(RST)
	begin
		bf_7_en   <= 0;			//Disable stage 7's BF (stage 7)			
		tf_7_en   <= 0;			//Disable stage 7's Twiddle Factor Module
		input_7_flag <= 1;		//Initial mode: input from Sr0, Si0
	end
	else if(stage7_input_en)		
	begin
		if(input_7_flag)							
		begin
			RAM7_r <= Sr6;		//Fetch from the last stage's buffer
			RAM7_i <= Si6;		
			bf_7_en   <= 1;		//Enable stage 7's BF (stage 0)			
			tf_7_en   <= 1;		//Enable stage 7's Twiddle Factor Module
			input_7_flag <= 0;
		end
		else	//input_7_flag == 0, fetch from butterfly		
		begin
			RAM7_r <= Dr7;		//From this stage's BF		
			RAM7_i <= Di7;
			bf_7_en <= 0;		//Disable stage 7's BF, repeat
			input_0_flag <= 1;
		end
	end
end

always @(negedge CLK or posedge RST)			//STAGE 7 Butterfly: loop of 1
begin
	if(RST)
	begin
		output_RAM_en <= 0;
	end	
	else if(bf_7_en)
	begin
		output_RAM_en <= 1;
		Ar7 <= RAM7_r;		//From RAM anterior data
		Ai7 <= RAM7_i;
		Br7 <= Sr6;		//From tf6's output
		Bi7 <= Si6;
	end
end

//*****Output stage
always @(posedge CLK or posedge RST)	//output & truncate
begin
	if(RST)
	begin
		output_RAM_addr <= 0;
		output_RAM_flag <= 0;
	end
	else if(output_RAM_en)   //0,128,64,192,1,129,65,129,3...
	begin
		case(output_RAM_flag)			//From Butterfly 7, //0,1,2,3...
		"00":
		begin
			output_RAM_r[output_RAM_addr] <= {Cr7[31], Cr7[22:8]};	
			output_RAM_i[output_RAM_addr] <= {Cr7[31], Cr7[22:8]};
			output_RAM_flag <= output_RAM_flag+1;	
			if(output_RAM_addr == 0)		//output_buffer only used for one cycle
			begin
				output_buffer_en <= 0;	
			end
		end
		"01":			//From RAM7 //128,129,130...
		begin
			output_RAM_r[output_RAM_addr+128] <= {RAM7_r[31], RAM7_r[22:8]};
			output_RAM_i[output_RAM_addr+128] <= {RAM7_i[31], RAM7_i[22:8]};
			output_RAM_flag <= output_RAM_flag+1;		
		end	
		"10":		//From Butterfly 7 //64,65,66...
		begin
			output_RAM_r[output_RAM_addr+64] <= {Cr7[31], Cr7[22:8]};
			output_RAM_i[output_RAM_addr+64] <= {Cr7[31], Cr7[22:8]};	
			output_RAM_flag <= output_RAM_flag+1;
		end
		"11":			//From RAM7 //192,193,194...
		begin
			output_RAM_r[output_RAM_addr+192] <= {RAM7_r[31], RAM7_r[22:8]};
			output_RAM_i[output_RAM_addr+192] <= {RAM7_i[31], RAM7_i[22:8]};
			output_RAM_addr <= output_RAM_addr + 1;	
			output_RAM_flag <= 0;
			if(output_RAM_addr == 63)		//can be loaded into the output_buffer in parallel
			begin
				output_buffer_en <= 1;	
			end
		end
		endcase
	end
end

always @(posedge CLK or posedge RST) 		//output_buffer_RAM: read the output_RAM in parallel
begin
	if(RST)
	begin
		output_en <= 0;
	end
	else if(output_buffer_en)
	begin
		output_en <= 1;
		for(m = 0; m < 256; m = m + 1) 
		begin
			output_buffer_r[m] <= output_RAM_r[m];
			output_buffer_i[m] <= output_RAM_i[m];		
		end
	end
	else
	begin
		output_en <= 0;
	end
end
			
always @(posedge CLK or posedge RST)		//output stream
begin
	if(RST)
	begin
		output_ptr <= 0;		//output address pointer
	end
	else if(output_en)   
	begin
		if(output_ptr == 0)
		begin
			output_ready <= 1;
		end
		data_o_r <= output_buffer_r[output_ptr];
		data_o_i <= output_buffer_r[output_ptr];
		output_ptr <= output_ptr+1;
		if(output_ptr == 255)
		begin
			output_ptr <= 0;
			output_ready <= 0;
		end
	end
end
endmodule

