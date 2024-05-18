`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/07 13:24:55
// Design Name: 
// Module Name: top_tb
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

module top_tb();
  
  reg CLOCK_50;
  reg rst;
  wire a;
  
  initial
    begin
      CLOCK_50 = 1'b0;
      forever #10 CLOCK_50 = ~CLOCK_50;
    end
    
  initial
    begin
      rst = `RstEnable;
      #195 rst = `RstDisable;
      #1000 $stop;
    end
    
    TOP TOP0(
        .clk(CLOCK_50),
        .rst(rst),
        
        .a(a)
    );
endmodule
