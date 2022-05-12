`timescale 1 ns / 100 ps
`default_nettype none

module ffs_tree
  #(parameter N_CANDIDATES = 8)
  (
   input logic [N_CANDIDATES-1:0]          i_data,
   output logic [$clog2(N_CANDIDATES)-1:0] o_data
   );
  logic [$clog2(N_CANDIDATES)-1:0]                   flag;
  logic [N_CANDIDATES/2-1:0]                         cands [$clog2(N_CANDIDATES)];

  generate for (genvar i = 0; i < $clog2(N_CANDIDATES); i++) begin
    for (genvar j = 0; j < N_CANDIDATES/2; j++) begin
      always_comb begin
        // width: N_CANDIDATES/(2**(i+1))
        // N_CANDIDATES - (N_CANDIDATES/(2**i)) * ((N_CANDIDATES/2 - j - 1)%(2**i))-1
        // head:  N_CANDIDATES - (N_CANDIDATES/(2**i)) * (j%(2**i)) - 1
        // (N_CANDIDATES/2-j-1)%(2**1) case 8
        /// i(level) = 0: 0, 0, 0, 0
        /// i(level) = 1: 1, 0, 1, 0
        /// i(level) = 2: 3, 2, 1, 0
        cands[i][j] = |i_data[N_CANDIDATES - (N_CANDIDATES/(2**i)) * ((N_CANDIDATES/2 - j - 1)%(2**i))-1-:N_CANDIDATES/(2**(i+1))];
      end
    end
  end endgenerate

  always_comb begin
    flag = '0;
    for (int i = 0; i < $clog2(N_CANDIDATES); i++) begin
      flag = {flag[$high(flag)-1:0], cands[i][flag[$high(flag)-1:0]]};
    end
  end

  assign o_data = ~flag;
endmodule

module ffs_queue
  #(parameter N_CANDIDATES = 8)
  (
   input logic [N_CANDIDATES-1:0]          i_data,
   output logic [$clog2(N_CANDIDATES)-1:0] o_data
   );
  always_comb begin
    automatic logic q [$];
    automatic int   qu [$];
    automatic int   count;
    q.delete();
    for (int i = 0; i < N_CANDIDATES; i++) begin
      q.push_back(i_data[$high(i_data) - i]);
    end
    qu = q.find_first_index with (item == 1'b1);
    count = qu.size();
    if (count == 0) begin
      // $display("every field is unset");
      o_data = '1;
    end else begin
      o_data = ($clog2(N_CANDIDATES))'(qu.pop_front());
    end
  end
endmodule

module ffs_forloop
  #(parameter N_CANDIDATES = 8)
  (
   input logic [N_CANDIDATES-1:0]          i_data,
   output logic [$clog2(N_CANDIDATES)-1:0] o_data
   );
  always_comb begin
    for (int i = 0; i < N_CANDIDATES; i++) begin
      o_data = i[$clog2(N_CANDIDATES)-1:0];
      if (i_data[$high(i_data) - i] == 1'b1) begin
        break;
      end
    end
  end
endmodule

module ffs_module
  #(parameter N_CANDIDATES = 8)
  (
   input logic [N_CANDIDATES-1:0]          i_data,
   output logic [$clog2(N_CANDIDATES)-1:0] o_data_forloop,
   output logic [$clog2(N_CANDIDATES)-1:0] o_data_queue,
   output logic [$clog2(N_CANDIDATES)-1:0] o_data_tree
   );

  initial begin: CONFIG_CHECK
    assert (N_CANDIDATES % 2 == 0) else $fatal(0, "N_CANDIDATES should be power of 2.");
  end

  ffs_queue #(.N_CANDIDATES(N_CANDIDATES))
  FFS_Q (.i_data(i_data), .o_data(o_data_queue));

  ffs_forloop #(.N_CANDIDATES(N_CANDIDATES))
  FFS_F (.i_data(i_data), .o_data(o_data_forloop));

  ffs_tree #(.N_CANDIDATES(N_CANDIDATES))
  FFS_T (.i_data(i_data), .o_data(o_data_tree));
endmodule

`default_nettype wire
