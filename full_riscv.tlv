\m4_TLV_version 1d: tl-x.org
\SV
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/2d6d36baa4d2bc62321f982f78c8fe1456641a43/risc-v_defs.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])
\SV
   m4_makerchip_module  // (Expanded in Nav-TLV pane.)
   
\TLV

   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program for MYTH Workshop to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  r10 (a0): In: 0, Out: final sum
   //  r12 (a2): 10
   //  r13 (a3): 1..10
   //  r14 (a4): Sum
   // 
   // External to function:
   m4_asm(ADD, r10, r0, r0)             // Initialize r10 (a0) to 0.
   // Function:
   m4_asm(ADD, r14, r10, r0)            // Initialize sum register a4 with 0x0
   m4_asm(ADDI, r12, r10, 1010)         // Store count of 10 in register a2.
   m4_asm(ADD, r13, r10, r0)            // Initialize intermediate sum register a3 with 0
   // Loop:
   m4_asm(ADD, r14, r13, r14)           // Incremental addition
   m4_asm(ADDI, r13, r13, 1)            // Increment intermediate register by 1
   m4_asm(BLT, r13, r12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   m4_asm(ADD, r10, r14, r0)            // Store final result to register a0 so that it can be read by main program
   m4_asm(ADDI, r1, r0, 101)
   m4_asm(ORI, r6, r0, 0)
   m4_asm(SW, r6, r1, 0)
   m4_asm(LW, r4, r6, 0)
   // Optional:
   m4_asm(JAL, r7, 11111111111111101000) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_asm_end()
   
   //1 - PC
   $reset = *reset;
   $next_pc[31:0] =  $reset    ? '0              :
                     $taken_br ? $br_tgt_pc   :  //9
                     $is_jal   ? $br_tgt_pc   :  // 13
                     $is_jalr  ? $jalr_tgt_pc :  // 13
                     $pc + 32'd4 ;
   $pc[31:0] = >>1$next_pc;
   
   //2 - IMEM - Read
   `READONLY_MEM($pc, $$instr[31:0])
   
   //3 - Decode Logic - RISBUJ
   $is_i_instr = $instr[6:2] ==? 5'b0000x ||
                 $instr[6:2] ==? 5'b001x0 ||
                 $instr[6:2] ==? 5'b11001 ;
   
   $is_r_instr = $instr[6:2] ==? 5'b01011 ||
                 $instr[6:2] ==? 5'b011x0 ||
                 $instr[6:2] ==? 5'b10100 ;
   
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   
   $is_b_instr = $instr[6:2] ==? 5'b11000;
   
   $is_j_instr = $instr[6:2] ==? 5'b11011;
   
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   
   //4 - Instr Fields
   $funct7[6:0]   =  $instr[31:25];
   $funct3[2:0]   =  $instr[14:12];
   $rs1[4:0]      =  $instr[19:15];
   $rs2[4:0]      =  $instr[24:20];
   $rd[4:0]       =  $instr[11:7];
   $opcode[6:0]   =  $instr[6:0];
   `BOGUS_USE($funct7 $funct3 $rs1 $rs2 $rd $opcode)
   
   $funct7_valid  =  $is_r_instr;
   $funct3_valid  =  $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs1_valid     =  $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs2_valid     =  $is_r_instr || $is_s_instr || $is_b_instr ;
   $rd_valid      =  $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   $imm_valid     =  $is_i_instr || $is_s_instr || $is_b_instr || $is_u_instr || $is_j_instr;
   `BOGUS_USE($funct7_valid $funct3_valid $rs1_valid $rs2_valid $rd_valid $imm_valid)
   
   //5 - Imm 
   $imm[31:0]  =  $is_i_instr ?  {{21{$instr[31]}}, $instr[30:20]}                                  :
                  $is_s_instr ?  {{21{$instr[31]}}, $instr[30:25], $instr[11:7]}                    :
                  $is_b_instr ?  {{20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0}   :
                  $is_u_instr ?  {$instr[31:12], 12'b0}                                             :
                  $is_j_instr ?  {{12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0} :
                                 32'b0 ;
   `BOGUS_USE($imm)
   
   //6 - Decode Instr Name
   $dec_bits[10:0]   =  {$funct7[5], $funct3, $opcode};
   $is_beq           =  $dec_bits ==? 11'bx_000_1100011;
   $is_bne           =  $dec_bits ==? 11'bx_001_1100011;
   $is_blt           =  $dec_bits ==? 11'bx_100_1100011;
   $is_bge           =  $dec_bits ==? 11'bx_101_1100011;
   $is_bltu          =  $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu          =  $dec_bits ==? 11'bx_111_1100011;
   
   $is_addi          =  $dec_bits ==? 11'bx_000_0010011;
   $is_add           =  $dec_bits ==? 11'b0_000_0110011;
   `BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add)
   
   //7 - RF Read
   //$rf_rd_en1           =   $rs1_valid;
   //$rf_rd_index1[4:0]   =   $rs1;
   //$src1_value[31:0]    =   $rf_rd_data1;
   
   //$rf_rd_en2           =   $rs2_valid;
   //$rf_rd_index2[4:0]   =   $rs2;
   //$src2_value[31:0]    =   $rf_rd_data2;
   
   //`BOGUS_USE($src1_value $src2_value)
   
   //8 - ALU
   //$result[31:0] =   $is_addi ?  $src1_value + $imm :
   //                  $is_add  ?  $src1_value + $src2_value :
   //                              32'bx;
   //$rf_wr_en            =     $rd_valid && ($rd != 5'b0);
   //$rf_wr_index[4:0]    =     $rd;
   //$rf_wr_data[31:0]    =     $is_load ? $ld_data : $result; // 14
   
   //9- Branch
   $taken_br   =  $is_beq  ?  ($src1_value == $src2_value) :
                  $is_bne  ?  ($src1_value != $src2_value) :
                  $is_blt  ?  (($src1_value < $src2_value)  ^ ($src1_value[31] != $src2_value[31])) :
                  $is_bge  ?  (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
                  $is_bltu ?  ($src1_value < $src2_value)  :
                  $is_bgeu ?  ($src1_value >= $src2_value) :
                              1'b0;
   
   $br_tgt_pc[31:0]  =  $pc + $imm;
   
   // 10 - Stop
   //*passed = |cpu/xreg[10]>>5$value == (1+2+3+4+5+6+7+8+9);
   
   //11
   $is_lui     =  $dec_bits ==? 11'bx_xxx_0110111 ;
   $is_auipc   =  $dec_bits ==? 11'bx_xxx_0010111 ;
   $is_jal     =  $dec_bits ==? 11'bx_xxx_1101111 ;
   $is_jalr    =  $dec_bits ==? 11'bx_000_1100111 ;
   
   $is_load    =  $opcode   ==  7'b0000011        ;
   
   $is_sb      =  $dec_bits ==? 11'bx_000_0100011 ;
   $is_sh      =  $dec_bits ==? 11'bx_001_0100011 ;
   $is_sw      =  $dec_bits ==? 11'bx_010_0100011 ;
   
   $is_slti    =  $dec_bits ==? 11'bx_010_0010011 ;
   
   //12
   $result[31:0]  =     $is_addi || $is_load || $is_s_instr ?  $src1_value + $imm : // 14
                        $is_add     ?  $src1_value + $src2_value :
                        $is_lui     ?  {$imm[31:12], 12'b0} :
                        $is_auipc   ?  $pc + $imm :
                        $is_jal     ?  $pc + 32'd4 :
                        $is_jalr    ?  $pc + 32'd4 :
                        $is_slti    ?  (($src1_value[31] == $imm[31]) ? $src1_value < $imm : {31'b0, $src1_value[31]}) :
                                       32'bx;
   //13
   $is_jump             =  $is_jal || $is_jalr;
   $jalr_tgt_pc[31:0]   =  $src1_value + $imm;
   
   
   //14
   //$dmem_wr_en          =   $is_s_instr;
   //$dmem_rd_en1         =   $is_load;
   //$dmem_rd_index1[4:0] =   $result[6:2];
   //$dmem_wr_index[4:0]  =   $result[6:2];
   //$dmem_wr_data[31:0]  =   $src2_value;
   //$ld_data[31:0]       =   $dmem_rd_data1;
   
   //*passed = |cpu/xreg[4]>>5$value == 0;
      // YOUR CODE HERE
      // ...
   
      // Note: Because of the magic we are using for visualisation, if visualisation is enabled below,
      //       be sure to avoid having unassigned signals (which you might be using for random inputs)
      //       other than those specifically expected in the labs. You'll get strange errors for these.
   
   
   // Assert these to end simula/toption (before Makerchip cycle limit).
   *passed = *cyc_cnt > 50;
   *failed = 1'b0;
   
   // Macro instantiations for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   //|cpu
   m4+rf(32, 32, $reset, $rd_valid && ($rd != 5'b0), $rd, $is_load ? $ld_data : $result, $rs1_valid, $rs1, $src1_value[31:0], $rs2_valid, $rs2, $src2_value[31:0])
   //m4+rf(32, 32, $reset, $rd_valid && ($rd != 5'b0), $rd, $result, $rs1_valid, $rs1, $src1_value[31:0], $rs2_valid, $rs2, $src2_value[31:0])
   m4+dmem(32, 32, $reset, $is_s_instr, $result[6:2], $src2_value, $is_load, $result[6:2], $ld_data[31:0])
   
   m4+cpu_viz()
\SV
   endmodule
