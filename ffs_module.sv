`timescale 1 ns / 100 ps
`default_nettype none

module ffs_tree
  #(parameter N_CANDIDATES = 8)
  (
   input logic [N_CANDIDATES-1:0]          i_data,
   output logic [$clog2(N_CANDIDATES)-1:0] o_data
   );
  // barrel shifter
  logic [$clog2(N_CANDIDATES)-1:0][N_CANDIDATES-1:0] i_data_bs;
  logic [$clog2(N_CANDIDATES)-1:0]                   o_data_i;

  generate for (genvar i = 0; i < $clog2(N_CANDIDATES); i++) begin
    if (i == 0) begin
      always_comb begin
        if (|(i_data[$high(i_data)-:N_CANDIDATES/2])) begin
          i_data_bs[i] = i_data;
          o_data_i[i] = 'b0;
        end else begin
          // shift left
          i_data_bs[i] = i_data << (N_CANDIDATES/2);
          o_data_i[i] = 'b1;
        end
      end
    end else begin
      always_comb begin
        if (|(i_data_bs[i-1][$high(i_data)-:N_CANDIDATES/(2**(i+1))])) begin
          i_data_bs[i] = i_data_bs[i-1];
          o_data_i[i] = 'b0;
        end else begin
          // shift left
          i_data_bs[i] = i_data_bs[i-1] << (N_CANDIDATES/(2**(i+1)));
          o_data_i[i] = 'b1;
        end
      end
    end
  end endgenerate
  always_comb begin
    o_data = {<<{o_data_i}};
  end
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
      o_data = 'd0;
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
    o_data = '0;
    for (logic [$clog2(N_CANDIDATES):0] i = 0; i < N_CANDIDATES; i++) begin
      if (i_data[N_CANDIDATES - 1 - i[$clog2(N_CANDIDATES)-1:0]] == 1'b1) begin
        o_data = i[$clog2(N_CANDIDATES)-1:0];
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
