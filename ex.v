`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/07 00:00:50
// Design Name: 
// Module Name: ex
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

module EX(
	input wire	rst,
	
	//上一级id_ex输入
	input wire [`AluOpBus] aluop_i,
	input wire [`AluSelBus] alusel_i,
	input wire [`RegBus] reg1_i,
	input wire [`RegBus] reg2_i,
	input wire [`RegAddrBus] wd_i,
	input wire wreg_i,
	
	//输出至下一级ex_mem
	output reg [`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg [`RegBus] wdata_o,
	
	//HI、LO寄存器的值
	input wire [`RegBus] hi_i,
	input wire [`RegBus] lo_i,
	
	//回写阶段的指令是否要写HI、LO，用于检测HI、LO的数据相关
	input wire [`RegBus]  wb_hi_i,
	input wire [`RegBus]  wb_lo_i,
	input wire wb_whilo_i,
	
	//访存阶段的指令是否要写HI、LO，用于检测HI、LO的数据相关
	input wire [`RegBus] mem_hi_i,
	input wire [`RegBus] mem_lo_i,
	input wire mem_whilo_i,
	
	//处于执行阶段的指令对HI,LO寄存器的写操作请求
	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o,
	output reg                    whilo_o,
	
	//ctrl
	output reg stallreq,
	
	//执行阶段的转移指令的返回地址
	input wire [`RegBus] link_address_i,
	//当前执行阶段的指令是否位于延迟槽
	(*DONT_TOUCH = "1"*) input wire is_in_delayslot_i,
	
	//除法输入
	input wire [`DoubleRegBus]     div_result_i,
	input wire                    div_ready_i,
	
	//到除法的输出
	output reg [`RegBus] div_opdata1_o,
	output reg [`RegBus] div_opdata2_o,
	output reg  div_start_o,
	output reg  signed_div_o,
	
	//
	(*DONT_TOUCH = "1"*) input wire [`RegBus] inst_i,
	output wire[`AluOpBus]        aluop_o,
	output wire[`RegBus]          mem_addr_o,
	output wire[`RegBus]          reg2_o
    );
       //保存逻辑运算结果
	  reg [`RegBus] logicout;
	  //保存移位运算结果
	  reg [`RegBus] shiftres;
	  //保存移动运算结果
	  reg [`RegBus] moveres;
	  //保存HI寄存器值
	  reg [`RegBus] HI;
	  //保存LO寄存器值
	  reg [`RegBus] LO;
	  
	  wire ov_sum;
	  wire reg1_eq_reg2;
	  wire reg1_lt_reg2;
	  reg [`RegBus] arithmeticres;
	  wire [`RegBus] reg2_i_mux;
	  wire [`RegBus] reg1_i_mux;                            //第一个操作数取反的值
	  wire[`RegBus] result_sum;
	  wire[`RegBus] opdata1_mult;
	  wire[`RegBus] opdata2_mult;
	  wire[`DoubleRegBus] hilo_temp;
	  reg[`DoubleRegBus] mulres;
	  reg stallreq_for_div;
	  reg stallreq_for_madd_msub;
	  
	  
	    //aluop_o传递到访存阶段，用于加载、存储指令
        assign aluop_o = aluop_i;
  
        //mem_addr传递到访存阶段，是加载、存储指令对应的存储器地址
        assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};

        //将两个操作数也传递到访存阶段，也是为记载、存储指令准备的
        assign reg2_o = reg2_i;
	  
	  	always @ (*)                                       //执行运算
	  	  begin
		    if(rst == `RstEnable) 
		      begin
			    logicout <= `ZeroWord;
		      end 
		    else 
		      begin
			     case (aluop_i)
				   `EXE_OR_OP:			
				      begin
					    logicout <= reg1_i | reg2_i;
				      end
				    `EXE_AND_OP:			
				      begin
					    logicout <= reg1_i & reg2_i;
				      end
				    `EXE_NOR_OP:			
				      begin
					    logicout <= ~(reg1_i | reg2_i);
				      end
				    `EXE_XOR_OP:			
				      begin
					    logicout <= reg1_i ^ reg2_i;
				      end
				    default:				
				      begin
					    logicout <= `ZeroWord;
				      end
			     endcase
		      end    //if
	  	  end        //always
	  	  
	  	always @ (*) 
	  	  begin
		    if(rst == `RstEnable) 
		      begin
			    shiftres <= `ZeroWord;
		      end 
		    else 
		      begin
			    case (aluop_i)
				  `EXE_SLL_OP:			
				    begin
					  shiftres <= reg2_i << reg1_i[4:0] ;
				    end
				  `EXE_SRL_OP:		
				    begin
					  shiftres <= reg2_i >> reg1_i[4:0];
				    end
				  `EXE_SRA_OP:		
				    begin
					  shiftres <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) | reg2_i >> reg1_i[4:0];
				    end
				  default:				
				    begin
					  shiftres <= `ZeroWord;
				    end
			     endcase
		      end    //if
	  	  end      //always
	  	  
	  	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) || (aluop_i == `EXE_SLT_OP)) ? (~reg2_i)+1 : reg2_i;

	    assign result_sum = reg1_i + reg2_i_mux;										 

	    assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));  
									
	    assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ?((reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && result_sum[31])||(reg1_i[31] && reg2_i[31] && result_sum[31])):(reg1_i < reg2_i);
  
        assign reg1_i_mux = ~reg1_i;
          
							
	      always @ (*) 
	        begin
		      if(rst == `RstEnable) 
		        begin
			      arithmeticres <= `ZeroWord;
		        end 
		      else 
		        begin
			      case (aluop_i)
				    `EXE_SLT_OP, `EXE_SLTU_OP:		
				      begin
					    arithmeticres <= reg1_lt_reg2 ;
				      end
				    `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP:		
				      begin
					    arithmeticres <= result_sum; 
				      end
				    `EXE_SUB_OP, `EXE_SUBU_OP:		
				      begin
					    arithmeticres <= result_sum; 
				      end		
				    `EXE_CLZ_OP:		
				      begin
					    arithmeticres <= reg1_i[31] ? 0 : reg1_i[30] ? 1 : reg1_i[29] ? 2 :
													 reg1_i[28] ? 3 : reg1_i[27] ? 4 : reg1_i[26] ? 5 :
													 reg1_i[25] ? 6 : reg1_i[24] ? 7 : reg1_i[23] ? 8 : 
													 reg1_i[22] ? 9 : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
													 reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 : 
													 reg1_i[16] ? 15 : reg1_i[15] ? 16 : reg1_i[14] ? 17 : 
													 reg1_i[13] ? 18 : reg1_i[12] ? 19 : reg1_i[11] ? 20 :
													 reg1_i[10] ? 21 : reg1_i[9] ? 22 : reg1_i[8] ? 23 : 
													 reg1_i[7] ? 24 : reg1_i[6] ? 25 : reg1_i[5] ? 26 : 
													 reg1_i[4] ? 27 : reg1_i[3] ? 28 : reg1_i[2] ? 29 : 
													 reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32 ;
				      end
				    `EXE_CLO_OP:		
				      begin
					    arithmeticres <= (reg1_i_mux[31] ? 0 : reg1_i_mux[30] ? 1 : reg1_i_mux[29] ? 2 :
													 reg1_i_mux[28] ? 3 : reg1_i_mux[27] ? 4 : reg1_i_mux[26] ? 5 :
													 reg1_i_mux[25] ? 6 : reg1_i_mux[24] ? 7 : reg1_i_mux[23] ? 8 : 
													 reg1_i_mux[22] ? 9 : reg1_i_mux[21] ? 10 : reg1_i_mux[20] ? 11 :
													 reg1_i_mux[19] ? 12 : reg1_i_mux[18] ? 13 : reg1_i_mux[17] ? 14 : 
													 reg1_i_mux[16] ? 15 : reg1_i_mux[15] ? 16 : reg1_i_mux[14] ? 17 : 
													 reg1_i_mux[13] ? 18 : reg1_i_mux[12] ? 19 : reg1_i_mux[11] ? 20 :
													 reg1_i_mux[10] ? 21 : reg1_i_mux[9] ? 22 : reg1_i_mux[8] ? 23 : 
													 reg1_i_mux[7] ? 24 : reg1_i_mux[6] ? 25 : reg1_i_mux[5] ? 26 : 
													 reg1_i_mux[4] ? 27 : reg1_i_mux[3] ? 28 : reg1_i_mux[2] ? 29 : 
													 reg1_i_mux[1] ? 30 : reg1_i_mux[0] ? 31 : 32) ;
				      end
				    default:				
				      begin
					    arithmeticres <= `ZeroWord;
				      end
			      endcase
		        end
	        end

	  	 //取得乘法操作的操作数，如果是有符号除法且操作数是负数，那么取反加一
        assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) )&& (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;

        assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) )&& (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;		

        assign hilo_temp = opdata1_mult * opdata2_mult;																				

          always @ (*) 
            begin
              if(rst == `RstEnable) 
                begin
			      mulres <= {`ZeroWord,`ZeroWord};
		        end 
		      else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP))
				begin
			      if(reg1_i[31] ^ reg2_i[31] == 1'b1) 
			        begin
				      mulres <= ~hilo_temp + 1;
			        end 
			      else 
			        begin
			          mulres <= hilo_temp;
			        end
				end 
			  else 
			    begin
				  mulres <= hilo_temp;
		        end
            end
	  	  
	  	  
	  	always @ (*)                                           //给出最总结果（是否写入寄存器等）
	  	  begin
	  	    wd_o <= wd_i;
	  	    
	  	    //发生溢出，不写
	  	    if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) 
	          begin
	 	        wreg_o <= `WriteDisable;
	          end 
	        else 
	          begin
	            wreg_o <= wreg_i;
	          end
	  	    
	  	    case ( alusel_i )
	  	      `EXE_RES_LOGIC:
	  	        begin
	  	          wdata_o <= logicout;
	  	        end
	  	      `EXE_RES_SHIFT:
	  	        begin
	  	          wdata_o <= shiftres;
	  	        end
	  	      `EXE_RES_MOVE:		
	  	        begin
	 		      wdata_o <= moveres;
	 	        end
	 	      `EXE_RES_ARITHMETIC:	
	 	        begin
	 		      wdata_o <= arithmeticres;
	 	        end
	 	      `EXE_RES_MUL:		
	 	        begin
	 		      wdata_o <= mulres[31:0];
	 	        end
	 	      `EXE_RES_JUMP_BRANCH:		
	 	        begin
	 		      wdata_o <= link_address_i;
	 	        end
	  	      default:
	  	        begin
	  	          wdata_o <= `ZeroWord;
	  	        end
	  	     endcase
	  	  end	  	        
	    
	     //得到最新的HI、LO寄存器的值，此处要解决指令数据相关问题
	    always @ (*) 
	      begin
		    if(rst == `RstEnable) 
		      begin
			    {HI,LO} <= {`ZeroWord,`ZeroWord};
		      end 
		    else if(mem_whilo_i == `WriteEnable) 
		      begin
			   {HI,LO} <= {mem_hi_i,mem_lo_i};
		      end 
		    else if(wb_whilo_i == `WriteEnable)
		      begin
			    {HI,LO} <= {wb_hi_i,wb_lo_i};
		      end 
		    else 
		      begin
			    {HI,LO} <= {hi_i,lo_i};			
		      end
	      end	
        //MFHI、MFLO、MOVN、MOVZ指令
	    always @ (*) 
	      begin
		    if(rst == `RstEnable) 
		      begin
	  	        moveres <= `ZeroWord;
	          end 
	        else 
	          begin
	            moveres <= `ZeroWord;
	            case (aluop_i)
	   	          `EXE_MFHI_OP:		
	   	            begin
	   		          moveres <= HI;
	            	end
	           	  `EXE_MFLO_OP:		
	           	    begin
	   	    	      moveres <= LO;
	   	            end
	   	          `EXE_MOVZ_OP:		
	   	            begin
	   		          moveres <= reg1_i;
	   	            end
	   	          `EXE_MOVN_OP:		
	   	            begin
	   		          moveres <= reg1_i;
	   	            end
	   	          default : 
	   	            begin
	   	            end
	            endcase
	         end
	      end
	      
	    always @ (*) 
	      begin
		    if(rst == `RstEnable) 
		      begin
			    whilo_o <= `WriteDisable;
			    hi_o <= `ZeroWord;
			    lo_o <= `ZeroWord;
		      end 
            else if((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP)) 
              begin
			    whilo_o <= `WriteEnable;
			    hi_o <= mulres[63:32];
			    lo_o <= mulres[31:0];
			  end
		    else if(aluop_i == `EXE_MTHI_OP) 
		      begin
			    whilo_o <= `WriteEnable;
			    hi_o <= reg1_i;
			    lo_o <= LO;
		      end
		    else if((aluop_i == `EXE_DIV_OP) || (aluop_i == `EXE_DIVU_OP)) 
		      begin
			    whilo_o <= `WriteEnable;
			    hi_o <= div_result_i[63:32];
			    lo_o <= div_result_i[31:0];			
		      end 
		    else if(aluop_i == `EXE_MTLO_OP) 
		      begin
			    whilo_o <= `WriteEnable;
			    hi_o <= HI;
			    lo_o <= reg1_i;
		      end 
		    else 
		      begin
			    whilo_o <= `WriteDisable;
			    hi_o <= `ZeroWord;
			    lo_o <= `ZeroWord;
		      end				
	      end			
          //DIV、DIVU指令	
		      always @ (*) 
		        begin
			      if(rst == `RstEnable) 
			        begin
				      stallreq_for_div <= `NoStop;
	    	          div_opdata1_o <= `ZeroWord;
				      div_opdata2_o <= `ZeroWord;
				      div_start_o <= `DivStop;
				      signed_div_o <= 1'b0;
			        end 
			      else 
			        begin
				      stallreq_for_div <= `NoStop;
	   	              div_opdata1_o <= `ZeroWord;
			      	  div_opdata2_o <= `ZeroWord;
				      div_start_o <= `DivStop;
				      signed_div_o <= 1'b0;	
			      	  case (aluop_i) 
					    `EXE_DIV_OP:		
					      begin
					      	if(div_ready_i == `DivResultNotReady) 
					      	  begin
	    			      	    div_opdata1_o <= reg1_i;
						      	div_opdata2_o <= reg2_i;
						      	div_start_o <= `DivStart;
						      	signed_div_o <= 1'b1;
						      	stallreq_for_div <= `Stop;
					      	  end 
					      	else if(div_ready_i == `DivResultReady) 
					      	  begin
	    				        div_opdata1_o <= reg1_i;
						      	div_opdata2_o <= reg2_i;
						      	div_start_o <= `DivStop;
						      	signed_div_o <= 1'b1;
							    stallreq_for_div <= `NoStop;
						        end 
						      else 
						        begin						
	    				          div_opdata1_o <= `ZeroWord;
						      	  div_opdata2_o <= `ZeroWord;
						      	  div_start_o <= `DivStop;
						      	  signed_div_o <= 1'b0;
							      stallreq_for_div <= `NoStop;
						        end					
					      end
					    `EXE_DIVU_OP:		
					      begin
						    if(div_ready_i == `DivResultNotReady) 
						      begin
	    				        div_opdata1_o <= reg1_i;
						      	div_opdata2_o <= reg2_i;
						      	div_start_o <= `DivStart;
						      	signed_div_o <= 1'b0;
						      	stallreq_for_div <= `Stop;
						      end 
						    else if(div_ready_i == `DivResultReady) 
						      begin
	    				        div_opdata1_o <= reg1_i;
						      	div_opdata2_o <= reg2_i;
						      	div_start_o <= `DivStop;
						      	signed_div_o <= 1'b0;
						      	stallreq_for_div <= `NoStop;
						      end 
						    else 
						      begin						
	    			      	    div_opdata1_o <= `ZeroWord;
						      	div_opdata2_o <= `ZeroWord;
						      	div_start_o <= `DivStop;
						      	signed_div_o <= 1'b0;
						        stallreq_for_div <= `NoStop;
						      end					
					      end
					      default: begin
					      end
				      endcase
			      end
		      end
		    always @ (*) 
		      begin
                stallreq = stallreq_for_madd_msub || stallreq_for_div;
              end	
	      
endmodule
