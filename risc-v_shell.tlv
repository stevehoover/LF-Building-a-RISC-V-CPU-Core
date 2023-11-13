\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/df57c0c25435c0ddac3555df620b4fc5bd535e30/lib/risc-v_shell_lib.tlv'])

\m5
   assemble_imem(['
      # /====================\
      # | Sum 1 to 9 Program |
      # \====================/
      #
      # Program to test RV32I
      # Add 1,2,3,...,9 (in that order).
      #
      # Regs:
      #  x12 (a2): 10
      #  x13 (a3): 1..10
      #  x14 (a4): Sum
      # 
      reset:
         ADDI x14, x0, 0          # Initialize sum register x14 with 0
         ADDI x12, x0, 10         # Store count of 10 in register x12.
         ADDI x13, x0, 1          # Initialize loop count register x13 to 1
      loop:
         ADD x14, x13, x14        # Incremental summation
         ADDI x13, x13, 1         # Increment loop count by 1
         BLT x13, x12, loop       # If a3 is less than a2, repeat
         ADDI x30, x14, -44       # Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
         BGE x0, x0, 0            # Done. Jump to itself (infinite loop).
   '])
\SV
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
   m5_my_defs
   /* verilator lint_on WIDTH */


   /**
   //---------------------------------------------------------------------------------
   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  x12 (a2): 10
   //  x13 (a3): 1..10
   //  x14 (a4): Sum
   // 
   m4_asm(ADDI, x14, x0, 0)             // Initialize sum register a4 with 0
   m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register a2.
   m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register a3 with 0
   // Loop:
   m4_asm(ADD, x14, x13, x14)           // Incremental summation
   m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   m4_asm(BLT, x13, x12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   // Test result value in x14, and set x31 to reflect pass/fail.
   m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
   m4_asm(BGE, x0, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_asm_end()
   m4_define(['M4_MAX_CYC'], 50)
   //---------------------------------------------------------------------------------
   **/


\TLV
   
   $reset = *reset;
   
   
   // YOUR CODE HERE
   // ...
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = 1'b0;
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   //m4+rf(32, 32, $reset, $wr_en, $wr_index[4:0], $wr_data[31:0], $rd1_en, $rd1_index[4:0], $rd1_data, $rd2_en, $rd2_index[4:0], $rd2_data)
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m5+cpu_viz()
\SV
   endmodule