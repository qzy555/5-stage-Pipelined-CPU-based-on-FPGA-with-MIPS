`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/09 17:09:09
// Design Name: 
// Module Name: RAM
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


module RAM(
    input wire clk,
	input wire	ce,
	input wire	we,
	(*DONT_TOUCH = "1"*) input wire [`DataAddrBus] addr,
	input wire [3:0] sel,
	input wire [`DataBus] data_i,
	output reg [`DataBus] data_o
    );
      reg [`ByteWidth]  data_mem0 [0:1024-1];
	  reg [`ByteWidth]  data_mem1 [0:1024-1];
	  reg [`ByteWidth]  data_mem2 [0:1024-1];
	  reg [`ByteWidth]  data_mem3 [0:1024-1];
	  
	  initial $readmemh ( "D:/CPU/mips-8/mips-8.src/ram_init0.dat", data_mem0);
      initial $readmemh ( "D:/CPU/mips-8/mips-8.src/ram_init1.dat", data_mem1);
      initial $readmemh ( "D:/CPU/mips-8/mips-8.src/ram_init2.dat", data_mem2);
      initial $readmemh ( "D:/CPU/mips-8/mips-8.src/ram_init3.dat", data_mem3);
	  
	  always @ (posedge clk) 
	    begin
		  if (ce == `ChipDisable) 
		    begin
			  //data_o <= ZeroWord;
		    end 
		  else if(we == `WriteEnable) 
		    begin
			  if (sel[3] == 1'b1) 
			    begin
		          data_mem3[addr[`DataMemNumLog2+1:2]] <= data_i[31:24];
		        end
			  if (sel[2] == 1'b1) 
			    begin
		          data_mem2[addr[`DataMemNumLog2+1:2]] <= data_i[23:16];
		        end
		      if (sel[1] == 1'b1) 
		        begin
		          data_mem1[addr[`DataMemNumLog2+1:2]] <= data_i[15:8];
		        end
			  if (sel[0] == 1'b1) 
			    begin
		          data_mem0[addr[`DataMemNumLog2+1:2]] <= data_i[7:0];
		        end			   	    
		    end
	    end
	    
	    always @ (*) 
	      begin
		    if (ce == `ChipDisable) 
		      begin
			    data_o <= `ZeroWord;
	          end 
	        else if(we == `WriteDisable) 
	          begin
		        data_o <= {data_mem3[addr[`DataMemNumLog2+1:2]],
		                   data_mem2[addr[`DataMemNumLog2+1:2]],
		                   data_mem1[addr[`DataMemNumLog2+1:2]],
		                   data_mem0[addr[`DataMemNumLog2+1:2]]};
		      end 
		    else 
		      begin
				data_o <= `ZeroWord;
		      end
	      end		
	  
endmodule
