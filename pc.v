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
    
    //����ID�׶ε���Ϣ
	input wire branch_flag_i,
	input wire[`RegBus] branch_target_address_i,
    
    output reg [`InstAddrBus] pc,
    output reg ce
    );
        
        always @ (posedge clk)
         begin
            if (rst == `RstEnable)           //�и�λ�źţ�ʹ����Ч
              begin
                ce <=  `ChipDisable;
              end 
            else                       //�޸�λ�źţ�ʹ����Ч
              begin
                ce <=  `ChipEnable;            
              end
          end
          
        always @ (posedge clk)
          begin
            if (ce == `ChipDisable) 
              begin
                pc <= 32'h00000000;             //ʹ����Ч��pcά��0
              end
            else if(stall[0] == `NoStop)                     //ʹ����Ч��pc+4
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
