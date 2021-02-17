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
   m4_define(['m4_asm_end'], ['`define READONLY_MEM(ADDR, DATA) logic [31:0] instrs [0:M4_NUM_INSTRS-1]; assign DATA \= instrs[ADDR[\$clog2(\$size(instrs)) + 1 : 2]]; assign instrs \= '{m4_instr0['']m4_forloop(['m4_instr_ind'], 1, M4_NUM_INSTRS, [', m4_echo(['m4_instr']m4_instr_ind)'])};'])
'])


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
      \viz_alpha
         initEach: function() {
            return {}  // {objects: {reg: reg}};
         },
         renderEach: function() {
            siggen = (name) => this.svSigRef(`${name}`) == null ? this.svSigRef(`sticky_zero`) : this.svSigRef(`${name}`);
            
            let rf_rd_en1 = siggen(`L0_rf1_rd_en1_a0`)
            let rf_rd_index1 = siggen(`L0_rf1_rd_index1_a0`)
            let rf_rd_en2 = siggen(`L0_rf1_rd_en2_a0`)
            let rf_rd_index2 = siggen(`L0_rf1_rd_index2_a0`)
            let rf_wr_index = siggen(`rf1_wr_index_a0`)
            let wr = siggen(`L1_Xreg[${this.getIndex()}].L1_wr_a0`)
            let value = siggen(`Xreg_value_a0(${this.getIndex()})`)
            
            let rd = (rf_rd_en1.asBool(false) && rf_rd_index1.asInt() == this.getIndex()) || 
                     (rf_rd_en2.asBool(false) && rf_rd_index2.asInt() == this.getIndex())
            
            let mod = wr.asBool(false);
            let reg = parseInt(this.getIndex())
            let regIdent = reg.toString().padEnd(2, " ")
            let newValStr = (regIdent + ": ").padEnd(14, " ")
            let reg_str = new fabric.Text((regIdent + ": " + value.asInt(NaN).toString(M4_VIZ_BASE)).padEnd(14, " "), {
               top: 18 * this.getIndex() - 40,
               left: 316,
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
            return {objects: [reg_str]}
         }
         
// Data Memory
\TLV dmem(_entries, _width, $_reset, $_port1_en, $_port1_index, $_port1_data, $_port2_en, $_port2_index, $_port2_data)
   // Allow expressions for most inputs, so define input signals.
   $dmem1_wr_en = m4_argn(4, $@);
   $dmem1_wr_index[\$clog2(_entries)-1:0] = m4_argn(5, $@);
   $dmem1_wr_data[_width-1:0] = m4_argn(6, $@);
   
   $dmem1_rd_en = m4_argn(7, $@);
   $dmem1_rd_index[\$clog2(_entries)-1:0] = m4_argn(8, $@);
   
   /dmem[m4_eval(_entries-1):0]
      $wr = /top$dmem1_wr_en && (/top$dmem1_wr_index == #dmem);
      <<1$value[_width-1:0] = /top$_reset ? 0                 :
                              $wr         ? /top$dmem1_wr_data :
                                            $RETAIN;
   
   $_port2_data[_width-1:0] = $dmem1_rd_en ? /dmem[$dmem1_rd_index]$value : 'X;
   /dmem[m4_eval(_entries-1):0]
      \viz_alpha
         initEach: function() {
            return {}  // {objects: {reg: reg}};
         },
         renderEach: function() {
            siggen = (name) => this.svSigRef(`${name}`) == null ? this.svSigRef(`sticky_zero`) : this.svSigRef(`${name}`);
            //
            let dmem_rd_en = siggen(`L0_dmem1_rd_en_a0`);
            let dmem_rd_index = siggen(`L0_dmem1_rd_index_a0`);
            let dmem_wr_index = siggen(`L0_dmem1_wr_index_a0`);
            //
            let wr = siggen(`L1_Dmem[${this.getIndex()}].L1_wr_a0`);
            let value = siggen(`Dmem_value_a0(${this.getIndex()})`);
            //
            let rd = dmem_rd_en.asBool() && dmem_rd_index.asInt() == this.getIndex();
            let mod = wr.asBool(false);
            let reg = parseInt(this.getIndex());
            let regIdent = reg.toString().padEnd(2, " ");
            let newValStr = (regIdent + ": ").padEnd(14, " ");
            let dmem_str = new fabric.Text((regIdent + ": " + value.asInt(NaN).toString(M4_VIZ_BASE)).padEnd(14, " "), {
               top: 18 * this.getIndex() - 40,
               left: 480,
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
            return {objects: [dmem_str]}
         }

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
         m4_define(['M4_IMEM_TOP'], ['m4_ifelse(m4_eval(M4_NUM_INSTRS > 16), 0, 0, m4_eval(0 - (M4_NUM_INSTRS - 16) * 18))'])
         initEach() {
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
            let missing_col1 = new fabric.Text("", {
                  top: 420,
                  left: -480,
                  fontSize: 16,
                  fontWeight: 500,
                  fontFamily: "monospace",
                  fill: "purple"
               })
            let missing_col2 = new fabric.Text("", {
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
               missing_col1,
               missing_col2,
              ],
              {visible: false}
            )
            return {missing_col1, missing_col2,
                    objects: {imem_box, decode_box, rf_box, dmem_box, imem_header, decode_header, rf_header, dmem_header, passed, missing_sigs}};
         },
         renderEach() {
            // Strings (2 columns) of missing signals.
            var missing_list = ["", ""]
            var missing_cnt = 0
            let sticky_zero = this.svSigRef(`sticky_zero`);  // A default zero-valued signal.
            // Attempt to look up a signal, using sticky_zero as default and updating missing_list if expected.
            siggen = (name, full_name, expected = true) => {
               var sig = this.svSigRef(full_name ? full_name : `L0_${name}_a0`)
               if (sig == null) {
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
                  if(sig != null && sig.asBool()) {
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
            let dmem_rd_index =   siggen_rf_dmem("dmem1_rd_index")
            let dmem_wr_en    =   siggen_rf_dmem("dmem1_wr_en")
            let dmem_wr_index =   siggen_rf_dmem("dmem1_wr_index")
            
            if (instr != sticky_zero) {
               this.getInitObjects().imem_box.setVisible(true)
               this.getInitObjects().imem_header.setVisible(true)
               this.getInitObjects().decode_box.setVisible(true)
               this.getInitObjects().decode_header.setVisible(true)
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
            let ld_arrow = new fabric.Line([490, 18 * dmem_rd_index.asInt() + 6 - 40, 168, 75 + 18 * 0], {
               stroke: "#b0c8df",
               strokeWidth: 2,
               visible: dmem_rd_en.asBool()
            })
            let st_arrow = new fabric.Line([490, 18 * dmem_wr_index.asInt() + 6 - 40, 190, 75 + 18 * 3], {
               stroke: "#b0b0df",
               strokeWidth: 3,
               visible: dmem_wr_en.asBool()
            })
            if (rf_rd_en1 != sticky_zero) {
               this.getInitObjects().rf_box.setVisible(true)
               this.getInitObjects().rf_header.setVisible(true)
            }
            if (dmem_rd_en != sticky_zero) {
               this.getInitObjects().dmem_box.setVisible(true)
               this.getInitObjects().dmem_header.setVisible(true)
            }
            
            
            // Instruction with values
            
            let regStr = (valid, regNum, regValue) => {
               return valid ? `r${regNum}` : `rX`  // valid ? `r${regNum} (${regValue})` : `rX`
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
                  load_viz.animate({left: 146, top: 70}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
                  setTimeout(() => {
                     load_viz.setVisible(false)
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
                  store_viz.setVisible(true)
                  store_viz.animate({left: 515, top: 18 * dmem_wr_index.asInt() - 40}, {
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
                  result_viz.setVisible(rf_wr_data != sticky_zero && rf_wr_en.asBool())
                  result_shadow.setVisible(result != sticky_zero)
                  result_viz.animate({left: 317 + 8 * 4, top: 18 * rf_wr_index.asInt(0) - 40}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
               }, 1000)
            }
            
            // Lab completion
            
            // Passed?
            this.getInitObject("passed").setVisible(false)
            if (passed) {
              if (passed.step(-1).asBool()) {
                this.getInitObject("passed").set({visible: true, text:"Passed !!!", fill: "green"})
              } else {
                // Using an unstable API, so:
                try {
                  passed.goTo(passed.signal.waveData.endCycle - 1)
                  if (passed.asBool()) {
                     this.getInitObject("passed").set({text:"Sim Passes", visible: true, fill: "lightgray"})
                  }
                } catch(e) {
                }
              }
            }
            
            // Missing signals
            if (missing_list[0]) {
               this.getInitObject("missing_sigs").setVisible(true)
               this.fromInit().missing_col1.setText(missing_list[0])
               this.fromInit().missing_col2.setText(missing_list[1])
            }
            return {objects: [pcPointer, pc_arrow, ...type_texts, rs1_arrow, rs2_arrow, rd_arrow, instrWithValues, fetch_instr_viz, src1_value_viz, src2_value_viz, result_shadow, result_viz, ld_arrow, st_arrow, load_viz, store_viz]};
         }
      
      /imem[m4_eval(M4_NUM_INSTRS-1):0]
         \viz_alpha
            initEach() {
              let binary = new fabric.Text("", {
                 top: M4_IMEM_TOP + 18 * this.getIndex(),
                 left: -680,
                 fontSize: 14,
                 fontFamily: "monospace",
                 
              })
              let disassembled = new fabric.Text("", {
                 top: M4_IMEM_TOP + 18 * this.getIndex(),
                 left: -350,
                 fontSize: 14,
                 fontFamily: "monospace"
              })
              return {objects: {binary, disassembled}}
            },
            renderEach() {
               // Instruction memory is constant, so just create it once.
               let reset = this.svSigRef(`L0_reset_a0`)
               let pc = this.svSigRef(`L0_pc_a0`)
               let rd_viz = pc && !reset.asBool() && (pc.asInt() >> 2) == this.getIndex()
               if (!global.instr_mem_drawn) {
                  global.instr_mem_drawn = []
               }
               if (!global.instr_mem_drawn[this.getIndex()]) {
                  global.instr_mem_drawn[this.getIndex()] = true
                  
                  let instr = this.svSigRef(`instrs(${this.getIndex()})`)
                  if (instr) {
                     let binary_str = instr.goTo(0).asBinaryStr("")
                     this.getInitObject("binary").setText(binary_str)
                  }
                  let disassembled = this.svSigRef(`instr_strs(${this.getIndex()})`)
                  if (disassembled) {
                     let disassembled_str = disassembled.goTo(0).asString("")
                     disassembled_str = disassembled_str.slice(0, -5)
                     this.getInitObject("disassembled").setText(disassembled_str)
                  }
               }
               this.getInitObject("disassembled").set({textBackgroundColor: rd_viz ? "#b0ffff" : "white"})
               this.getInitObject("binary")      .set({textBackgroundColor: rd_viz ? "#b0ffff" : "white"})
            }
      
\TLV tb()
   $passed_cond = (/xreg[30]$value == 32'b1) &&
                  (! $reset && $next_pc[31:0] == $pc[31:0]);
   *passed = >>2$passed_cond;

\TLV test_prog()
   // /=======================\
   // | Test each instruction |
   // \=======================/
   //
   // Some constant values to use as operands.
   m4_asm(ADDI, r1, r0, 10101)           // An operand value of 21.
   m4_asm(ADDI, r2, r0, 111)             // An operand value of 7.
   m4_asm(ADDI, r3, r0, 111111111100)    // An operand value of -4.
   // Execute one of each instruction, XORing subtracting (via ADDI) the expected value.
   // ANDI:
   m4_asm(ANDI, r5, r1, 1011100)
   m4_asm(XORI, r5, r5, 10101)
   // ORI:
   m4_asm(ORI, r6, r1, 1011100)
   m4_asm(XORI, r6, r6, 1011100)
   // ADDI:
   m4_asm(ADDI, r7, r1, 111)
   m4_asm(XORI, r7, r7, 11101)
   // ADDI:
   m4_asm(SLLI, r8, r1, 110)
   m4_asm(XORI, r8, r8, 10101000001)
   // SLLI:
   m4_asm(SRLI, r9, r1, 10)
   m4_asm(XORI, r9, r9, 100)
   // AND:
   m4_asm(AND, r10, r1, r2)
   m4_asm(XORI, r10, r10, 100)
   // OR:
   m4_asm(OR, r11, r1, r2)
   m4_asm(XORI, r11, r11, 10110)
   // XOR:
   m4_asm(XOR, r12, r1, r2)
   m4_asm(XORI, r12, r12, 10011)
   // ADD:
   m4_asm(ADD, r13, r1, r2)
   m4_asm(XORI, r13, r13, 11101)
   // SUB:
   m4_asm(SUB, r14, r1, r2)
   m4_asm(XORI, r14, r14, 1111)
   // SLL:
   m4_asm(SLL, r15, r2, r2)
   m4_asm(XORI, r15, r15, 1110000001)
   // SRL:
   m4_asm(SRL, r16, r1, r2)
   m4_asm(XORI, r16, r16, 1)
   // SLTU:
   m4_asm(SLTU, r17, r2, r1)
   m4_asm(XORI, r17, r17, 0)
   // SLTIU:
   m4_asm(SLTIU, r18, r2, 10101)
   m4_asm(XORI, r18, r18, 0)
   // LUI:
   m4_asm(LUI, r19, 0)
   m4_asm(XORI, r19, r19, 1)
   // SRAI:
   m4_asm(SRAI, r20, r3, 1)
   m4_asm(XORI, r20, r20, 111111111111)
   // SLT:
   m4_asm(SLT, r21, r3, r1)
   m4_asm(XORI, r21, r21, 0)
   // SLTI:
   m4_asm(SLTI, r22, r3, 1)
   m4_asm(XORI, r22, r22, 0)
   // SRA:
   m4_asm(SRA, r23, r1, r2)
   m4_asm(XORI, r23, r23, 1)
   // AUIPC:
   m4_asm(AUIPC, r4, 100)
   m4_asm(SRLI, r24, r4, 111)
   m4_asm(XORI, r24, r24, 10000000)
   // JAL:
   m4_asm(JAL, r25, 10)     // r25 = PC of next instr
   m4_asm(AUIPC, r4, 0)     // r4 = PC
   m4_asm(XOR, r25, r25, r4)  # AUIPC and JAR results are the same.
   m4_asm(XORI, r25, r25, 1)
   // JALR:
   m4_asm(JALR, r26, r4, 10000)
   m4_asm(SUB, r26, r26, r4)        // JALR PC+4 - AUIPC PC
   m4_asm(ADDI, r26, r26, 111111110001)  // - 4 instrs, + 1
   // SW & LW:
   m4_asm(SW, r2, r1, 1)
   m4_asm(LW, r27, r2, 1)
   m4_asm(XORI, r27, r27, 10100)
   // Write 1 to remaining registers prior to r30 just to avoid concern.
   m4_asm(ADDI, r28, r0, 1)
   m4_asm(ADDI, r29, r0, 1)
   // Terminate with success condition (regardless of correctness of register values):
   m4_asm(ADDI, r30, r0, 1)
   m4_asm(JAL, r0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   m4_asm_end()
   m4_define(['M4_MAX_CYC'], 70)

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
   m4_define(['M4_MAX_CYC'], 40)


// ^===================================================================^

\SV
   m4_makerchip_module  // (Expanded in Nav-TLV pane.)
\TLV
   // @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   // Possible choices for M4_LAB.
   // START, PC, IMEM, INSTR_TYPE, FIELDS, IMM, SUBSET_INSTRS, RF_MACRO, RF_READ, SUBSET_ALU, RF_WRITE, TAKEN_BR, BR_REDIR, TB,
   //    TEST_PROG, ALL_INSTRS, FULL_ALU, JUMP, LD_ST_ADDR, DMEM, LD_DATA, DONE
   m4_default(['M4_LAB'], M4_PC_LAB)
   // @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   /* Built for LAB: M4_LAB */

\SV
   endmodule
