/*
	Clock 数字接口输入时钟
	Baud16X 16倍波特率时钟输出
	Clock 必须是Baud的32倍及以上的偶数倍
*/

module Digtal_Baud(
	input 		Clock,									//数字接口时钟
	output 		Baud16X									//16倍波特率输出
);
//------------参数定义
	parameter unsigned CLOCK_Frequency = 29491200;			//数字接口时钟频率
	parameter unsigned Baud_Frequency = 921600;				//数字接口波特率频率
	localparam DIV = CLOCK_Frequency / Baud_Frequency / 16;		//分频比
//------------	
	reg [31:0]	Counter = 32'D0;						//分频计数器
	reg 			Baud_16X_Reg = 1'B0;					//输出缓存
	
	always @(posedge Clock)	begin
		if(DIV == 2)	begin
			Counter = Counter + 1'B1;
		end
		else	begin
			if(Counter == (DIV >> 1))	begin
				Baud_16X_Reg = 1'B1;
				Counter = Counter + 1'B1;
			end
			else if(Counter >= (DIV - 1))	begin
				Baud_16X_Reg = 1'B0;
				Counter = 32'D0;
			end
			else	begin
				Counter = Counter + 1'B1;
			end
		end
	end
	
	assign Baud16X = (DIV == 2) ? Counter[0] : Baud_16X_Reg;
	
endmodule
