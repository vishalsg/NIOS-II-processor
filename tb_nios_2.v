module tb_nios_2;

reg         clk,rst,enable;
reg  [31:0] inst_mem_o;
reg  [31:0] inst_mem [255:0];
reg  [31:0] data_mem_rdata;
wire [31:0] data_mem_addr;  // Data memory Address
wire [31:0] data_mem_wdata;  // Write Data
wire        data_mem_wr;    // Data memory Write Operation
wire        data_mem_rd;    // Data memory Read Operation
wire  [7:0]prog_count;
reg  [31:0] data_mem[0:65536];

always #5 clk = ~clk;

always @ (posedge clk)
begin
  if (enable)
  begin
    inst_mem_o <= #1 inst_mem[prog_count];
  end
  else
  begin
    inst_mem_o <= #1 inst_mem_o;
  end
end

always @ (posedge clk)
begin
  if (data_mem_wr) begin
    data_mem[data_mem_addr] <= #1 data_mem_wdata;
  $display("Memory Write Occured @ %0t with addr:%h = %h",$realtime,data_mem_addr,data_mem_wdata);
  end
  if (data_mem_rd) begin   
  data_mem_rdata <= #1 data_mem[data_mem_addr];
  $display("Memory Read  Occured @ %0t with addr:%h = %h",$realtime,data_mem_addr,data_mem[data_mem_addr]);
  end
end

initial
begin
 $dumpfile("nios2.vcd");
 $dumpvars("0");
end


initial
begin
clk = 0;
rst = 1;
enable = 0;
data_mem_rdata = 32'h0000;
data_mem[16'h82] = 32'h0009;
inst_mem[8'h0] = 32'h00400044;  // addi $1,$0,0
inst_mem[8'h4] = 32'h01000826;   // beq 4,0,return1
inst_mem[8'h8] = 32'h00000001;  // Stall - 1 Due to data dependenct
inst_mem[8'h0C] = 32'h0900091E;  // bne 4,1,continue
inst_mem[8'h10] = 32'h00000001;  // Stall - 2 Due to data dependenct
inst_mem[8'h14] = 32'h00000001;  // Stall - 3 Due to data dependenct
inst_mem[8'h18] = 32'h00000001;  // Stall - 1 Due to data dependenct
inst_mem[8'h1C] = 32'h00000001;  // Stall - 2 Due to data dependenct
inst_mem[8'h20] = 32'h00000001;  // Stall - 3 Due to data dependenct
inst_mem[8'h24] = 32'h08800004;  // addi 2,1,0
inst_mem[8'h28] = 32'hF800077A;  // Jump Instruction call subroutine jr $31
inst_mem[8'h2C] = 32'h00000001;  // Stall - 1 Due to data dependenct
inst_mem[8'h30] = 32'h00000001;  // Stall - 2 Due to data dependenct
inst_mem[8'h34] = 32'h00000001;  // Stall - 3 Due to data dependenct
inst_mem[8'h38] = 32'hEF7FFD04;  // addi 29,29,-12 LAbel:continue
inst_mem[8'h3C] = 32'hEF800215;  // stw 30,8(29)
inst_mem[8'h4C] = 32'h00000001;  // Stall - 2 Due to data dependenct
inst_mem[8'h44] = 32'h00000001;  // Stall - 3 Due to data dependenct
inst_mem[8'h48] = 32'h00000001;  // Stall - 1 Due to data dependenct // Unneccesary stall can remove
inst_mem[8'h40] = 32'hEFC00115;  // stw 31,4(29)
inst_mem[8'h50] = 32'hEF800204;  // addi 30,29,8
inst_mem[8'h54] = 32'hE9000015;  // stw 4,0(29)
inst_mem[8'h58] = 32'h213FFFC4;  // addi 4,4,-1
inst_mem[8'h5C] = 32'h00000000;  // jal fact
inst_mem[8'h60] = 32'h00000001;  // Stall - 1 Due to Control Hazard
inst_mem[8'h64] = 32'h00000001;  // Stall - 2 Due to Control Hazard
inst_mem[8'h68] = 32'h00000001;  // Stall - 2 Due to Control Hazard
inst_mem[8'h6C] = 32'hE9000017;  // ldw 4,0(29)
inst_mem[8'h70] = 32'h00000001;  // Stall - 1 Due to Control Hazard
inst_mem[8'h74] = 32'h00000001;  // Stall - 2 Due to Control Hazard
inst_mem[8'h78] = 32'h00000001;  // Stall - 2 Due to Control Hazard
inst_mem[8'h7C] = 32'h208409FA;  // mult 2,2,4
inst_mem[8'h80] = 32'hEFC00117;  // ldw 31,4(29)
inst_mem[8'h84] = 32'hEF800217;  // ldw 30,8(29)
inst_mem[8'h88] = 32'hEF400304;  // addi 29,29,12 
inst_mem[8'h8C] = 32'h00000001;  // Stall - 1 Due to Control Hazard
inst_mem[8'h90] = 32'h00000001;  // Stall - 2 Due to Control Hazard
inst_mem[8'h94] = 32'h00000001;  // Stall - 2 Due to Control Hazard
inst_mem[8'h98] = 32'hF800077A;  // Jump Instruction call subroutine jr $31
inst_mem[8'h9C] = 32'h00800115;  // ldw 2,4(0)
inst_mem[8'hA0] = 32'h00000001;  // Stall - 2 Due to Control Hazard
//inst_mem[8'h14] = 32'h21400144;
// inst_mem[8'h18] = 32'h00000200;
// orig inst_mem[0] = 32'b00000001010000000001100100010101;
// orig inst_mem[1] = 32'b00101010000010111000100000110001;
// orig inst_mem[5] = 32'b00101010000010111000100000110001;
// orig inst_mem[6] = 32'b00010001100000000010000000010111;
// orig inst_mem[3] = 32'b00000000100000000000000000110100;
// orig inst_mem[4] = 32'b00010000100000000000010100010100;
// orig inst_mem[2] = 32'b00000001010000000000000000010110;
//inst_mem[5] = 32'b00010000100000000000000100000100;
//inst_mem[6] = 32'b00000001000000000000100000010110;
// orig inst_mem[7] = 32'b00110001110100010011100000111010;
// orig inst_mem[8] = 32'h20000126;
inst_mem[9] = 32'h00000001;
inst_mem_o = 32'h00000001;
#5 rst = 0;
#20 rst = 1;
#5 enable = 1;
#2350 enable = 0;

#200 $finish;
end

nios_2 nios_2_inst ( .clk(clk),
                     .rst(rst),
                     .enable(enable),
                     .inst_fetch(inst_mem_o),
                     .prog_count_o(prog_count),
                     .data_mem_wr_o(data_mem_wr),    // Data memory Write Operation
                     .data_mem_rd_o(data_mem_rd),    // Data memory Read Operation
                     .data_mem_addr_o(data_mem_addr),  // Data memory Address
                     .data_mem_wdata_o(data_mem_wdata),  // Write Data
                     .data_mem_rdata_i(data_mem_rdata)
);


endmodule

