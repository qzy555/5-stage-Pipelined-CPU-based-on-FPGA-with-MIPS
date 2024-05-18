`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/06 21:28:49
// Design Name: 
// Module Name: if_id
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

module IF_ID(
    input wire clk,
    input wire rst,
    
    input wire [`InstAddrBus] if_pc,
    input wire [`InstBus] if_inst,
    (*DONT_TOUCH = "1"*) input wire [5:0] stall,              //ctrl
    
    output reg [`InstAddrBus] id_pc,
    output reg [`InstBus] id_inst
    );
    
        always @ (posedge clk)
          begin
            if (rst == `RstEnable )           //有复位信号时，pc与inst为0
              begin
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;
              end
            else if(stall[1] == `Stop && stall[2] == `NoStop)
              begin
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;
              end
            else if(stall[1] == `NoStop)
              begin
                id_pc <= if_pc;                  //无复位信号时，pc与inst向下传递
                id_inst <= if_inst;
              end
          end
endmodule
