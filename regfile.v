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
        reg [`RegBus] regs[0:`RegNum-1];       //����32��32λ�Ĵ���
        
        always @ (posedge clk)                                    //д����
          begin
            if(rst == `RstDisable)                                //��λ�ź���Ч
              begin
                if((we == `WriteEnable)&&(waddr != `RegNumLog2'h0))    //дʹ����Ч��дĿ��Ĵ�����Ϊ0�Ĵ���     
                  begin
                    regs[waddr] <= wdata;
                  end
              end
          end
        
        always @ (*)                              //�˿�1�Ķ�����
          begin
            if (rst == `RstEnable )               //�и�λ�ź�ʱ�����0
              begin
                rdata1 <= `ZeroWord;
              end
            else if(raddr1 == `RegNumLog2'h0)     //����һ���Ĵ��������0
              begin
                rdata1 <= `ZeroWord;
              end
            else if((raddr1 == waddr)&&(we == `WriteEnable)&&(re1 == `ReadEnable))        //��д��ͬʱ����д��ֱֵ�������
              begin
                rdata1 <= wdata;
              end
            else if(re1 == `ReadEnable)             //�����������ֱ������üĴ����е�ֵ
              begin
                rdata1 <= regs [raddr1]; 
              end
            else
              begin
                rdata1 <= `ZeroWord;                  //������������0
              end
          end
          
        always @ (*)                              //�˿�1�Ķ�����
          begin
            if (rst == `RstEnable )               //�и�λ�ź�ʱ�����0
              begin
                rdata2 <= `ZeroWord;
              end
            else if(raddr2 == `RegNumLog2'h0)     //����һ���Ĵ��������0
              begin
                rdata2 <= `ZeroWord;
              end
            else if((raddr2 == waddr)&&(we == `WriteEnable)&&(re2 == `ReadEnable))        //��д��ͬʱ����д��ֱֵ�������
              begin
                rdata2 <= wdata;
              end
            else if(re2 == `ReadEnable)             //�����������ֱ������üĴ����е�ֵ
              begin
                rdata2 <= regs [raddr2];
              end
            else
              begin
                rdata2 <= `ZeroWord;                  //������������0
              end
          end
          
endmodule
