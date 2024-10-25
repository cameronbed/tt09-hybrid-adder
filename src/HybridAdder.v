/* (c) Krishna Subramanian <https://github.com/mongrelgem>
 * For Issues & Bugs, report to <https://github.com/mongrelgem/Verilog-Adders/issues>
*/
module BigCircle(output G, output P, input Gi, input Pi, input GiPrev, input PiPrev);
  wire e;
  and #(1) (e, Pi, GiPrev);
  or #(1) (G, e, Gi);
  and #(1) (P, Pi, PiPrev);
endmodule

module HA8(output [7:0] sum, output cout, input [7:0] a, input [7:0] b);
  wire [3:0] sum_cla, sum_ksa;
  wire cout_cla, cout_ksa;

  // KSA + CLA
  CLA4 cla4(sum_cla, cout_cla, a[3:0], b[3:0], 1'b0);
  KSA4 ksa4(sum_ksa, cout_ksa, a[7:4], b[7:4], cout_cla);

  assign sum = {sum_ksa, sum_cla};
  assign cout = cout_ksa;
endmodule

module CLA4(output [3:0] sum, output cout, input [3:0] a, input [3:0] b, input cin);
  wire [3:0] g, p, c;
  wire [9:0] e;
  genvar i;

  // PGGen instances
  generate
    for (i = 0; i < 4; i = i + 1) begin : pggen_inst
      PGGen pggen(g[i], p[i], a[i], b[i]);
    end
  endgenerate

  // c[0]
  and #(1) (e[0], cin, p[0]);
  or #(1) (c[0], e[0], g[0]);

  // c[1]
  and #(1) (e[1], cin, p[0], p[1]);
  and #(1) (e[2], g[0], p[1]);
  or #(1) (c[1], e[1], e[2], g[1]);

  // c[2]
  and #(1) (e[3], cin, p[0], p[1], p[2]);
  and #(1) (e[4], g[0], p[1], p[2]);
  and #(1) (e[5], g[1], p[2]);
  or #(1) (c[2], e[3], e[4], e[5], g[2]);

  // c[3]
  and #(1) (e[6], cin, p[0], p[1], p[2], p[3]);
  and #(1) (e[7], g[0], p[1], p[2], p[3]);
  and #(1) (e[8], g[1], p[2], p[3]);
  and #(1) (e[9], g[2], p[3]);
  or #(1) (c[3], e[6], e[7], e[8], e[9], g[3]);

  // XOR for sum
  xor #(2) (sum[0], p[0], cin);
  generate
    for (i = 1; i < 4; i = i + 1) begin : xor_inst
      xor #(2) (sum[i], p[i], c[i-1]);
    end
  endgenerate

  buf #(1) (cout, c[3]);
endmodule

module KSA4(output [3:0] sum, output cout, input [3:0] a, input [3:0] b, input cin);
  wire [3:0] c;
  wire [3:0] g0, p0; // Initial generate and propagate
  wire [3:0] g1, p1; // First stage
  wire [3:0] g2, p2; // Second stage
  genvar i;

  // Generate initial g and p
  generate
    for (i = 0; i < 4; i = i + 1) begin : gp_gen
      assign g0[i] = a[i] & b[i];
      assign p0[i] = a[i] ^ b[i];
    end
  endgenerate

  // Include cin in the first carry
  assign c[0] = g0[0] | (p0[0] & cin);

  // Initialize g1[0] and p1[0]
  assign g1[0] = g0[0];
  assign p1[0] = p0[0];

  // First stage of computation
  generate
    for (i = 1; i < 4; i = i + 1) begin : stage1
      assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
      assign p1[i] = p0[i] & p0[i-1];
    end
  endgenerate

  // Second stage of computation
  assign g2[0] = g1[0];
  assign p2[0] = p1[0];

  assign g2[1] = g1[1];
  assign p2[1] = p1[1];

  assign g2[2] = g1[2] | (p1[2] & g1[0]);
  assign p2[2] = p1[2] & p1[0];

  assign g2[3] = g1[3] | (p1[3] & g1[1]);
  assign p2[3] = p1[3] & p1[1];

  // Compute carries
  assign c[1] = g2[1] | (p2[1] & c[0]);
  assign c[2] = g2[2] | (p2[2] & c[0]);
  assign c[3] = g2[3] | (p2[3] & c[0]);

  // Sum calculation
  assign sum[0] = p0[0] ^ cin;
  generate
    for (i = 1; i < 4; i = i + 1) begin : sum_gen
      assign sum[i] = p0[i] ^ c[i-1];
    end
  endgenerate

  assign cout = c[3];
endmodule


module PGGen(output g, output p, input a, input b);
  and #(1) (g, a, b);
  xor #(2) (p, a, b);
endmodule

module SmallCircle(output Ci, input Gi);
  buf #(1) (Ci, Gi);
endmodule

module Square(output G, output P, input Ai, input Bi);
  and #(1) (G, Ai, Bi);
  xor #(2) (P, Ai, Bi);
endmodule

module Triangle(output Si, input Pi, input CiPrev);
  xor #(2) (Si, Pi, CiPrev);
endmodule
