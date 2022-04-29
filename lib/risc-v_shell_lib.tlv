\m4_TLV_version 1d: tl-x.org
\SV
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/1d1023ccf8e7b0a8cf8e8fc4f0a823ebb61008e3/risc-v_defs.tlv'])
   
// v====================== lib/risc-v_shell_lib.tlv =======================v

// Configuration for WARP-V definitions.
m4+definitions(['
   // Define full test program.
   // Provide a non-empty argument if this is instantiated within a \TLV region (vs. \SV).
   m4_define(['m4_test_prog'], ['m4_hide(['
     // /=======================\
     // | Test each instruction |
     // \=======================/
     //
     // Some constant values to use as operands.
     m4_asm(ADDI, x1, x0, 10101)           // An operand value of 21.
     m4_asm(ADDI, x2, x0, 111)             // An operand value of 7.
     m4_asm(ADDI, x3, x0, 111111111100)    // An operand value of -4.
     // Execute one of each instruction, XORing subtracting (via ADDI) the expected value.
     // ANDI:
     m4_asm(ANDI, x5, x1, 1011100)
     m4_asm(XORI, x5, x5, 10101)
     // ORI:
     m4_asm(ORI, x6, x1, 1011100)
     m4_asm(XORI, x6, x6, 1011100)
     // ADDI:
     m4_asm(ADDI, x7, x1, 111)
     m4_asm(XORI, x7, x7, 11101)
     // ADDI:
     m4_asm(SLLI, x8, x1, 110)
     m4_asm(XORI, x8, x8, 10101000001)
     // SLLI:
     m4_asm(SRLI, x9, x1, 10)
     m4_asm(XORI, x9, x9, 100)
     // AND:
     m4_asm(AND, r10, x1, x2)
     m4_asm(XORI, x10, x10, 100)
     // OR:
     m4_asm(OR, x11, x1, x2)
     m4_asm(XORI, x11, x11, 10110)
     // XOR:
     m4_asm(XOR, x12, x1, x2)
     m4_asm(XORI, x12, x12, 10011)
     // ADD:
     m4_asm(ADD, x13, x1, x2)
     m4_asm(XORI, x13, x13, 11101)
     // SUB:
     m4_asm(SUB, x14, x1, x2)
     m4_asm(XORI, x14, x14, 1111)
     // SLL:
     m4_asm(SLL, x15, x2, x2)
     m4_asm(XORI, x15, x15, 1110000001)
     // SRL:
     m4_asm(SRL, x16, x1, x2)
     m4_asm(XORI, x16, x16, 1)
     // SLTU:
     m4_asm(SLTU, x17, x2, x1)
     m4_asm(XORI, x17, x17, 0)
     // SLTIU:
     m4_asm(SLTIU, x18, x2, 10101)
     m4_asm(XORI, x18, x18, 0)
     // LUI:
     m4_asm(LUI, x19, 0)
     m4_asm(XORI, x19, x19, 1)
     // SRAI:
     m4_asm(SRAI, x20, x3, 1)
     m4_asm(XORI, x20, x20, 111111111111)
     // SLT:
     m4_asm(SLT, x21, x3, x1)
     m4_asm(XORI, x21, x21, 0)
     // SLTI:
     m4_asm(SLTI, x22, x3, 1)
     m4_asm(XORI, x22, x22, 0)
     // SRA:
     m4_asm(SRA, x23, x1, x2)
     m4_asm(XORI, x23, x23, 1)
     // AUIPC:
     m4_asm(AUIPC, x4, 100)
     m4_asm(SRLI, x24, x4, 111)
     m4_asm(XORI, x24, x24, 10000000)
     // JAL:
     m4_asm(JAL, x25, 10)     // x25 = PC of next instr
     m4_asm(AUIPC, x4, 0)     // x4 = PC
     m4_asm(XOR, x25, x25, x4)  # AUIPC and JAR results are the same.
     m4_asm(XORI, x25, x25, 1)
     // JALR:
     m4_asm(JALR, x26, x4, 10000)
     m4_asm(SUB, x26, x26, x4)        // JALR PC+4 - AUIPC PC
     m4_asm(ADDI, x26, x26, 111111110001)  // - 4 instrs, + 1
     // SW & LW:
     m4_asm(SW, x2, x1, 1)
     m4_asm(LW, x27, x2, 1)
     m4_asm(XORI, x27, x27, 10100)
     // Write 1 to remaining registers prior to x30 just to avoid concern.
     m4_asm(ADDI, x28, x0, 1)
     m4_asm(ADDI, x29, x0, 1)
     // Terminate with success condition (regardless of correctness of register values):
     m4_asm(ADDI, x30, x0, 1)
     m4_asm(JAL, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
     
     m4_define(['M4_VIZ_BASE'], 16)   // (Note that immediate values are shown in disassembled instructions in binary and signed decimal in decoder regardless of this setting.)

     m4_define(['M4_MAX_CYC'], 70)
     '])m4_ifelse(['$1'], [''], ['m4_asm_end()'], ['m4_asm_end_tlv()'])'])
   
   m4_define_vector(['M4_WORD'], 32)
   m4_define(['M4_EXT_I'], 1)
   
   m4_define(['M4_NUM_INSTRS'], 0)
   
   m4_echo(m4tlv_riscv_gen__body())
   
   // A single-line M4 macro instantiated at the end of the asm code.
   // It actually produces a definition of an SV macro that instantiates the IMem conaining the program (that can be parsed without \SV_plus). 
   m4_define(['m4_asm_end'], ['`define READONLY_MEM(ADDR, DATA) logic [31:0] instrs [0:M4_NUM_INSTRS-1]; assign DATA = instrs[ADDR[$clog2($size(instrs)) + 1 : 2]]; assign instrs = '{m4_instr0['']m4_forloop(['m4_instr_ind'], 1, M4_NUM_INSTRS, [', m4_echo(['m4_instr']m4_instr_ind)'])};'])
   m4_define(['m4_asm_end_tlv'], ['`define READONLY_MEM(ADDR, DATA) logic [31:0] instrs [0:M4_NUM_INSTRS-1]; assign DATA \= instrs[ADDR[\$clog2(\$size(instrs)) + 1 : 2]]; assign instrs \= '{m4_instr0['']m4_forloop(['m4_instr_ind'], 1, M4_NUM_INSTRS, [', m4_echo(['m4_instr']m4_instr_ind)'])};'])
'])

\TLV test_prog()
   m4_test_prog(['TLV'])

// Register File
\TLV rf(_entries, _width, $_reset, $_port1_en, $_port1_index, $_port1_data, $_port2_en, $_port2_index, $_port2_data, $_port3_en, $_port3_index, $_port3_data)
   $rf1_wr_en = m4_argn(4, $@);
   $rf1_wr_index[\$clog2(_entries)-1:0]  = m4_argn(5, $@);
   $rf1_wr_data[_width-1:0] = m4_argn(6, $@);
   
   $rf1_rd_en1 = m4_argn(7, $@);
   $rf1_rd_index1[\$clog2(_entries)-1:0] = m4_argn(8, $@);
   
   $rf1_rd_en2 = m4_argn(10, $@);
   $rf1_rd_index2[\$clog2(_entries)-1:0] = m4_argn(11, $@);
   
   /xreg[m4_eval(_entries-1):0]
      $wr = /top$rf1_wr_en && (/top$rf1_wr_index == #xreg);
      <<1$value[_width-1:0] = /top$_reset ? #xreg              :
                                 $wr      ? /top$rf1_wr_data :
                                            $RETAIN;
   
   $_port2_data[_width-1:0]  =  $rf1_rd_en1 ? /xreg[$rf1_rd_index1]$value : 'X;
   $_port3_data[_width-1:0]  =  $rf1_rd_en2 ? /xreg[$rf1_rd_index2]$value : 'X;
   
   /xreg[m4_eval(_entries-1):0]
      \viz_js
         box: {width: 120, height: 18, strokeWidth: 0},
         render() {
            let siggen = (name) => {
               let sig = this.svSigRef(`${name}`)
               return (sig == null || !sig.exists()) ? this.svSigRef(`sticky_zero`) : sig;
            }
            let rf_rd_en1 = siggen(`L0_rf1_rd_en1_a0`)
            let rf_rd_index1 = siggen(`L0_rf1_rd_index1_a0`)
            let rf_rd_en2 = siggen(`L0_rf1_rd_en2_a0`)
            let rf_rd_index2 = siggen(`L0_rf1_rd_index2_a0`)
            let wr = siggen(`L1_Xreg[${this.getIndex()}].L1_wr_a0`)
            let value = siggen(`Xreg_value_a0(${this.getIndex()})`)
            
            let rd = (rf_rd_en1.asBool(false) && rf_rd_index1.asInt() == this.getIndex()) || 
                     (rf_rd_en2.asBool(false) && rf_rd_index2.asInt() == this.getIndex())
            
            let mod = wr.asBool(false);
            let reg = parseInt(this.getIndex())
            let regIdent = reg.toString().padEnd(2, " ")
            let newValStr = (regIdent + ": ").padEnd(14, " ")
            let reg_str = new fabric.Text((regIdent + ": " + value.asInt(NaN).toString(M4_VIZ_BASE)).padEnd(14, " "), {
               top: 0,
               left: 0,
               fontSize: 14,
               fill: mod ? "blue" : "black",
               fontWeight: mod ? 800 : 400,
               fontFamily: "monospace",
               textBackgroundColor: rd ? "#b0ffff" : mod ? "#f0f0f0" : "white"
            })
            if (mod) {
               setTimeout(() => {
                  reg_str.set({text: newValStr, textBackgroundColor: "#d0e8ff", dirty: true})
                  this.global.canvas.renderAll()
               }, 1500)
            }
            return [reg_str]
         },
         where: {left: 316, top: -40}
         
// Data Memory
\TLV dmem(_entries, _width, $_reset, $_addr, $_port1_en, $_port1_data, $_port2_en, $_port2_data)
   // Allow expressions for most inputs, so define input signals.
   $dmem1_wr_en = $_port1_en;
   $dmem1_addr[\$clog2(_entries)-1:0] = $_addr;
   $dmem1_wr_data[_width-1:0] = $_port1_data;
   
   $dmem1_rd_en = $_port2_en;
   
   /dmem[m4_eval(_entries-1):0]
      $wr = /top$dmem1_wr_en && (/top$dmem1_addr == #dmem);
      <<1$value[_width-1:0] = /top$_reset ? 0                 :
                              $wr         ? /top$dmem1_wr_data :
                                            $RETAIN;
   
   $_port2_data[_width-1:0] = $dmem1_rd_en ? /dmem[$dmem1_addr]$value : 'X;
   /dmem[m4_eval(_entries-1):0]
      \viz_js
         box: {width: 120, height: 18, strokeWidth: 0},
         render() {
            let siggen = (name) => {
               let sig = this.svSigRef(`${name}`)
               return (sig == null || !sig.exists()) ? this.svSigRef(`sticky_zero`) : sig;
            }
            //
            let dmem_rd_en = siggen(`L0_dmem1_rd_en_a0`);
            let dmem_addr = siggen(`L0_dmem1_addr_a0`);
            //
            let wr = siggen(`L1_Dmem[${this.getIndex()}].L1_wr_a0`);
            let value = siggen(`Dmem_value_a0(${this.getIndex()})`);
            //
            let rd = dmem_rd_en.asBool() && dmem_addr.asInt() == this.getIndex();
            let mod = wr.asBool(false);
            let reg = parseInt(this.getIndex());
            let regIdent = reg.toString().padEnd(2, " ");
            let newValStr = (regIdent + ": ").padEnd(14, " ");
            let dmem_str = new fabric.Text((regIdent + ": " + value.asInt(NaN).toString(M4_VIZ_BASE)).padEnd(14, " "), {
               top: 0,
               left: 0,
               fontSize: 14,
               fill: mod ? "blue" : "black",
               fontWeight: mod ? 800 : 400,
               fontFamily: "monospace",
               textBackgroundColor: rd ? "#b0ffff" : mod ? "#d0e8ff" : "white"
            })
            if (mod) {
               setTimeout(() => {
                  dmem_str.set({text: newValStr, dirty: true})
                  this.global.canvas.renderAll()
               }, 1500)
            }
            return [dmem_str]
         },
         where: {left: 480, top: -40}

\TLV cpu_viz()
   // String representations of the instructions for debug.
   \SV_plus
      // A default signal for ones that are not found.
      logic sticky_zero;
      assign sticky_zero = 0;
      // Instruction strings from the assembler.
      logic [40*8-1:0] instr_strs [0:M4_NUM_INSTRS];
      assign instr_strs = '{m4_asm_mem_expr "END                                     "};
   
   \viz_js
      m4_define(['M4_IMEM_TOP'], ['m4_ifelse(m4_eval(M4_NUM_INSTRS > 16), 0, 0, m4_eval(0 - (M4_NUM_INSTRS - 16) * 18))'])
      box: {strokeWidth: 0},
      init() {
         let imem_box = new fabric.Rect({
               top: M4_IMEM_TOP - 50,
               left: -700,
               fill: "#208028",
               width: 665,
               height: 76 + 18 * M4_NUM_INSTRS,
               stroke: "black",
               visible: false
            })
         let decode_box = new fabric.Rect({
               top: -25,
               left: -15,
               fill: "#f8f0e8",
               width: 280,
               height: 215,
               stroke: "#ff8060",
               visible: false
            })
         let rf_box = new fabric.Rect({
               top: -90,
               left: 306,
               fill: "#2028b0",
               width: 145,
               height: 650,
               stroke: "black",
               visible: false
            })
         let dmem_box = new fabric.Rect({
               top: -90,
               left: 470,
               fill: "#208028",
               width: 145,
               height: 650,
               stroke: "black",
               visible: false
            })
         let imem_header = new fabric.Text("🗃️ IMem", {
               top: M4_IMEM_TOP - 35,
               left: -460,
               fontSize: 18,
               fontWeight: 800,
               fontFamily: "monospace",
               fill: "white",
               visible: false
            })
         let decode_header = new fabric.Text("⚙️ Instr. Decode", {
               top: -4,
               left: 20,
               fill: "maroon",
               fontSize: 18,
               fontWeight: 800,
               fontFamily: "monospace",
               visible: false
            })
         let rf_header = new fabric.Text("📂 RF", {
               top: -75,
               left: 316,
               fontSize: 18,
               fontWeight: 800,
               fontFamily: "monospace",
               fill: "white",
               visible: false
            })
         let dmem_header = new fabric.Text("🗃️ DMem", {
               top: -75,
               left: 480,
               fontSize: 18,
               fontWeight: 800,
               fontFamily: "monospace",
               fill: "white",
               visible: false
            })
         
         let passed = new fabric.Text("", {
               top: 340,
               left: -30,
               fontSize: 46,
               fontWeight: 800
            })
         this.missing_col1 = new fabric.Text("", {
               top: 420,
               left: -480,
               fontSize: 16,
               fontWeight: 500,
               fontFamily: "monospace",
               fill: "purple"
            })
         this.missing_col2 = new fabric.Text("", {
               top: 420,
               left: -300,
               fontSize: 16,
               fontWeight: 500,
               fontFamily: "monospace",
               fill: "purple"
            })
         let missing_sigs = new fabric.Group(
            [new fabric.Text("🚨 To Be Implemented:", {
               top: 350,
               left: -466,
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
            this.missing_col1,
            this.missing_col2,
           ],
           {visible: false}
         )
         return {imem_box, decode_box, rf_box, dmem_box, imem_header, decode_header, rf_header, dmem_header, passed, missing_sigs}
      },
      render() {
         // Strings (2 columns) of missing signals.
         var missing_list = ["", ""]
         var missing_cnt = 0
         let sticky_zero = this.svSigRef(`sticky_zero`);  // A default zero-valued signal.
         // Attempt to look up a signal, using sticky_zero as default and updating missing_list if expected.
         let siggen = (name, full_name, expected = true) => {
            var sig = this.svSigRef(full_name ? full_name : `L0_${name}_a0`)
            if (sig == null || !sig.exists()) {
               sig         = sticky_zero;
               if (expected) {
                  missing_list[missing_cnt > 11 ? 1 : 0] += `◾ $${name}      \n`;
                  missing_cnt++
               }
            }
            return sig
         }
         // Look up signal, and it's ok if it doesn't exist.
         siggen_rf_dmem = (name, scope) => {
            return siggen(name, scope, false)
         }
         
         // Determine which is_xxx signal is asserted.
         siggen_mnemonic = () => {
            let instrs = ["lui", "auipc", "jal", "jalr", "beq", "bne", "blt", "bge", "bltu", "bgeu", "lb", "lh", "lw", "lbu", "lhu", "sb", "sh", "sw", "addi", "slti", "sltiu", "xori", "ori", "andi", "slli", "srli", "srai", "add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and", "csrrw", "csrrs", "csrrc", "csrrwi", "csrrsi", "csrrci", "load", "s_instr"];
            for(i=0;i<instrs.length;i++) {
               var sig = this.svSigRef(`L0_is_${instrs[i]}_a0`)
               if(sig != null && sig.asBool(false)) {
                  return instrs[i].toUpperCase()
               }
            }
            return "ILLEGAL"
         }
         
         let pc            =   siggen("pc")
         let instr         =   siggen("instr")
         let types = {I: siggen("is_i_instr"),
                      R: siggen("is_r_instr"),
                      S: siggen("is_s_instr"),
                      B: siggen("is_b_instr"),
                      J: siggen("is_j_instr"),
                      U: siggen("is_u_instr"),
                     }
         let rd_valid      =   siggen("rd_valid")
         let rd            =   siggen("rd")
         let result        =   siggen("result")
         let src1_value    =   siggen("src1_value")
         let src2_value    =   siggen("src2_value")
         let imm           =   siggen("imm")
         let imm_valid     =   siggen("imm_valid")
         let rs1           =   siggen("rs1")
         let rs2           =   siggen("rs2")
         let rs1_valid     =   siggen("rs1_valid")
         let rs2_valid     =   siggen("rs2_valid")
         let ld_data       =   siggen("ld_data")
         let mnemonic      =   siggen_mnemonic()
         let passed        =   siggen("passed_cond", false, false)
         
         let rf_rd_en1     =   siggen_rf_dmem("rf1_rd_en1")
         let rf_rd_index1  =   siggen_rf_dmem("rf1_rd_index1")
         let rf_rd_en2     =   siggen_rf_dmem("rf1_rd_en2")
         let rf_rd_index2  =   siggen_rf_dmem("rf1_rd_index2")
         let rf_wr_en      =   siggen_rf_dmem("rf1_wr_en")
         let rf_wr_index   =   siggen_rf_dmem("rf1_wr_index")
         let rf_wr_data    =   siggen_rf_dmem("rf1_wr_data")
         let dmem_rd_en    =   siggen_rf_dmem("dmem1_rd_en")
         let dmem_wr_en    =   siggen_rf_dmem("dmem1_wr_en")
         let dmem_addr     =   siggen_rf_dmem("dmem1_addr")
         
         if (instr != sticky_zero) {
            this.getObjects().imem_box.set({visible: true})
            this.getObjects().imem_header.set({visible: true})
            this.getObjects().decode_box.set({visible: true})
            this.getObjects().decode_header.set({visible: true})
         }
         let pcPointer = new fabric.Text("👉", {
            top: M4_IMEM_TOP + 18 * (pc.asInt() / 4),
            left: -375,
            fill: "blue",
            fontSize: 14,
            fontFamily: "monospace",
            visible: pc != sticky_zero
         })
         let pc_arrow = new fabric.Line([-57, M4_IMEM_TOP + 18 * (pc.asInt() / 4) + 6, 6, 35], {
            stroke: "#b0c8df",
            strokeWidth: 2,
            visible: instr != sticky_zero
         })
         
         // Display instruction type(s)
         let type_texts = []
         for (const [type, sig] of Object.entries(types)) {
            if (sig.asBool()) {
               type_texts.push(
                  new fabric.Text(`(${type})`, {
                     top: 60,
                     left: 10,
                     fill: "blue",
                     fontSize: 20,
                     fontFamily: "monospace"
                  })
               )
            }
         }
         let rs1_arrow = new fabric.Line([330, 18 * rf_rd_index1.asInt() + 6 - 40, 190, 75 + 18 * 2], {
            stroke: "#b0c8df",
            strokeWidth: 2,
            visible: rf_rd_en1.asBool()
         })
         let rs2_arrow = new fabric.Line([330, 18 * rf_rd_index2.asInt() + 6 - 40, 190, 75 + 18 * 3], {
            stroke: "#b0c8df",
            strokeWidth: 2,
            visible: rf_rd_en2.asBool()
         })
         let rd_arrow = new fabric.Line([330, 18 * rf_wr_index.asInt() + 6 - 40, 168, 75 + 18 * 0], {
            stroke: "#b0b0df",
            strokeWidth: 3,
            visible: rf_wr_en.asBool()
         })
         let ld_arrow = new fabric.Line([490, 18 * dmem_addr.asInt() + 6 - 40, 168, 75 + 18 * 0], {
            stroke: "#b0c8df",
            strokeWidth: 2,
            visible: dmem_rd_en.asBool()
         })
         let st_arrow = new fabric.Line([490, 18 * dmem_addr.asInt() + 6 - 40, 190, 75 + 18 * 3], {
            stroke: "#b0b0df",
            strokeWidth: 3,
            visible: dmem_wr_en.asBool()
         })
         if (rf_rd_en1 != sticky_zero) {
            this.getObjects().rf_box.set({visible: true})
            this.getObjects().rf_header.set({visible: true})
         }
         if (dmem_rd_en != sticky_zero) {
            this.getObjects().dmem_box.set({visible: true})
            this.getObjects().dmem_header.set({visible: true})
         }
         
         
         // Instruction with values
         
         let regStr = (valid, regNum, regValue) => {
            return valid ? `x${regNum}` : `xX`  // valid ? `x${regNum} (${regValue})` : `xX`
         }
         let immStr = (valid, immValue) => {
            immValue = parseInt(immValue,2) + 2*(immValue[0] << 31)
            return valid ? `i[${immValue}]` : ``;
         }
         let srcStr = ($src, $valid, $reg, $value) => {
            return $valid.asBool(false)
                       ? `\n      ${regStr(true, $reg.asInt(NaN), $value.asInt(NaN))}`
                       : "";
         }
         let str = `${regStr(rd_valid.asBool(false), rd.asInt(NaN), result.asInt(NaN))}\n` +
                   `  = ${mnemonic}${srcStr(1, rs1_valid, rs1, src1_value)}${srcStr(2, rs2_valid, rs2, src2_value)}\n` +
                   `      ${immStr(imm_valid.asBool(false), imm.asBinaryStr("0"))}`;
         let instrWithValues = new fabric.Text(str, {
            top: 70,
            left: 65,
            fill: "blue",
            fontSize: 14,
            fontFamily: "monospace",
            visible: instr != sticky_zero
         })
         
         
         // Animate fetch (and provide onChange behavior for other animation).
         
         let fetch_instr_str = siggen(`instr_strs(${pc.asInt() >> 2})`, `instr_strs(${pc.asInt() >> 2})`).asString("(?) UNKNOWN fetch instr").substr(4)
         let fetch_instr_viz = new fabric.Text(fetch_instr_str, {
            top: M4_IMEM_TOP + 18 * (pc.asInt() >> 2),
            left: -352 + 8 * 4,
            fill: "black",
            fontSize: 14,
            fontFamily: "monospace",
            visible: instr != sticky_zero
         })
         fetch_instr_viz.animate({top: 32, left: 10}, {
              onChange: this.global.canvas.renderAll.bind(this.global.canvas),
              duration: 500
         })
         
         // Animate RF value read/write.
         
         let src1_value_viz = new fabric.Text(src1_value.asInt(0).toString(M4_VIZ_BASE), {
            left: 316 + 8 * 4,
            top: 18 * rs1.asInt(0) - 40,
            fill: "blue",
            fontSize: 14,
            fontFamily: "monospace",
            fontWeight: 800,
            visible: (src1_value != sticky_zero) && rs1_valid.asBool(false)
         })
         setTimeout(() => {src1_value_viz.animate({left: 166, top: 70 + 18 * 2}, {
              onChange: this.global.canvas.renderAll.bind(this.global.canvas),
              duration: 500
         })}, 500)
         let src2_value_viz = new fabric.Text(src2_value.asInt(0).toString(M4_VIZ_BASE), {
            left: 316 + 8 * 4,
            top: 18 * rs2.asInt(0) - 40,
            fill: "blue",
            fontSize: 14,
            fontFamily: "monospace",
            fontWeight: 800,
            visible: (src2_value != sticky_zero) && rs2_valid.asBool(false)
         })
         setTimeout(() => {src2_value_viz.animate({left: 166, top: 70 + 18 * 3}, {
              onChange: this.global.canvas.renderAll.bind(this.global.canvas),
              duration: 500
         })}, 500)
         
         let load_viz = new fabric.Text(ld_data.asInt(0).toString(M4_VIZ_BASE), {
            left: 470,
            top: 18 * dmem_addr.asInt() + 6 - 40,
            fill: "blue",
            fontSize: 14,
            fontFamily: "monospace",
            fontWeight: 1000,
            visible: false
         })
         if (dmem_rd_en.asBool()) {
            setTimeout(() => {
               load_viz.set({visible: true})
               load_viz.animate({left: 146, top: 70}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
               })
               setTimeout(() => {
                  load_viz.set({visible: false})
                  }, 500)
            }, 500)
         }
         
         let store_viz = new fabric.Text(src2_value.asInt(0).toString(M4_VIZ_BASE), {
            left: 166,
            top: 70 + 18 * 3,
            fill: "blue",
            fontSize: 14,
            fontFamily: "monospace",
            fontWeight: 1000,
            visible: false
         })
         if (dmem_wr_en.asBool()) {
            setTimeout(() => {
               store_viz.set({visible: true})
               store_viz.animate({left: 515, top: 18 * dmem_addr.asInt() - 40}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
               })
            }, 1000)
         }
         
         let result_shadow = new fabric.Text(result.asInt(0).toString(M4_VIZ_BASE), {
            left: 146,
            top: 70,
            fill: "#b0b0df",
            fontSize: 14,
            fontFamily: "monospace",
            fontWeight: 800,
            visible: false
         })
         let result_viz = new fabric.Text(rf_wr_data.asInt(0).toString(M4_VIZ_BASE), {
            left: 146,
            top: 70,
            fill: "blue",
            fontSize: 14,
            fontFamily: "monospace",
            fontWeight: 800,
            visible: false
         })
         if (rd_valid.asBool()) {
            setTimeout(() => {
               result_viz.set({visible: rf_wr_data != sticky_zero && rf_wr_en.asBool()})
               result_shadow.set({visible: result != sticky_zero})
               result_viz.animate({left: 317 + 8 * 4, top: 18 * rf_wr_index.asInt(0) - 40}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
               })
            }, 1000)
         }
         
         // Lab completion
         
         // Passed?
         this.getObjects().passed.set({visible: false})
         if (passed) {
           if (passed.step(-1).asBool()) {
             this.getObjects().passed.set({visible: true, text:"Passed !!!", fill: "green"})
           } else {
             // Using an unstable API, so:
             try {
               passed.goToSimEnd().step(-1)
               if (passed.asBool()) {
                  this.getObjects().passed.set({text:"Sim Passes", visible: true, fill: "lightgray"})
               }
             } catch(e) {
             }
           }
         }
         
         // Missing signals
         if (missing_list[0]) {
            this.getObjects().missing_sigs.set({visible: true})
            this.missing_col1.set({text: missing_list[0]})
            this.missing_col2.set({text: missing_list[1]})
         }
         return [pcPointer, pc_arrow, ...type_texts, rs1_arrow, rs2_arrow, rd_arrow, instrWithValues, fetch_instr_viz, src1_value_viz, src2_value_viz, result_shadow, result_viz, ld_arrow, st_arrow, load_viz, store_viz]
      }
      
   /imem[m4_eval(M4_NUM_INSTRS-1):0]
      \viz_js
         box: {width: 630, height: 18, strokeWidth: 0},
         init() {
           let binary = new fabric.Text("", {
              top: 0,
              left: 0,
              fontSize: 14,
              fontFamily: "monospace",
         
           })
           let disassembled = new fabric.Text("", {
              top: 0,
              left: 330,
              fontSize: 14,
              fontFamily: "monospace"
           })
           return {binary, disassembled}
         },
         onTraceData() {
            let instr = this.svSigRef(`instrs(${this.getIndex()})`)
            if (instr) {
               let binary_str = instr.goToSimStart().asBinaryStr("")
               this.getObjects().binary.set({text: binary_str})
            }
            let disassembled = this.svSigRef(`instr_strs(${this.getIndex()})`)
            if (disassembled) {
               let disassembled_str = disassembled.goToSimStart().asString("")
               disassembled_str = disassembled_str.slice(0, -5)
               this.getObjects().disassembled.set({text: disassembled_str})
            }
         },
         render() {
            // Instruction memory is constant, so just create it once.
            let reset = this.svSigRef(`L0_reset_a0`)
            let pc = this.svSigRef(`L0_pc_a0`)
            let rd_viz = pc && !reset.asBool() && (pc.asInt() >> 2) == this.getIndex()
            this.getObjects().disassembled.set({textBackgroundColor: rd_viz ? "#b0ffff" : "white"})
            this.getObjects().binary      .set({textBackgroundColor: rd_viz ? "#b0ffff" : "white"})
         },
         where: {left: -680, top: M4_IMEM_TOP}
      
\TLV tb()
   $passed_cond = (/xreg[30]$value == 32'b1) &&
                  (! $reset && $next_pc[31:0] == $pc[31:0]);
   *passed = >>2$passed_cond;


// (A copy of this appears in the shell code.)
\TLV sum_prog()
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
   m4_asm(ADDI, x14, x0, 0)             // Initialize sum register x14 with 0
   m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register x12.
   m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register x13 with 0
   // Loop:
   m4_asm(ADD, x14, x13, x14)           // Incremental summation
   m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   m4_asm(BLT, x13, x12, 1111111111000) // If x13 is less than x12, branch to label named <loop>
   // Test result value in x14, and set x31 to reflect pass/fail.
   m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
   m4_asm(BGE, x0, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_asm_end_tlv()
   m4_define(['M4_MAX_CYC'], 40)
  
  
// ^===================================================================^

\SV
   m4_makerchip_module  // (Expanded in Nav-TLV pane.)
\TLV
   // Do nothing.
\SV
   endmodule
