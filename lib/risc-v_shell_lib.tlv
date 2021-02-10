\m4_TLV_version 1d: tl-x.org
\SV
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/2d6d36baa4d2bc62321f982f78c8fe1456641a43/risc-v_defs.tlv'])

// v====================== lib/risc-v_shell_lib.tlv =======================v

// Configuration for WARP-V definitions.
m4+definitions(['
   m4_define_vector(['M4_WORD'], 32)
   m4_define(['M4_EXT_I'], 1)
   
   m4_define(['M4_NUM_INSTRS'], 0)
   
   m4_echo(m4tlv_riscv_gen__body())
   
   // A single-line M4 macro instantiated at the end of the asm code.
   // It actually produces a definition of an SV macro that instantiates the IMem conaining the program (that can be parsed without \SV_plus). 
   m4_define(['m4_asm_end'], ['`define READONLY_MEM(ADDR, DATA) assign DATA \= instrs[ADDR[\$clog2(\$size(instrs)) + 1 : 2]]; logic [31:0] instrs [0:M4_NUM_INSTRS-1]; assign instrs \= '{m4_instr0['']m4_forloop(['m4_instr_ind'], 1, M4_NUM_INSTRS, [', m4_echo(['m4_instr']m4_instr_ind)'])};'])
'])


// Register File
\TLV rf(_entries, _width, $_reset, $_port1_en, $_port1_index, $_port1_data, $_port2_en, $_port2_index, $_port2_data, $_port3_en, $_port3_index, $_port3_data)
   $rf_wr_en = m4_argn(4, $@);
   $rf_wr_index[\$clog2(_entries)-1:0]  = m4_argn(5, $@);
   $rf_wr_data[_width-1:0] = m4_argn(6, $@);
   
   $rf_rd_en1 = m4_argn(7, $@);
   $rf_rd_index1[\$clog2(_entries)-1:0] = m4_argn(8, $@);
   
   $rf_rd_en2 = m4_argn(10, $@);
   $rf_rd_index2[\$clog2(_entries)-1:0] = m4_argn(11, $@);
   
   /xreg[_entries-1:0]
      <<1$value[_width-1:0]   =  /top$_reset   ? #xreg              :
                                 /top$rf_wr_en && (/top$rf_wr_index == #xreg)
                                               ? /top$rf_wr_data :
                                                 $RETAIN;
   
   $_port2_data[_width-1:0]  =  $rf_rd_en1 ? /xreg[$rf_rd_index1]$value : 'X;
   $_port3_data[_width-1:0]  =  $rf_rd_en2 ? /xreg[$rf_rd_index2]$value : 'X;

// Data Memory
\TLV dmem(_entries, _width, $_reset, $_port1_en, $_port1_index, $_port1_data, $_port2_en, $_port2_index, $_port2_data)
   // Allow expressions for most inputs, so define input signals.
   $dmem_wr_en = m4_argn(4, $@);
   $dmem_wr_index[\$clog2(_entries)-1:0] = m4_argn(5, $@);
   $dmem_wr_data[_width-1:0] = m4_argn(6, $@);
   
   $dmem_rd_en = m4_argn(7, $@);
   $dmem_rd_index[\$clog2(_entries)-1:0] = m4_argn(8, $@);
   
   /dmem[_entries-1:0]
      <<1$value[_width-1:0] = /top$_reset    ? #dmem                :
                              /top$dmem_wr_en && (/top$dmem_wr_index == #dmem)
                                             ? /top$dmem_wr_data :
                                               $RETAIN;
   
   $_port2_data[_width-1:0] = $dmem_rd_en ? /dmem[$dmem_rd_index]$value : 'X;
   
\TLV cpu_viz()
   // String representations of the instructions for debug.
   \SV_plus
      // A default signal for ones that are not found.
      logic sticky_zero;
      assign sticky_zero = 0;
      // Instruction strings from the assembler.
      logic [40*8-1:0] instr_strs [0:M4_NUM_INSTRS];
      assign instr_strs = '{m4_asm_mem_expr "END                                     "};
   
   /cpuviz
      \viz_alpha
         initEach() {
            let imem_header = new fabric.Text("📒 Instr. Memory", {
                  top: -29,
                  left: -440,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let decode_header = new fabric.Text("⚙️ Instr. Decode", {
                  top: 0,
                  left: 40,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let rf_header = new fabric.Text("📂 Reg. File", {
                  top: -29 - 40,
                  left: 280,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let dmem_header = new fabric.Text("🗃️ Data Memory", {
                  top: -29 - 40,
                  left: 450,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            
            let missing = new fabric.Text("", {
                  top: 420,
                  left: -400,
                  fontSize: 16,
                  fontWeight: 500,
                  fontFamily: "monospace",
                  fill: "purple"
               })
            let missing_sigs = new fabric.Group(
               [new fabric.Text("🚨 Missing Signals", {
                  top: 350,
                  left: -400,
                  fontSize: 18,
                  fontWeight: 800,
                  fill: "red",
                  fontFamily: "monospace"
               }),
               new fabric.Rect({
                  top: 400,
                  left: -500,
                  fill: "#ffffe0",
                  width: 400,
                  height: 300,
                  stroke: "black"
               }),
               missing
              ],
              {visible: false}
            )
            return {missing,
                    objects: {imem_header, decode_header, rf_header, dmem_header, missing_sigs}};
         },
         renderEach: function() {
            var missing_list = "";   // String of missing signals.
            let sticky_zero = this.svSigRef(`sticky_zero`);  // A default zero-valued signal.
            // Attempt to look up a signal, using sticky_zero as default and updating missing_list if expected.
            siggen = (name, full_name, expected = true) => {
               var sig = this.svSigRef(full_name ? full_name : `L0_${name}_a0`)
               if (sig == null) {
                  missing_list += `◾ $${name}      \n`;
                  sig         = sticky_zero;
               }
               return sig
            }
            // Look up signal, and it's ok if it doesn't exist.
            siggen_rf_dmem = (name, scope) => {
               return siggen(name, scope, false)
            }
            
            // Determine which is_xxx signal is asserted.
            siggen_mnemonic = () => {
               let instrs = ["lui", "auipc", "jal", "jalr", "beq", "bne", "blt", "bge", "bltu", "bgeu", "lb", "lh", "lw", "lbu", "lhu", "sb", "sh", "sw", "addi", "slti", "sltiu", "xori", "ori", "andi", "slli", "srli", "srai", "add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and", "csrrw", "csrrs", "csrrc", "csrrwi", "csrrsi", "csrrci", "load", "store"];
               for(i=0;i<instrs.length;i++) {
                  var sig = this.svSigRef(`L0_is_${instrs[i]}_a0`)
                  if(sig != null && sig.asBool()) {
                     return instrs[i].toUpperCase()
                  }
               }
               return "ILLEGAL"
            }
            
            //let example       =   siggen("error_eg")
            let pc            =   siggen("pc");
            let rd_valid      =   siggen("rd_valid");
            let rd            =   siggen("rd");
            let result        =   siggen("result");
            let src1_value    =   siggen("src1_value");
            let src2_value    =   siggen("src2_value");
            let imm           =   siggen("imm");
            let imm_valid     =   siggen("imm_valid");
            let rs1           =   siggen("rs1");
            let rs2           =   siggen("rs2");
            let rs1_valid     =   siggen("rs1_valid");
            let rs2_valid     =   siggen("rs2_valid");
            let mnemonic      =   siggen_mnemonic();
            
            let rf_rd_en1     =   siggen_rf_dmem("rf_rd_en1")
            let rf_rd_index1  =   siggen_rf_dmem("rf_rd_index1")
            let rf_rd_en2     =   siggen_rf_dmem("rf_rd_en2")
            let rf_rd_index2  =   siggen_rf_dmem("rf_rd_index2")
            let rf_wr_en      =   siggen_rf_dmem("rf_wr_en")
            let rf_wr_index   =   siggen_rf_dmem("rf_wr_index")
            let rf_wr_data    =   siggen_rf_dmem("rf_wr_data")
            let dmem_rd_en    =   siggen_rf_dmem("dmem_rd_en")
            let dmem_rd_index =   siggen_rf_dmem("dmem_rd_index")
            let dmem_wr_en    =   siggen_rf_dmem("dmem_wr_en")
            let dmem_wr_index =   siggen_rf_dmem("dmem_wr_index")       
             
            let pcPointer = new fabric.Text("👉", {
               top: 18 * (pc.asInt() / 4),
               left: -295,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace"
            })
            let pc_arrow = new fabric.Line([23, 18 * (pc.asInt() / 4) + 6, 46, 35], {
               stroke: "#d0e8ff",
               strokeWidth: 2
            })
            
            let rs1_arrow = new fabric.Line([330, 18 * rf_rd_index1.asInt() + 6 - 40, 190, 75 + 18 * 2], {
               stroke: "#d0e8ff",
               strokeWidth: 2,
               visible: rf_rd_en1.asBool()
            })
            let rs2_arrow = new fabric.Line([330, 18 * rf_rd_index2.asInt() + 6 - 40, 190, 75 + 18 * 3], {
               stroke: "#d0e8ff",
               strokeWidth: 2,
               visible: rf_rd_en2.asBool()
            })
            let rd_arrow = new fabric.Line([310, 18 * rf_wr_index.asInt() + 6 - 40, 168, 75 + 18 * 0], {
               stroke: "#d0d0ff",
               strokeWidth: 3,
               visible: rf_wr_en.asBool()
            })
            let ld_arrow = new fabric.Line([470, 18 * dmem_rd_index.asInt() + 6 - 40, 175, 75 + 18 * 1], {
               stroke: "#d0e8ff",
               strokeWidth: 2,
               visible: dmem_rd_en.asBool()
            })
            let st_arrow = new fabric.Line([470, 18 * dmem_wr_index.asInt() + 6 - 40, 175, 75 + 18 * 1], {
               stroke: "#d0d0ff",
               strokeWidth: 3,
               visible: dmem_wr_en.asBool()
            })
            
            
            // Instruction with values
            
            let regStr = (valid, regNum, regValue) => {
               return valid ? `r${regNum}` : `rX`  // valid ? `r${regNum} (${regValue})` : `rX`
            };
            let immStr = (valid, immValue) => {
               immValue = parseInt(immValue,2) + 2*(immValue[0] << 31)
               return valid ? `i[${immValue}]` : ``;
            };
            let srcStr = ($src, $valid, $reg, $value) => {
               return $valid.asBool(false)
                          ? `\n      ${regStr(true, $reg.asInt(NaN), $value.asInt(NaN))}`
                          : "";
            };
            let str = `${regStr(rd_valid.asBool(false), rd.asInt(NaN), result.asInt(NaN))}\n` +
                      `  = ${mnemonic}${srcStr(1, rs1_valid, rs1, src1_value)}${srcStr(2, rs2_valid, rs2, src2_value)}\n` +
                      `      ${immStr(imm_valid.asBool(false), imm.asBinaryStr())}`;
            let instrWithValues = new fabric.Text(str, {
               top: 70,
               left: 65,
               fill: color,
               fontSize: 14,
               fontFamily: "monospace"
            });
            
            
            // Animate fetch (and provide onChange behavior for other animation).
            
            let fetch_instr_str = siggen(`instr_strs(${pc.asInt() >> 2})`, `instr_strs(${pc.asInt() >> 2})`).asString("UNKNOWN fetch instr")
            let fetch_instr_viz = new fabric.Text(fetch_instr_str, {
               top: 18 * (pc.asInt() >> 2),
               left: -272,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace"
            })
            fetch_instr_viz.animate({top: 32, left: 50}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
            });
            
            let src1_value_viz = new fabric.Text(src1_value.asInt(0).toString(), {
               left: 316 + 8 * 4,
               top: 18 * rs1.asInt(0) - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: rs1_valid.asBool(false)
            })
            setTimeout(() => {src1_value_viz.animate({left: 166, top: 70 + 18 * 2}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
            })}, 500)
            let src2_value_viz = new fabric.Text(src2_value.asInt(0).toString(), {
               left: 316 + 8 * 4,
               top: 18 * rs2.asInt(0) - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: rs2_valid.asBool(false)
            })
            setTimeout(() => {src2_value_viz.animate({left: 166, top: 70 + 18 * 3}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
            })}, 500)
            
            let load_viz = new fabric.Text(rf_wr_data.asInt(0).toString(), {
               left: 470,
               top: 18 * dmem_rd_index.asInt() + 6 - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 1000,
               visible: false
            })
            if (dmem_rd_en.asBool()) {
               setTimeout(() => {
                  load_viz.setVisible(true)
                  load_viz.animate({left: 165, top: 75 + 18 * 1 - 5}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
                  setTimeout(() => {
                     load_viz.setVisible(true)
                     load_viz.animate({left: 350, top: 18 * rf_wr_index.asInt() - 40}, {
                       onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                       duration: 500
                     })
                     }, 1000)
               }, 500)
            }
            
            let store_viz = new fabric.Text(src2_value.asInt(0).toString(), {
               left: 165,
               top: 75 + 18 * 1 - 5,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 1000,
               visible: false
            })
            if (dmem_wr_en.asBool()) {
               setTimeout(() => {
                  store_viz.setVisible(true)
                  store_viz.animate({left: 515, top: 18 * dmem_wr_index.asInt() - 40}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
               }, 1000)
            }
            
            let result_shadow = new fabric.Text(result.asInt(0).toString(), {
               left: 146,
               top: 70,
               fill: "#d0d0ff",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: false
            })
            let result_viz = new fabric.Text(result.asInt(0).toString(), {
               left: 146,
               top: 70,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: false
            })
            if (rd_valid.asBool() && !dmem_rd_en.asBool()) {
               setTimeout(() => {
                  result_viz.setVisible(true)
                  result_shadow.setVisible(true)
                  result_viz.animate({left: 317 + 8 * 4, top: 18 * rd.asInt(0) - 40}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
               }, 1000)
            }
            
            // Missing signals
            if (missing_list) {
               this.getInitObject("missing_sigs").setVisible(true)
               this.fromInit().missing.setText(missing_list)
            }
            
            return {objects: [pcPointer, pc_arrow, rs1_arrow, rs2_arrow, rd_arrow, instrWithValues, fetch_instr_viz, src1_value_viz, src2_value_viz, result_shadow, result_viz, ld_arrow, st_arrow, load_viz, store_viz]};
         }
      
      /imem[m4_eval(M4_NUM_INSTRS-1):0]  // TODO: Cleanly report non-integer ranges.
         \viz_alpha
            initEach() {
              let binary = new fabric.Text("", {
                 top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                 left: -600,
                 fontSize: 14,
                 fontFamily: "monospace"
              })
              let disassembled = new fabric.Text("", {
                 top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                 left: -270,
                 fontSize: 14,
                 fontFamily: "monospace"
              })
              return {objects: {binary: binary, disassembled: disassembled}}
            },
            renderEach: function() {
               let siggen = (name) => {return this.svSigRef(`${name}`) == null ? this.svSigRef(`sticky_zero`) : this.svSigRef(`${name}`)}
               
               // Instruction memory is constant, so just create it once.
               let reset = this.svSigRef(`L0_reset_a0`);
               let pc = this.svSigRef(`L0_pc_a0`) == null ? this.svSigRef(`sticky_zero`) : this.svSigRef(`L0_pc_a0`);
               let rd_viz = !reset.asBool() && (pc.asInt() >> 2) == this.getIndex();
               if (!global.instr_mem_drawn) {
                  global.instr_mem_drawn = [];
               }
               if (!global.instr_mem_drawn[this.getIndex()]) {
                  global.instr_mem_drawn[this.getIndex()] = true
                  let binary_str       = siggen(`instrs(${this.getIndex()})`).asBinaryStr(NaN)
                  let disassembled_str = siggen(`instr_strs(${this.getIndex()})`).asString("")
                  disassembled_str = disassembled_str.slice(0, -5)
                  //debugger
                  this.getInitObject("binary").setText(binary_str)
                  this.getInitObject("disassembled").setText(disassembled_str)
               }
               this.getInitObject("disassembled").set({textBackgroundColor: rd_viz ? "#b0ffff" : "white"})
            }
      
      /xreg[31:0]
         \viz_alpha
            initEach: function() {
               return {}  // {objects: {reg: reg}};
            },
            renderEach: function() {
               siggen = (name) => this.svSigRef(`${name}`) == null ? this.svSigRef(`sticky_zero`) : this.svSigRef(`${name}`);
               
               let rf_rd_en1 = siggen(`L0_rf_rd_en1_a0`)
               let rf_rd_index1 = siggen(`L0_rf_rd_index1_a0`)
               let rf_rd_en2 = siggen(`L0_rf_rd_en1_a0`)
               let rf_rd_index2 = siggen(`L0_rf_rd_index2_a0`)
               let rf_wr_index = siggen(`rf_wr_index_a0`)
               let wr = siggen(`L1_Xreg[${this.getIndex()}].L1_wr_a0`)
               let value = siggen(`Xreg_value_a0(${this.getIndex()})`)
               
               let rd = (rf_rd_en1.asBool(false) && rf_rd_index1.asInt() == this.getIndex()) || 
                        (rf_rd_en2.asBool(false) && rf_rd_index2.asInt() == this.getIndex())
               
               let mod = wr.asBool(false);
               let wr_color = mod && rf_wr_index.asInt() == this.getIndex()
               let reg = parseInt(this.getIndex())
               let regIdent = reg.toString().padEnd(2, " ")
               let newValStr = regIdent + ": "
               let reg_str = new fabric.Text(regIdent + ": " + value.asInt(NaN).toString(), {
                  top: 18 * this.getIndex() - 40,
                  left: 316,
                  fontSize: 14,
                  fill: mod ? "blue" : "black",
                  fontWeight: mod ? 800 : 400,
                  fontFamily: "monospace",
                  textBackgroundColor: rd ? "#b0ffff" : wr_color ? "#ffef87" : null
               })
               if (mod) {
                  setTimeout(() => {
                     console.log(`Reg ${this.getIndex()} written with: ${newValStr}.`)
                     reg_str.set({text: newValStr, dirty: true})
                     this.global.canvas.renderAll()
                  }, 1500)
               }
               return {objects: [reg_str]}
            }
         
      /dmem[31:0]
         \viz_alpha
            initEach: function() {
               return {}  // {objects: {reg: reg}};
            },
            renderEach: function() {
               siggen = (name) => this.svSigRef(`${name}`) == null ? this.svSigRef(`sticky_zero`) : this.svSigRef(`${name}`);
               
               let dmem_rd_en = siggen(`L0_dmem_rd_en_a0`);
               let dmem_rd_index = siggen(`L0_dmem_rd_index_a0`);
               let dmem_wr_index = siggen(`L0_dmem_wr_index_a0`);
               
               let wr = siggen(`L1_Dmem[${this.getIndex()}].L1_wr_a0`);
               let value = siggen(`Dmem_value_a0(${this.getIndex()})`);
               
               let rd = dmem_rd_en.asBool() && dmem_rd_index.asInt() == this.getIndex();
               let mod = wr.asBool(false);
               let wr_color = mod && dmem_wr_index.asInt() == this.getIndex();
               let reg = parseInt(this.getIndex());
               let regIdent = reg.toString().padEnd(2, " ");
               let newValStr = regIdent + ": ";
               let dmem_str = new fabric.Text(regIdent + ": " + value.asInt(NaN).toString(), {
                  top: 18 * this.getIndex() - 40,
                  left: 480,
                  fontSize: 14,
                  fill: mod ? "blue" : "black",
                  fontWeight: mod ? 800 : 400,
                  fontFamily: "monospace",
                  textBackgroundColor: rd ? "#b0ffff" : wr_color ? "#ffef87" : null
               })
               if (mod) {
                  setTimeout(() => {
                     console.log(`Reg ${this.getIndex()} written with: ${newValStr}.`)
                     dmem_str.set({text: newValStr, dirty: true})
                     this.global.canvas.renderAll()
                  }, 1500)
               }
               return {objects: [dmem_str]}
            }

// ^===================================================================^

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
