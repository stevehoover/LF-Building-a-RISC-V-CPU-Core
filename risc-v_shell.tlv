\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/2d6d36baa4d2bc62321f982f78c8fe1456641a43/risc-v_defs.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])


                   
   //---------------------------------------------------------------------------------
   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  r12 (a2): 10
   //  r13 (a3): 1..10
   //  r14 (a4): Sum
   // 
   m4_asm(ADDI, r14, r0, 0)             // Initialize sum register a4 with 0
   m4_asm(ADDI, r12, r0, 1010)          // Store count of 10 in register a2.
   m4_asm(ADDI, r13, r0, 1)             // Initialize loop count register a3 with 0
   // Loop:
   m4_asm(ADD, r14, r13, r14)           // Incremental summation
   m4_asm(ADDI, r13, r13, 1)            // Increment loop count by 1
   m4_asm(BLT, r13, r12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   // Test result value in r14, and set r31 to reflect pass/fail.
   m4_asm(ADDI, r30, r14, 111111010100) // Subtract expected value of 44 to set r30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
   m4_asm(BGE, r0, r0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_asm_end()
   m4_define(['M4_MAX_CYC'], 50)
   //---------------------------------------------------------------------------------

                   

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   
   $reset = *reset;
   
   
   // YOUR CODE HERE
   // ...
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = 1'b0;
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   //m4+rf(32, 32, $reset, $wr_en, $wr_index, $wr_data, $rd1_en, $rd1_index, $rd1_data, $rd2_en, $rd2_index, $rd2_data)
   //m4+dmem(32, 32, $reset, $wr_en, $wr_addr, $wr_data, $rd_en, $rd_addr, $wr_data)
   m4+cpu_viz()
\SV
   endmodule