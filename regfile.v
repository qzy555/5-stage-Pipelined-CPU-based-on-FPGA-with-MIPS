`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/06 21:44:45
// Design Name: 
// Module Name: regfile
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

module REGFILE(
    input wire clk,
    input wire rst,
    
    input wire re1,
    input wire [`RegAddrBus] raddr1,
    output reg [`RegBus] rdata1,
    
    input wire re2,
    input wire [`RegAddrBus] raddr2,
    output reg [`RegBus] rdata2,
    
     input wire we,
     input wire [`RegAddrBus] waddr,
     input wire [`RegBus] wdata   
    );
        reg [`RegBus] regs[0:`RegNum-1];       //定义32个32位寄存器
        
        always @ (posedge clk)                                    //写操作
          begin
            if(rst == `RstDisable)                                //复位信号无效
              begin
                if((we == `WriteEnable)&&(waddr != `RegNumLog2'h0))    //写使能有效且写目标寄存器不为0寄存器     
                  begin
                    regs[waddr] <= wdata;
                  end
              end
          end
        
        always @ (*)                              //端口1的读操作
          begin
            if (rst == `RstEnable )               //有复位信号时，输出0
              begin
                rdata1 <= `ZeroWord;
              end
            else if(raddr1 == `RegNumLog2'h0)     //读第一个寄存器，输出0
              begin
                rdata1 <= `ZeroWord;
              end
            else if((raddr1 == waddr)&&(we == `WriteEnable)&&(re1 == `ReadEnable))        //读写相同时，将写入值直接做输出
              begin
                rdata1 <= wdata;
              end
            else if(re1 == `ReadEnable)             //无特殊情况，直接输出该寄存器中的值
              begin
                rdata1 <= regs [raddr1]; 
              end
            else
              begin
                rdata1 <= `ZeroWord;                  //其他情况，输出0
              end
          end
          
        always @ (*)                              //端口1的读操作
          begin
            if (rst == `RstEnable )               //有复位信号时，输出0
              begin
                rdata2 <= `ZeroWord;
              end
            else if(raddr2 == `RegNumLog2'h0)     //读第一个寄存器，输出0
              begin
                rdata2 <= `ZeroWord;
              end
            else if((raddr2 == waddr)&&(we == `WriteEnable)&&(re2 == `ReadEnable))        //读写相同时，将写入值直接做输出
              begin
                rdata2 <= wdata;
              end
            else if(re2 == `ReadEnable)             //无特殊情况，直接输出该寄存器中的值
              begin
                rdata2 <= regs [raddr2];
              end
            else
              begin
                rdata2 <= `ZeroWord;                  //其他情况，输出0
              end
          end
          
endmodule
