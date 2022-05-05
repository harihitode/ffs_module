#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vffs_module.h"

unsigned int main_time = 0;

double sc_time_stamp() {
  return main_time;
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  Vffs_module *top = new Vffs_module();
  VerilatedVcdC *tfp = new VerilatedVcdC;

  top->trace(tfp, 99);
  tfp->open("wave.vcd");
  printf("simulation has been started\n");

  const int candidates = 16;
  for (int i = 1; i < candidates; i++) {
    top->i_data = i;
    top->eval();
    tfp->dump(main_time++);
    printf("[input] 0b");
    for (int j = 8 - 1; j >= 0; j--) {
      if ((1 << j) & i) {
        putchar('1');
      } else {
        putchar('0');
      }
    }
    putchar(' ');
    printf("[forloop] %d, [queue] %d, [tree] %d\n",
           top->o_data_forloop,
           top->o_data_queue,
           top->o_data_tree);
  }
  printf("simulation finished\n");
  tfp->close();
  top->final();
  return 0;
}
