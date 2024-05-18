`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/06 17:54:18
// Design Name: 
// Module Name: rom
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module ROM(
//	input wire clk,
	input wire	ce,
	(*DONT_TOUCH = "1"*) input wire [`InstAddrBus] addr,
	output reg [`InstBus] inst
    );
    
	reg[`InstBus]  inst_mem[0:`InstMemNum-1];

	initial
	begin 
	$readmemh ( "D:/CPU/mips-8/mips-8.src/inst_rom.data", inst_mem );
    end
    
	always @ (*) begin
		if (ce == `ChipDisable) begin
			inst <= `ZeroWord;
	  end else begin
		  inst <= inst_mem [addr[`InstMemNumLog2+1:2]];
		end
	end
	
endmodule
