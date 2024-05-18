`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/06 16:57:59
// Design Name: 
// Module Name: pc
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

module PC(
    input wire clk,
    input wire rst,
    
    //ctrl
    (*DONT_TOUCH = "1"*) input wire [5:0] stall,
    
    //来自ID阶段的信息
	input wire branch_flag_i,
	input wire[`RegBus] branch_target_address_i,
    
    output reg [`InstAddrBus] pc,
    output reg ce
    );
        
        always @ (posedge clk)
         begin
            if (rst == `RstEnable)           //有复位信号，使能无效
              begin
                ce <=  `ChipDisable;
              end 
            else                       //无复位信号，使能有效
              begin
                ce <=  `ChipEnable;            
              end
          end
          
        always @ (posedge clk)
          begin
            if (ce == `ChipDisable) 
              begin
                pc <= 32'h00000000;             //使能无效，pc维持0
              end
            else if(stall[0] == `NoStop)                     //使能有效，pc+4
              begin
              	if(branch_flag_i == `Branch) 
              	  begin
					pc <= branch_target_address_i;
				  end
				else
				begin
                  pc <= pc + 4'h4;
                end
              end
          end
          
endmodule
