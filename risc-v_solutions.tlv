\m4_TLV_version 1d: tl-x.org
\SV

   // ==================================================
   // For use in the Building a RISC-V CPU Core Course.
   // Provides reference solutions without visibility to source code.
   // ==================================================
   
   // ----------------------------------
   // Instructions:
   //    - When stuck on a particular lab, select the lab at the bottom of this file,
   //      and compile/simulate.
   //    - A reference solution will build, but the source code will not be visible.
   //    - You may use waveforms, diagrams, and visualization to understand the proper circuit, but you
   //      will have to come up with the code. Logic expression syntax can be found by hovering over the
   //      signal assignment in the diagram.
   //    - Course updates can be found here: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core
   // ----------------------------------
   
   // Include solutions.
   m4_include_makerchip_hidden(['LF_workshop_solutions.private.tlv'])

\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   
   //=================\
   // Choose Your Lab |
   //=================/
   
   // Specify which lab you are on by providing a macro argument...
   m4+solution(START)
   // ...from these:
   // Chapter 4:
   //    START, PC, IMEM, INSTR_TYPE, FIELDS, IMM, SUBSET_INSTRS,
   //    RF_MACRO, RF_READ, SUBSET_ALU, RF_WRITE, TAKEN_BR, BR_REDIR, TB,
   // Chapter 5:
   //    TEST_PROG, ALL_INSTRS, FULL_ALU, JUMP, LD_ST_ADDR, DMEM, LD_DATA, DONE
   
   
\SV
   endmodule
