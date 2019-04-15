module Digtal_Rx	(
	input 			Baud16X,							//16倍波特率输入
	input 			Rx,								//数据输入
	output			RD,								//数据输出时钟
	output [7:0]	Data								//数据输出
);
//------------参数定义
	parameter Rx_Length = 8;						//串口数据长度 8bit 或9bit
	
//------------内部定义

	reg 			Counter_EN = 1'B0;							//计数器允许
	reg [7:0]	Counter = 8'D0;					//计数器
	reg 			StopBit_Error = 1'B0;						//停止位错误标记
	reg 			Receive_Complete = 1'B0;					//接收完成标记
	reg [7:0]	StartBit_Detection = 8'HFF;	//开始位检测寄存器
	reg [7:0]	Data_Reg = 8'D0;					//接收数据缓存
	reg [7:0] 	Digtal_DATA_Reg = 8'D0;			//输出数据缓存
	
	
//****开始位检测
	always @(posedge Baud16X)	begin
		StartBit_Detection[7:1] = StartBit_Detection[6:0];
		StartBit_Detection[0] = Rx;
	end

//****计数器
	always @(posedge Baud16X)	begin
		if(Counter_EN == 1'B0)	begin
			Counter = 8'D0;
		end
		else	begin
			Counter = Counter + 1'B1;
		end
	end

//****数据接收
	always @(posedge Baud16X)	begin
		if(StartBit_Detection == 8'B0000_0000)	begin				//连续8个低电平，认为开始位，允许计数
			Counter_EN = 1'B1;
		end
		if(Counter_EN == 1'B1)	begin
			//---------------复位各个错误标记位 
			if(Counter == 8'D1)	begin
				StopBit_Error = 		1'B0;		//复位停止位错误标记
				Receive_Complete = 	1'B0;		//复位接收完成标记
			end
			//---------------第1位数据接收 ------
			else if(Counter == 8'D16)	begin
				Data_Reg[0] = Rx;
			end
			//---------------第2位数据接收 ------
			else if(Counter == 8'D32)	begin
				Data_Reg[1] = Rx;
			end
			//---------------第3位数据接收 ------
			else if(Counter == 8'D48)	begin
				Data_Reg[2] = Rx;
			end
			//---------------第4位数据接收 ------
			else if(Counter == 8'D64)	begin
				Data_Reg[3] = Rx;
			end
			//---------------第5位数据接收 ------
			else if(Counter == 8'D80)	begin
				Data_Reg[4] = Rx;
			end
			//---------------第6位数据接收 ------
			else if(Counter == 8'D96)	begin
				Data_Reg[5] = Rx;
			end
			//---------------第7位数据接收 ------
			else if(Counter == 8'D112)	begin
				Data_Reg[6] = Rx;
			end
			//---------------第8位数据接收 ------
			else if(Counter == 8'D128)	begin
				Data_Reg[7] = Rx;
			end
			//---------------停止位判断 ------
			else if(Counter == 8'D144)	begin				
				if(Rx_Length == 8)	begin						// 8位接收数据  该位为停止位
					if(Rx == 1'B1)	begin								//停止位正确，允许输出数据，停止波特率
						StopBit_Error = 1'B0;							//清除停止位错误标记
						Receive_Complete = 1'B1;						//置数据读取标记
						Counter_EN = 1'B0;								//停止产生波特率
						Digtal_DATA_Reg[7:0] = Data_Reg[7:0];			//输出数据缓存
					end
					else	begin											//停止位错误，停止产生波特率，置停止位错误标志
						StopBit_Error = 1'B1;							//设置停止位错误标记
						Counter_EN = 1'B0;								//停止产生波特率
					end
				end
				else if(Rx_Length == 9)	begin				//9位接收数据	该位为校验位、第9位数据或者什么的
					StopBit_Error = 1'B0;						//忽略该位，不做任何事情
				end
				else 	begin										//补全if else
					StopBit_Error = 1'B0;
				end
			end
			else if(Counter == 8'D160)	begin				//9位接收数据才能到这里
				if(Rx_Length == 9)	begin						//该位为停止位
					if(Rx == 1'B1)	begin								//停止位正确，允许输出数据，停止波特率
						StopBit_Error = 1'B0;							//清除停止位错误标记
						Receive_Complete = 1'B1;						//置数据读取标记
						Counter_EN = 1'B0;								//停止产生波特率
						Digtal_DATA_Reg[7:0] = Data_Reg[7:0];		//输出数据缓存
					end
					else	begin											//停止位错误，停止产生波特率，置停止位错误标志
						StopBit_Error = 1'B1;							//设置停止位错误标记
						Counter_EN = 1'B0;								//停止产生波特率
					end
				end
				else	begin										//补全if else
					StopBit_Error = 1'B0;
				end
			end
			else	begin									//补全if else
				Counter_EN = Counter_EN;
			end
		end
	end


//**************端口输出*******

	assign RD = Receive_Complete;
	assign Data[7:0] = (RD == 1'B1) ? Digtal_DATA_Reg[7:0] : 8'HZZ;
	
endmodule
