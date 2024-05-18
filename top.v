`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/07 12:47:23
// Design Name: 
// Module Name: TOP
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

module TOP(
	input wire	clk,
	input wire	rst,
	
	(*DONT_TOUCH = "1"*) output wire a
    );
    
    //
    wire [`InstAddrBus] inst_addr;
    wire [`InstBus] inst;
    wire rom_ce;
    wire mem_we_i;
    wire [`RegBus] mem_addr_i;
    wire [`RegBus] mem_data_i;
    wire [`RegBus] mem_data_o;
    wire [3:0] mem_sel_i;
    wire ram_ce_o;
    
    //
    Mips Mips0(
    	.clk(clk),
		.rst(rst),
	
		.rom_addr_o(inst_addr),
		.rom_data_i(inst),
		
		.rom_ce_o(rom_ce),
		
		.ram_we_o(mem_we_i),
		.ram_addr_o(mem_addr_i),
		.ram_sel_o(mem_sel_i),
		.ram_data_o(mem_data_i),
		.ram_data_i(mem_data_o),
		.ram_ce_o(ram_ce_o)
    );
    
    ROM ROM0(
        .ce(rom_ce),
        .addr(inst_addr),
        .inst(inst)
    );
    
    RAM RAM0(
		.clk(clk),
		.ce(ram_ce_o),
		.we(mem_we_i),
		.addr(mem_addr_i),
		.sel(mem_sel_i),
		.data_i(mem_data_i),
		.data_o(mem_data_o)	
	);
endmodule
