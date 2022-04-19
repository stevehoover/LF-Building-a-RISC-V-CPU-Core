\m4_TLV_version 1d: tl-x.org
\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */

// Visualization for calculator
\TLV calc_viz()
   \SV_plus
      logic sticky_zero;
      assign sticky_zero = 0;
   /view
      \viz_js
         box: {strokeWidth: 0},
         init() {
            let hexcalname = new fabric.Text("HEX Calc 3000", {
              left: -150 + 150,
              top: -150 + 40,
              textAlign: "center",
              fontSize: 22,
              fontWeight: 600,
              fontFamily: "Timmana",
              fontStyle: "italic",
              fill: "#ffffff",
            })
            let calbox = new fabric.Rect({
              left: -150,
              top: -130,
              fill: "#665d60",
              width: 316,
              height: 366,
              strokeWidth: 3,
              stroke: "#a0a0a0",
            })
            let val1box = new fabric.Rect({
              left: -150 + 82,
              top: -150 + 83,
              fill: "#d0d8e0",
              width: 214,
              height: 40,
              strokeWidth: 5,
              stroke: "#608080",
            })
            let val1num = new fabric.Text("--------", {
              left: -150 + 185,
              top: -150 + 83 + 8,
              textAlign: "right",
              fill: "#505050",
              fontSize: 22,
              fontFamily: "Courier New",
            })
            let val2box = new fabric.Rect({
              left: -150 + 187,
              top: -150 + 221,
              fill: "#d0d8e0",
              width: 109,
              height: 40,
              strokeWidth: 1,
              stroke: "#303030",
            })
            let val2num = new fabric.Text("--------", {
              left: -150 + 185,
              top: -150 + 221 + 8,
              textAlign: "right",
              fill: "#505050",
              fontSize: 22,
              fontFamily: "Courier New",
            })
            let outbox = new fabric.Rect({
              left: -150 + 97,
              top: -150 + 310,
              fill: "#d0d8e0",
              width: 199,
              height: 40,
              strokeWidth: 1,
              stroke: "#303030",
            })
            let outnum = new fabric.Text("--------", {
              left: -150 + 185,
              top: -150 + 310 + 8,
              textAlign: "right",
              fill: "#505050",
              fontSize: 22,
              fontFamily: "Courier New",
            })
            let equalname = new fabric.Text("=", {
              left: -150 + 38,
              top: -150 + 316,
              fontSize: 28,
              fontFamily: "Courier New",
            })
            let sumbox = new fabric.Rect({
              left: -150 + 28,
              top: -150 + 148,
              fill: "#a0a0a0",
              width: 64,
              height: 64,
              strokeWidth: 1,
              stroke: "#b0b0b0",
            })
            let prodbox = new fabric.Rect({
              left: -150 + 28,
              top: -150 + 222,
              fill: "#a0a0a0",
              width: 64,
              height: 64,
              strokeWidth: 1,
              stroke: "#b0b0b0",
            })
            let minbox = new fabric.Rect({
              left: -150 + 105,
              top: -150 + 148,
              fill: "#a0a0a0",
              width: 64,
              height: 64,
              strokeWidth: 1,
              stroke: "#b0b0b0",
            })
            let quotbox = new fabric.Rect({
              left: -150 + 105,
              top: -150 + 222,
              fill: "#a0a0a0",
              width: 64,
              height: 64,
              strokeWidth: 1,
              stroke: "#b0b0b0",
            })
            let sumicon = new fabric.Text("+", {
              left: -150 + 28 + 26,
              top: -150 + 148 + 22,
              fontSize: 22,
              fontFamily: "Times",
            })
            let prodicon = new fabric.Text("*", {
              left: -150 + 28 + 26,
              top: -150 + 222 + 22,
              fontSize: 22,
              fontFamily: "Courier New",
            })
            let minicon = new fabric.Text("-", {
              left: -150 + 105 + 26,
              top: -150 + 148 + 22,
              fontSize: 22,
              fontFamily: "Courier New",
            })
            let quoticon = new fabric.Text("/", {
              left: -150 + 105 + 26,
              top: -150 + 222 + 22,
              fontSize: 22,
              fontFamily: "Courier New",
            })
            this.missing = new fabric.Text("", {
                  top: 360,
                  left: -160,
                  fontSize: 16,
                  fontWeight: 500,
                  fontFamily: "monospace",
                  fill: "purple"
               })
            let missing_sigs = new fabric.Group(
               [new fabric.Text("🚨 Missing Signals", {
                  top: 290,
                  left: -80,
                  fontSize: 18,
                  fontWeight: 800,
                  fill: "red",
                  fontFamily: "monospace"
                }),
                new fabric.Rect({
                  top: 340,
                  left: -180,
                  fill: "#ffffe0",
                  width: 400,
                  height: 300,
                  stroke: "black"
                }),
                this.missing
               ],
               {visible: false}
              )
            
            return {calbox, val1box, val1num, val2box, val2num,
                    outbox, outnum, equalname, sumbox, minbox, prodbox, quotbox, sumicon,
                    prodicon, minicon: minicon, quoticon: quoticon, hexcalname, missing_sigs}
         },
         render() {
            let missing_list = "";
            let sig_names = ["op", "val1", "val2", "out"];
            let sticky_zero = this.svSigRef(`sticky_zero`);
            getSig = (name) => {
               let sig = this.svSigRef(`L0_${name}_a0`);
               if (sig == null || !sig.exists()) {
                  missing_list += `◾ $${name}      \n`;
                  sig         = sticky_zero;
               }
               return sig;
            }
            var sigs = sig_names.reduce(function(result, sig_name, index) {
               result[sig_name] = getSig(sig_name)
               return result
            }, {})
            this.getObjects().val1num.set({text: sigs.val1.asInt(NaN).toString(16).padStart(8, " ")})
            this.getObjects().val2num.set({text: sigs.val2.asInt(NaN).toString(16).padStart(8, " ")})
            this.getObjects().outnum.set({text: sigs.out.asInt(NaN).toString(16).padStart(8, " ")})
            let op = sigs.op.asInt(NaN)
            this.getObjects().sumbox.set({fill: op == 0 ?  "#c0d0e0" : "#a0a0a0"})
            this.getObjects().minbox.set({fill: op == 1 ?  "#c0d0e0" : "#a0a0a0"})
            this.getObjects().prodbox.set({fill: op == 2 ? "#c0d0e0" : "#a0a0a0"})
            this.getObjects().quotbox.set({fill: op == 3 ? "#c0d0e0" : "#a0a0a0"})
            if (missing_list) {
               this.getObjects().calbox.set({fill: "red"})
               this.getObjects().missing_sigs.set({visible:true})
               this.missing.set({text: missing_list})
            }
         }
\TLV

   $val1[31:0] = {26'b0, $val1_rand[5:0]};
   $val2[31:0] = {28'b0, $val2_rand[3:0]};
   
   $sum[31:0] = $val1 + $val2;
   $diff[31:0] = $val1 - $val2;
   $prod[31:0] = $val1 * $val2;
   $quot[31:0] = $val1 / $val2;
   
   $out[31:0] = $op[1:0] == 2'b00 ? $sum :
                $op == 2'b01 ? $diff :
                $op == 2'b10 ? $prod :
                               $quot;  // Default, same as 2'b11.
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
   
   m4+calc_viz()
\SV
   endmodule
