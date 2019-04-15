`timescale 1 ps/ 1 ps
module Digtal_Main_vlg_tst();
// constants                                           
// general purpose registers
reg eachvec;
// test vector input registers
reg CLOCK_Digtal;
reg CS;
reg [7:0] RAM_Q;
reg [7:0] Rx_Data;
// wires                                               
wire [7:0]  Out_Data;
wire [7:0]  RAM_Data_In;
wire [30:0]  RAM_RDADD;
wire RAM_RDEN;
wire [30:0]  RAM_WRADD;
wire RAM_WREN;





reg [31:0]	DIV_BAUD;
reg [7:0]	RD_Counter;
reg RD_n;
reg [7:0]	CS_Div;
wire BAUD;
wire RD;
// assign statements (if any)                          
Digtal_Main i1 (
// port map - connection between master ports and signals/registers   
	.CLOCK_Digtal(CLOCK_Digtal),
	.CS(CS),
	.Out_Data(Out_Data),
	.RAM_Data_In(RAM_Data_In),
	.RAM_Q(RAM_Q),
	.RAM_RDADD(RAM_RDADD),
	.RAM_RDEN(RAM_RDEN),
	.RAM_WRADD(RAM_WRADD),
	.RAM_WREN(RAM_WREN),
	.RD(RD),
	.Rx_Data(Rx_Data)
);
initial                                                
begin                                                  
// code that executes only once                        
// insert code here --> begin                          
   CLOCK_Digtal = 1'B0;    
	CS = 1'B0;	
	RAM_Q = 8'H00;	
	RD_n = 1'B0;
	Rx_Data = 8'H00;
	
	
	DIV_BAUD = 8'D0;
	RD_Counter = 8'D0;
	CS_Div = 8'D0;
// --> end                                             
$display("Running testbench");                       
end   
//仿真CLOCK_Digtal                                                 
always begin
	#1 CLOCK_Digtal = ~CLOCK_Digtal;
end  
//对CLOCK_Digtal分频，输出RD数据
always @(posedge CLOCK_Digtal)	begin
	DIV_BAUD = DIV_BAUD + 1'B1;
	RD_n = DIV_BAUD[6];
end
always @(posedge RD_n)	begin
	RD_Counter = RD_Counter + 1'B1;
	if(RD_Counter == 8'D0)	begin
		Rx_Data	= 8'HEB;
	end
	else	if(RD_Counter == 8'D1)	begin
		Rx_Data	= 8'H90;
	end
	else	if(RD_Counter == 8'D2)	begin
		Rx_Data	= 8'H90;
	end
	else	if(RD_Counter == 8'D3)	begin
		Rx_Data	= 8'HEB;
	end
	else	begin
		Rx_Data = RD_Counter;
	end
end

assign RD = (RD_Counter<70) ? RD_n : 1'B0;

//仿真CS
always @(posedge CLOCK_Digtal)	begin
	CS_Div = CS_Div + 1;
	if(CS_Div == 32)	
		CS = 1'B1;
	else if(CS_Div == 96)	
		CS = 1'B0;
	else
		CS = CS;
end



                                                
endmodule

