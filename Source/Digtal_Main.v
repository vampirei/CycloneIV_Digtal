module Digtal_Main(
	input 			CLOCK_Digtal,		//数字接口时钟
	//编码器相关
	input 			CS,					//片选
	output [7:0]	Out_Data,			//数据输出
	//数据接收相关
	input 			RD,					//接收模块数据输出时钟
	input [7:0]		Rx_Data,				//接收模块数据输出
	//RAM相关
	output [7:0]	RAM_Data_In,		//RAM数据输入
	output [30:0]	RAM_RDADD,			//RAM读取地址
	output [30:0]	RAM_WRADD,			//RAM写入地址
	output 			RAM_RDEN,			//RAM读请求
	output 			RAM_WREN,			//RAM写请求
	input [7:0]		RAM_Q					//RAM数据输出
	);
//------------参数定义
	parameter unsigned 			Mode = 0;										//工作模式：1--接收到即发送模式，插入字有效；其他--整帧接收模式，帧头字有效。
	parameter unsigned 			Length_InsertOrFrameheader = 4;			//插入字或帧头长度
	parameter 						Byte1_InsertOrFrameheader = 8'HEB;		//插入字1或者帧头1
	parameter 						Byte2_InsertOrFrameheader = 8'H90;		//插入字2或者帧头2
	parameter 						Byte3_InsertOrFrameheader = 8'H90;		//插入字3或者帧头3
	parameter 						Byte4_InsertOrFrameheader = 8'HEB;		//插入字4或者帧头4
	parameter 						Byte5_InsertOrFrameheader = 8'HEB;		//插入字5或者帧头5
	parameter 						Byte6_InsertOrFrameheader = 8'H90;		//插入字6或者帧头6
	parameter 						Byte7_InsertOrFrameheader = 8'H90;		//插入字7或者帧头7
	parameter 						Byte8_InsertOrFrameheader = 8'HEB;		//插入字8或者帧头8
	localparam 						Write_Delay = 15;								//读写定时阈值
	localparam 						Idle_FrameMode = 8'HAA;						//整帧接受模式中发送的空闲字
	localparam unsigned 			Length_Frame = 16'D50;						//整帧接收模式中帧长(包含帧头)
/*	parameter Instert_Length = 4;						//插入字长度，4---8
	parameter Instert_Byte1 = 8'HEB;					//插入字1
	parameter Instert_Byte2 = 8'H90;					//插入字2
	parameter Instert_Byte3 = 8'H90;					//插入字3
	parameter Instert_Byte4 = 8'HEB;					//插入字4
	parameter Instert_Byte5 = 8'HEB;					//插入字5
	parameter Instert_Byte6 = 8'H90;					//插入字6
	parameter Instert_Byte7 = 8'H90;					//插入字7
	parameter Instert_Byte8 = 8'HEB;					//插入字8
*/	
	
//------------内部声明
	reg [1:0] 	Digtal_CS_Edge = 2'B00;					//CS边沿寄存器
	reg [1:0] 	Digtal_DATA_RD_Edge = 2'B00;			//RD边沿寄存器
	reg 			CLK_Counter_W_EN  = 1'B0;				//时钟计数允许(写RAM)						
	reg [7:0]	CLK_Counter_W = 8'D0;					//时钟计数(写RAM)
	reg 			CLK_Counter_R_EN  = 1'B0;				//时钟计数允许(读RAM)
	reg [7:0] 	CLK_Counter_R = 8'D0;					//时钟计数(读RAM)
	reg [31:0] 	RAM_wraddress_Reg = 32'D0;				//RAM写入地址寄存器
	reg [31:0] 	RAM_rdaddress_Reg = 32'D0;				//RAM读取地址寄存器
	reg [9:0] 	ByteModeStatus = 10'B10_0000_0001;	//字节模式发送状态
																	/*
																	bit0 ----- bit7 Insert word 发送情况
																	bit8   Read状态
																	bit9   Insert状态		
																	*/	
	reg [8:0]	ReceiveFrameHeaderStatus = 9'D0;		//整帧模式帧头接收状态
																	/*
																		bit8-----帧头全部接收完成
																		bit7-----Byte8_InsertOrFrameheader接收到
																		bit6-----Byte7_InsertOrFrameheader接收到
																		bit5-----Byte6_InsertOrFrameheader接收到
																		bit4-----Byte5_InsertOrFrameheader接收到
																		bit3-----Byte4_InsertOrFrameheader接收到
																		bit2-----Byte3_InsertOrFrameheader接收到
																		bit1-----Byte2_InsertOrFrameheader接收到
																		bit0-----Byte1_InsertOrFrameheader接收到
																	*/	
	reg [15:0]	ReceiveFrameStatus = 16'D0;			//整帧模式接收数量
	reg 			EN_SendFrame = 1'B0;						//整帧模式发送允许
	reg [8:0]	SendFrameHeaderStatus = 9'D0;			//整帧模式帧头发送状态
																	/*
																		bit8-----帧头全部发送完成
																		bit7-----Byte8_InsertOrFrameheader发送完成
																		bit6-----Byte7_InsertOrFrameheader发送完成
																		bit5-----Byte6_InsertOrFrameheader发送完成
																		bit4-----Byte5_InsertOrFrameheader发送完成
																		bit3-----Byte4_InsertOrFrameheader发送完成
																		bit2-----Byte3_InsertOrFrameheader发送完成
																		bit1-----Byte2_InsertOrFrameheader发送完成
																		bit0-----Byte1_InsertOrFrameheader发送完成
																	*/	
	reg [15:0]	SendFrameStatus = 16'D0;				//整帧模式发送数量
	reg [7:0] 	OUTPUT_data_Reg = 8'D0;					//输出数据缓存
	reg 			RAM_rden_Reg = 1'B0;						//RAM读请求缓存
	reg 			RAM_wren_Reg = 1'B0;						//RAM写请求缓存
	
//*****************片选边沿获取	
	always @(posedge CLOCK_Digtal)	begin
		Digtal_CS_Edge[1] = Digtal_CS_Edge[0];
		Digtal_CS_Edge[0] = CS;
	end
//*****************串口数据时钟边沿获取
	always @(posedge CLOCK_Digtal)	begin
		Digtal_DATA_RD_Edge[1] = Digtal_DATA_RD_Edge[0];
		Digtal_DATA_RD_Edge[0] = RD;
	end	
//*****************读写时钟计数
	always @(posedge CLOCK_Digtal)	begin
		if(CLK_Counter_W_EN == 1'B1)	begin				//写时钟计数
			CLK_Counter_W = CLK_Counter_W + 1'B1;
		end
		else	begin
			CLK_Counter_W = 7'D0;
		end
		if(CLK_Counter_R_EN == 1'B1)	begin				//读时钟计数
			CLK_Counter_R = CLK_Counter_R + 1'B1;
		end
		else	begin
			CLK_Counter_R = 7'D0;
		end
	end	
//*****************接收数据
	/*
	*数据时钟上升沿     开始写入时钟计数
	*数据时钟下降沿     停止写入时钟计数
	* 写入时钟计数值为1		准备RAM需要写入的数据
	* 写入时钟计数值为2		输出RAM写请求
	* 写入时钟计数值为3-4	保持RAM写请求	
	* 写入时钟计数值为5		清除RAM写请求
	* 写入时钟计数值为6		准备RAM下次输出地址	
	*/
	/*
	*CS上升沿，首先判断发送状态（INSERT还是READ）
	*CS下降沿  更新状态(INSERT或READ)
	* 读取时钟计数值为1		输出RAM读请求
	* 读取时钟计数值为2--4	保持RAM读请求	读取RAM数据
	* 读取时钟计数值为5		清除RAM读请求
	* 读取时钟计数值为6		准备RAM下次读取地址	
	*/
//*****************接收数据	
	always @(posedge CLOCK_Digtal)	begin
		if(Mode == 1)	begin				//接收到即发送模式，插入字有效
			//判断时钟计数器是否大于阈值，停止计数
			if(CLK_Counter_W > Write_Delay)	begin
				CLK_Counter_W_EN = 1'B0;
			end
			//数据时钟上升沿   开始写入时钟计数
			if(Digtal_DATA_RD_Edge == 2'B01)	begin
				CLK_Counter_W_EN = 1'B1;				//开启写入计数器，准备写入数据
			end
			//数据时钟下降沿   停止写入时钟计数
			else if(Digtal_DATA_RD_Edge == 2'B10)	begin
				CLK_Counter_W_EN = 1'B0;				//停止写入时钟计数
			end
			//根据写入时钟计数器值写入数据
			else begin											
				case(CLK_Counter_W)
					8'D1:	begin			//准备RAM需要写入数据
						//RAM_data_Reg = Digtal_DATA;
					end
					8'D2:	begin			//输出RAM写请求
						RAM_wren_Reg = 1'B1;
					end
					8'D3:	begin			//保持RAM写请求
						RAM_wren_Reg = 1'B1;
					end
					8'D4:	begin			//保持RAM写请求
						RAM_wren_Reg = 1'B1;
					end
					8'D5:	begin			//清除RAM写请求
						RAM_wren_Reg = 1'B0;
					end
					8'D6:	begin			//准备RAM下次写入地址
						RAM_wraddress_Reg[31:0] = RAM_wraddress_Reg[31:0] + 1'B1;				//写入地址增加1							
					end
					8'D7:	begin
						RAM_wren_Reg = 1'B0;																	//停止RAM写入时钟计数
					end
					default :	begin																			//防错  补全 case
						RAM_wraddress_Reg[31:0] = RAM_wraddress_Reg[31:0];
					end
				endcase
			end
			if(Digtal_CS_Edge == 2'B01)	begin				//片选上升沿
				if(ByteModeStatus[9] == 1'B1)	begin				//处于INSERT状态
					if(ByteModeStatus[0] == 1'B1)				OUTPUT_data_Reg = Byte1_InsertOrFrameheader;
					else if(ByteModeStatus[1] == 1'B1)		OUTPUT_data_Reg = Byte2_InsertOrFrameheader;
					else if(ByteModeStatus[2] == 1'B1)		OUTPUT_data_Reg = Byte3_InsertOrFrameheader;
					else if(ByteModeStatus[3] == 1'B1)		OUTPUT_data_Reg = Byte4_InsertOrFrameheader;
					else if(ByteModeStatus[4] == 1'B1)		OUTPUT_data_Reg = Byte5_InsertOrFrameheader;
					else if(ByteModeStatus[5] == 1'B1)		OUTPUT_data_Reg = Byte6_InsertOrFrameheader;
					else if(ByteModeStatus[6] == 1'B1)		OUTPUT_data_Reg = Byte7_InsertOrFrameheader;
					else if(ByteModeStatus[7] == 1'B1)		OUTPUT_data_Reg = Byte8_InsertOrFrameheader;
				end
				else if(ByteModeStatus[8] == 1'B1)	begin				//处于Read状态
					CLK_Counter_R_EN = 1'B1;				//开启读取计数器，准备读取RAM数据
				end
			end
			else if(Digtal_CS_Edge == 2'B11)	begin				//片选有效期间
				case(CLK_Counter_R)										//选择读取计数时钟值
					8'D1:	begin											//输出RAM读请求
						RAM_rden_Reg = 1'B1;
					end
					8'D2:	begin											//保持RAM读请求
						RAM_rden_Reg = 1'B1;
					end
					8'D3:	begin											//保持RAM读请求
						RAM_rden_Reg = 1'B1;
					end
					8'D4:	begin											//保持RAM读请求  读取RAM数据
						RAM_rden_Reg = 1'B1;
						OUTPUT_data_Reg = RAM_Q;
					end
					8'D5:	begin											//清除RAM读请求
						RAM_rden_Reg = 1'B0;
					end
					8'D6:	begin											//准备RAM下次读取地址	
						CLK_Counter_R_EN = 1'B0;														//RAM读取时钟计数停止
						RAM_rdaddress_Reg[31:0] = RAM_rdaddress_Reg[31:0] + 1'B1;			//RAM地址增加1
					end
					default:	begin											//防错  补全case default
						RAM_rdaddress_Reg = RAM_rdaddress_Reg;
					end
				endcase
			end
			else if(Digtal_CS_Edge == 2'B10)	begin				//片选下降沿
				if(ByteModeStatus[9] == 1'B1)	begin
					if(ByteModeStatus[0] == 1'B1)	begin
						ByteModeStatus = 10'B10_0000_0010;
					end
					else if(ByteModeStatus[1] == 1'B1)	begin
						ByteModeStatus = 10'B10_0000_0100;
					end
					else if(ByteModeStatus[2] == 1'B1)	begin
						ByteModeStatus = 10'B10_0000_1000;
					end
					else if(ByteModeStatus[3] == 1'B1)	begin			//发送完最后一个INSERT值 判断是否可以读取RAM数据
						if(Length_InsertOrFrameheader == 4)	begin
							if((RAM_rdaddress_Reg + 1) <= RAM_wraddress_Reg)	begin
								ByteModeStatus = 10'B01_0000_0000;
							end
							else begin
								ByteModeStatus = 10'B10_0000_0001;
							end
						end
						else	begin
							ByteModeStatus = 10'B10_0001_0000;
						end
					end
					else if(ByteModeStatus[4] == 1'B1)	begin			//发送完最后一个INSERT值 判断是否可以读取RAM数据
						if(Length_InsertOrFrameheader == 5)	begin
							if(RAM_rdaddress_Reg + 1 <= RAM_wraddress_Reg)	begin
								ByteModeStatus = 10'B01_0000_0000;
							end
							else begin
								ByteModeStatus = 10'B10_0000_0001;
							end
						end
						else	begin
							ByteModeStatus = 10'B10_0010_0000;
						end
					end
					else if(ByteModeStatus[5] == 1'B1)	begin			//发送完最后一个INSERT值 判断是否可以读取RAM数据
						if(Length_InsertOrFrameheader == 6)	begin
							if(RAM_rdaddress_Reg + 1 <= RAM_wraddress_Reg)	begin
								ByteModeStatus = 10'B01_0000_0000;
							end
							else begin
								ByteModeStatus = 10'B10_0000_0001;
							end
						end
						else	begin
							ByteModeStatus = 10'B10_0100_0000;
						end
					end
					else if(ByteModeStatus[6] == 1'B1)	begin			//发送完最后一个INSERT值 判断是否可以读取RAM数据
						if(Length_InsertOrFrameheader == 7)	begin
							if(RAM_rdaddress_Reg + 1 <= RAM_wraddress_Reg)	begin
								ByteModeStatus = 10'B01_0000_0000;
							end
							else begin
								ByteModeStatus = 10'B10_0000_0001;
							end
						end
						else	begin
							ByteModeStatus = 10'B10_1000_0000;
						end
					end
					else if(ByteModeStatus[7] == 1'B1)			begin			//发送完最后一个INSERT值 判断是否可以读取RAM数据
						if(RAM_rdaddress_Reg + 1 <= RAM_wraddress_Reg)	begin
							ByteModeStatus = 10'B01_0000_0000;
						end
						else begin
							ByteModeStatus = 10'B10_0000_0001;
						end
					end
				end
				else if(ByteModeStatus[9] == 1'B0)	begin		//ByteModeStatus[8] == 1'B1  发送完一个Read数据，判断地址是否可能溢出，判断是否可以继续读取
					if(RAM_rdaddress_Reg[31] == 1'B1 && RAM_wraddress_Reg[31] == 1'B1)		begin			//防止地址溢出
						RAM_rdaddress_Reg[31] = 1'B0;
						RAM_wraddress_Reg[31] = 1'B0;
					end
					if(RAM_rdaddress_Reg + 1 <= RAM_wraddress_Reg)	begin											//判断是否可以继续读取RAM数据
						ByteModeStatus = 10'B01_0000_0000;
					end
					else begin
						ByteModeStatus = 10'B10_0000_0001;
					end
				end
			end
			else begin			//片选无效期间，补全if else
				CLK_Counter_R_EN = 1'B0;
			end
		end
		else	begin							//整帧接收模式，帧头字有效
			//判断时钟计数器是否大于阈值，停止计数
			if(CLK_Counter_W > Write_Delay)	begin
				CLK_Counter_W_EN = 1'B0;
			end
			//数据时钟上升沿，判断帧头接收状态
			if(Digtal_DATA_RD_Edge == 2'B01)	begin		//数据时钟上升沿，判断帧头接收状态
				if(ReceiveFrameHeaderStatus[8] == 1'B1)	begin		//帧头完全接收到，可以写入数据，开始写入时钟计数
					CLK_Counter_W_EN = 1'B1;				//开启写入计数器，准备写入数据
				end
				else	begin														//帧头没有完全接收到，不能写入数据，判断该接收哪个帧头
					if(ReceiveFrameHeaderStatus[0] == 1'B0)	begin	//帧头Byte1_InsertOrFrameheader	没有接收到
						if(Rx_Data == Byte1_InsertOrFrameheader)	begin		//接收到的数据是帧头1  
							ReceiveFrameHeaderStatus = 9'B0_0000_0001;		//标记帧头1接收完成
							ReceiveFrameStatus = 16'D1;							//标记接收到数据数量1
						end
						else	begin
							ReceiveFrameHeaderStatus = 9'B0_0000_0000;		//标记帧头1接收未完成
							ReceiveFrameStatus = 16'D0;							//标记接收到数据数量0
						end
					end
					else if(ReceiveFrameHeaderStatus[1] == 1'B0)	begin	//帧头Byte2_InsertOrFrameheader	没有接收到
						if(Rx_Data == Byte2_InsertOrFrameheader)	begin		//接收到的数据是帧头2  
							ReceiveFrameHeaderStatus[1] = 1'B1;					//标记帧头1接收完成
							ReceiveFrameStatus = 16'D2;							//标记接收到数据数量2
							if(Length_InsertOrFrameheader == 2)	begin			//帧头长度为2
								ReceiveFrameHeaderStatus[8] = 1'B1;				//标记帧头接收完成
							end
							else	begin
								ReceiveFrameHeaderStatus[8] = 1'B0;				//标记帧头接收未完成
							end
						end
						else if(Rx_Data == Byte1_InsertOrFrameheader)	begin		//接收到的数据是帧头1 
							ReceiveFrameHeaderStatus = 9'B0_0000_0001;
							ReceiveFrameStatus = 16'D1;									//标记接收到数据数量1
						end
						else	begin
							ReceiveFrameHeaderStatus = 9'B0_0000_0000;
							ReceiveFrameStatus = 16'D0;									//标记接收到数据数量0
						end
					end
					else if(ReceiveFrameHeaderStatus[2] == 1'B0)	begin	//帧头Byte3_InsertOrFrameheader	没有接收到
						if(Rx_Data == Byte3_InsertOrFrameheader)	begin		//接收到的数据是帧头3  
							ReceiveFrameHeaderStatus[2] = 1'B1;
							ReceiveFrameStatus = 16'D3;									//标记接收到数据数量3
							if(Length_InsertOrFrameheader == 3)	begin			//帧头长度为3
								ReceiveFrameHeaderStatus[8] = 1'B1;				//标记帧头接收完成
							end
							else	begin
								ReceiveFrameHeaderStatus[8] = 1'B0;				//标记帧头接收未完成
							end
						end
						else if(Rx_Data == Byte1_InsertOrFrameheader)	begin		//接收到的数据是帧头1 
							ReceiveFrameHeaderStatus = 9'B0_0000_0001;
							ReceiveFrameStatus = 16'D1;									//标记接收到数据数量1
						end
						else	begin
							ReceiveFrameHeaderStatus = 9'B0_0000_0000;
							ReceiveFrameStatus = 16'D0;									//标记接收到数据数量0
						end
					end
					else if(ReceiveFrameHeaderStatus[3] == 1'B0)	begin	//帧头Byte4_InsertOrFrameheader	没有接收到
						if(Rx_Data == Byte4_InsertOrFrameheader)	begin		//接收到的数据是帧头4  
							ReceiveFrameHeaderStatus[3] = 1'B1;
							ReceiveFrameStatus = 16'D4;									//标记接收到数据数量4
							if(Length_InsertOrFrameheader == 4)	begin			//帧头长度为4
								ReceiveFrameHeaderStatus[8] = 1'B1;				//标记帧头接收完成
							end
							else	begin
								ReceiveFrameHeaderStatus[8] = 1'B0;				//标记帧头接收未完成
							end
						end
						else if(Rx_Data == Byte1_InsertOrFrameheader)	begin		//接收到的数据是帧头1 
							ReceiveFrameHeaderStatus = 9'B0_0000_0001;
							ReceiveFrameStatus = 16'D1;									//标记接收到数据数量1
						end
						else	begin
							ReceiveFrameHeaderStatus = 9'B0_0000_0000;
							ReceiveFrameStatus = 16'D0;									//标记接收到数据数量0
						end
					end
					else if(ReceiveFrameHeaderStatus[4] == 1'B0)	begin	//帧头Byte5_InsertOrFrameheader	没有接收到
						if(Rx_Data == Byte5_InsertOrFrameheader)	begin		//接收到的数据是帧头5  
							ReceiveFrameHeaderStatus[4] = 1'B1;
							ReceiveFrameStatus = 16'D5;									//标记接收到数据数量5
							if(Length_InsertOrFrameheader == 5)	begin			//帧头长度为5
								ReceiveFrameHeaderStatus[8] = 1'B1;				//标记帧头接收完成
							end
							else	begin
								ReceiveFrameHeaderStatus[8] = 1'B0;				//标记帧头接收未完成
							end
						end
						else if(Rx_Data == Byte1_InsertOrFrameheader)	begin		//接收到的数据是帧头1 
							ReceiveFrameHeaderStatus = 9'B0_0000_0001;
							ReceiveFrameStatus = 16'D1;									//标记接收到数据数量1
						end
						else	begin
							ReceiveFrameHeaderStatus = 9'B0_0000_0000;
							ReceiveFrameStatus = 16'D0;									//标记接收到数据数量0
						end
					end
					else if(ReceiveFrameHeaderStatus[5] == 1'B0)	begin	//帧头Byte6_InsertOrFrameheader	没有接收到
						if(Rx_Data == Byte6_InsertOrFrameheader)	begin		//接收到的数据是帧头6  
							ReceiveFrameHeaderStatus[5] = 1'B1;
							ReceiveFrameStatus = 16'D6;									//标记接收到数据数量6
							if(Length_InsertOrFrameheader == 6)	begin			//帧头长度为6
								ReceiveFrameHeaderStatus[8] = 1'B1;				//标记帧头接收完成
							end
							else	begin
								ReceiveFrameHeaderStatus[8] = 1'B0;				//标记帧头接收未完成
							end
						end
						else if(Rx_Data == Byte1_InsertOrFrameheader)	begin		//接收到的数据是帧头1 
							ReceiveFrameHeaderStatus = 9'B0_0000_0001;
							ReceiveFrameStatus = 16'D1;									//标记接收到数据数量1
						end
						else	begin
							ReceiveFrameHeaderStatus = 9'B0_0000_0000;
							ReceiveFrameStatus = 16'D0;									//标记接收到数据数量0
						end
					end
					else if(ReceiveFrameHeaderStatus[6] == 1'B0)	begin	//帧头Byte7_InsertOrFrameheader	没有接收到
						if(Rx_Data == Byte7_InsertOrFrameheader)	begin		//接收到的数据是帧头7  
							ReceiveFrameHeaderStatus[6] = 1'B1;
							ReceiveFrameStatus = 16'D7;									//标记接收到数据数量7
							if(Length_InsertOrFrameheader == 7)	begin			//帧头长度为7
								ReceiveFrameHeaderStatus[8] = 1'B1;				//标记帧头接收完成
							end
							else	begin
								ReceiveFrameHeaderStatus[8] = 1'B0;				//标记帧头接收未完成
							end
						end
						else if(Rx_Data == Byte1_InsertOrFrameheader)	begin		//接收到的数据是帧头1 
							ReceiveFrameHeaderStatus = 9'B0_0000_0001;
							ReceiveFrameStatus = 16'D1;									//标记接收到数据数量1
						end
						else	begin
							ReceiveFrameHeaderStatus = 9'B0_0000_0000;
							ReceiveFrameStatus = 16'D0;									//标记接收到数据数量0
						end
					end
					else if(ReceiveFrameHeaderStatus[7] == 1'B0)	begin	//帧头Byte8_InsertOrFrameheader	没有接收到
						if(Rx_Data == Byte8_InsertOrFrameheader)	begin		//接收到的数据是帧头8 
							ReceiveFrameHeaderStatus = 9'B1_1111_1111;			//标记帧头接收完成
							ReceiveFrameStatus = 16'D8;									//标记接收到数据数量8
						end
						else if(Rx_Data == Byte1_InsertOrFrameheader)	begin		//接收到的数据是帧头1 
							ReceiveFrameHeaderStatus = 9'B0_0000_0001;
							ReceiveFrameStatus = 16'D1;									//标记接收到数据数量1
						end
						else	begin
							ReceiveFrameHeaderStatus = 9'B0_0000_0000;
							ReceiveFrameStatus = 16'D0;									//标记接收到数据数量0
						end
					end
				end
			end
			//数据时钟下降沿   停止写入时钟计数
			else if(Digtal_DATA_RD_Edge == 2'B10)	begin
				CLK_Counter_W_EN = 1'B0;				//停止写入时钟计数
			end
			//根据写入时钟计数器值写入数据
			else begin											
				case(CLK_Counter_W)
					8'D1:	begin			//准备RAM需要写入数据
						//RAM_data_Reg = Digtal_DATA;
					end
					8'D2:	begin			//输出RAM写请求
						RAM_wren_Reg = 1'B1;
					end
					8'D3:	begin			//保持RAM写请求
						RAM_wren_Reg = 1'B1;
					end
					8'D4:	begin			//保持RAM写请求
						RAM_wren_Reg = 1'B1;
					end
					8'D5:	begin			//清除RAM写请求
						RAM_wren_Reg = 1'B0;
						ReceiveFrameStatus = ReceiveFrameStatus + 1'B1;		//接收数量增加1
					end
					8'D6:	begin			//准备RAM下次写入地址
						RAM_wraddress_Reg[31:0] = RAM_wraddress_Reg[31:0] + 1'B1;				//写入地址增加1		
						if(ReceiveFrameStatus >= Length_Frame)	begin									//已经接收到1帧数据，可以允许读取
							EN_SendFrame = 1'B1;																//发送允许置1
							ReceiveFrameHeaderStatus = 9'B0_0000_0000;								//清除整帧模式帧头接收状态，重新开始检测帧头
							ReceiveFrameStatus = 16'D0;													//清空接收数量
						end
						else	begin																				//防错  补全if else
							ReceiveFrameHeaderStatus = ReceiveFrameHeaderStatus ;
						end
					end
					8'D7:	begin
						RAM_wren_Reg = 1'B0;																	//停止RAM写入时钟计数
					end
					default :	begin																			//防错  补全 case
						RAM_wraddress_Reg[31:0] = RAM_wraddress_Reg[31:0];
					end
				endcase
			end
			if(Digtal_CS_Edge == 2'B01)	begin				//片选上升沿
				if(EN_SendFrame == 1'B0)	begin					//不允许发送数据
					OUTPUT_data_Reg = Idle_FrameMode;				//填充整帧模式空闲字
				end
				else	begin												//允许发送数据，判断帧头是否发送完成
					if(SendFrameHeaderStatus[8] == 1'B0)	begin		//帧头发送未完成
						if(SendFrameHeaderStatus[0] == 1'B0)	begin		//帧头1未发送
							OUTPUT_data_Reg = Byte1_InsertOrFrameheader;		//发送帧头1
							SendFrameHeaderStatus[0] = 1'B1;						//标记帧头1发送完成
							SendFrameStatus = 16'D1;								//发送数据计数
						end
						else if(SendFrameHeaderStatus[1] == 1'B0)	begin		//帧头2未发送
							OUTPUT_data_Reg = Byte2_InsertOrFrameheader;		//发送帧头2
							SendFrameHeaderStatus[1] = 1'B1;						//标记帧头2发送完成
							SendFrameStatus = 16'D2;								//发送数据计数
							if(Length_InsertOrFrameheader == 2) 	begin							//帧头长度为2
								SendFrameHeaderStatus[8] = 1'B1;					//标记帧头发送完成
							end
						end 
						else if(SendFrameHeaderStatus[2] == 1'B0)	begin		//帧头3未发送
							OUTPUT_data_Reg = Byte3_InsertOrFrameheader;		//发送帧头3
							SendFrameHeaderStatus[2] = 1'B1;						//标记帧头3发送完成
							SendFrameStatus = 16'D3;								//发送数据计数
							if(Length_InsertOrFrameheader == 3) 	begin							//帧头长度为3
								SendFrameHeaderStatus[8] = 1'B1;					//标记帧头发送完成
							end
						end 
						else if(SendFrameHeaderStatus[3] == 1'B0)	begin		//帧头4未发送
							OUTPUT_data_Reg = Byte4_InsertOrFrameheader;		//发送帧头4
							SendFrameHeaderStatus[3] = 1'B1;						//标记帧头4发送完成
							SendFrameStatus = 16'D4;								//发送数据计数
							if(Length_InsertOrFrameheader == 4) 	begin							//帧头长度为4
								SendFrameHeaderStatus[8] = 1'B1;					//标记帧头发送完成
							end
						end 
						else if(SendFrameHeaderStatus[4] == 1'B0)	begin		//帧头5未发送
							OUTPUT_data_Reg = Byte5_InsertOrFrameheader;		//发送帧头5
							SendFrameHeaderStatus[4] = 1'B1;						//标记帧头5发送完成
							SendFrameStatus = 16'D5;								//发送数据计数
							if(Length_InsertOrFrameheader == 5) 	begin							//帧头长度为5
								SendFrameHeaderStatus[8] = 1'B1;					//标记帧头发送完成
							end
						end
						else if(SendFrameHeaderStatus[5] == 1'B0)	begin		//帧头6未发送
							OUTPUT_data_Reg = Byte6_InsertOrFrameheader;		//发送帧头6
							SendFrameHeaderStatus[5] = 1'B1;						//标记帧头6发送完成
							SendFrameStatus = 16'D6;								//发送数据计数
							if(Length_InsertOrFrameheader == 6) 	begin							//帧头长度为6
								SendFrameHeaderStatus[8] = 1'B1;					//标记帧头发送完成
							end
						end
						else if(SendFrameHeaderStatus[6] == 1'B0)	begin		//帧头7未发送
							OUTPUT_data_Reg = Byte7_InsertOrFrameheader;		//发送帧头7
							SendFrameHeaderStatus[6] = 1'B1;						//标记帧头7发送完成
							SendFrameStatus = 16'D7;								//发送数据计数
							if(Length_InsertOrFrameheader == 7) 	begin							//帧头长度为7
								SendFrameHeaderStatus[8] = 1'B1;					//标记帧头发送完成
							end
						end
						else if(SendFrameHeaderStatus[7] == 1'B0)	begin		//帧头8未发送
							OUTPUT_data_Reg = Byte8_InsertOrFrameheader;		//发送帧头8
							SendFrameHeaderStatus = 9'B1_1111_1111;			//标记帧头发送完成
							SendFrameStatus = 16'D8;								//发送数据计数
						end 
					end
					else	begin													//帧头发送完成 开启读取计数器，准备读取RAM数据
						CLK_Counter_R_EN = 1'B1;				//开启读取计数器，准备读取RAM数据
					end
				end 
			end
			else if(Digtal_CS_Edge == 2'B11)	begin				//片选有效期间
				case(CLK_Counter_R)										//选择读取计数时钟值
					8'D1:	begin											//输出RAM读请求
						RAM_rden_Reg = 1'B1;
					end
					8'D2:	begin											//保持RAM读请求
						RAM_rden_Reg = 1'B1;
					end
					8'D3:	begin											//保持RAM读请求
						RAM_rden_Reg = 1'B1;
					end
					8'D4:	begin											//保持RAM读请求  读取RAM数据
						RAM_rden_Reg = 1'B1;
						OUTPUT_data_Reg = RAM_Q;
					end
					8'D5:	begin											//清除RAM读请求
						RAM_rden_Reg = 1'B0;
					end
					8'D6:	begin											//准备RAM下次读取地址	
						CLK_Counter_R_EN = 1'B0;														//RAM读取时钟计数停止
						RAM_rdaddress_Reg[31:0] = RAM_rdaddress_Reg[31:0] + 1'B1;			//RAM地址增加1
						SendFrameStatus = SendFrameStatus + 1'B1;		//发送数据计数
					end
					default:	begin											//防错  补全case default
						RAM_rdaddress_Reg = RAM_rdaddress_Reg;
					end
				endcase
			end
			else if(Digtal_CS_Edge == 2'B10)	begin				//片选下降沿
				if(SendFrameStatus >= Length_Frame)		begin		//一帧数据发送完成
					EN_SendFrame = 1'B0;										//清除发送允许
					SendFrameStatus = 16'D0;								//清除发送数据计数
					SendFrameHeaderStatus = 9'B0_0000_0000;			//清除帧头发送状态
				end
				else	begin													//防错  补全if else
					SendFrameHeaderStatus = SendFrameHeaderStatus;
				end
			end
			else begin			//片选无效期间，补全if else
				CLK_Counter_R_EN = 1'B0;
			end
		end
	end
//*****************端口输出
	assign RAM_WREN = RAM_wren_Reg;														//RAM写请求
	assign RAM_RDEN = RAM_rden_Reg;														//RAM读请求
	assign RAM_Data_In = Rx_Data;															//RAM输入数据
	assign RAM_RDADD = RAM_rdaddress_Reg[30:0];										//RAM读取地址
	assign RAM_WRADD = RAM_wraddress_Reg[30:0];										//RAM写入地址
	assign Out_Data = (CS == 1'B1)? OUTPUT_data_Reg : 8'HZZ;						//模块输出数据
	
endmodule
