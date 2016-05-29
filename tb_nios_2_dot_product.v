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
  $display("Memory Write Occured with addr:%h = %h",data_mem_addr,data_mem_wdata);
  end
  if (data_mem_rd) begin   
  data_mem_rdata <= #1 data_mem[data_mem_addr];
  $display("Memory read Occured with addr:%h = %h",data_mem_addr,data_mem[data_mem_addr]);
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
data_mem[16'h10] = 32'd0005; // Load it value minus one
data_mem[16'h20] = 32'd0005;
data_mem[16'h24] = 32'd0003;
data_mem[16'h28] = 32'd0006;
data_mem[16'h2C] = 32'd0019;
data_mem[16'h30] = 32'd0008;
data_mem[16'h34] = 32'd0012;
data_mem[16'h40] = 32'd0002;
data_mem[16'h44] = 32'd0014;
data_mem[16'h48] = 32'd0003;
data_mem[16'h4C] = 32'd0002;
data_mem[16'h50] = 32'd0005;
data_mem[16'h54] = 32'd0036;
data_mem[16'h82] = 32'h0009;
inst_mem[8'h0] = 32'b00000_00010_0000_0000_0010_0000_000100;  // addi $2,$0,20 ( A_VECTOR )
inst_mem[8'h4] = 32'b00000_00011_0000_0000_0100_0000_000100;  // addi $3,$0,40 ( B_VECTOR )
inst_mem[8'h8] = 32'b00000_00100_0000_0000_0001_0000_000100;  // addi $4,$0,10 ( Number )
inst_mem[8'hC] = 32'h00000001;  // Stall - 2 Due to data dependenct
inst_mem[8'h10] = 32'h00000001;  // Stall - 3 Due to data dependenct
inst_mem[8'h14] = 32'h00000001;  // Stall - 3 Due to data dependenct
inst_mem[8'h18] = 32'b00100_00100_0000_0000_0000_0000_010111;  // ldw $4,0($4)
inst_mem[8'h1C] = 32'b00000_00000_0010_1000_0011_0001_110001;  // add $5,$0,$0
inst_mem[8'h20] = 32'b00010_00110_0000_0000_0000_0000_010111;   // LOOP: LDW R6, 0(R2); 
inst_mem[8'h24] = 32'b00011_00111_0000_0000_0000_0000_010111;   //       LDW R7, 0(R3);  
inst_mem[8'h28] = 32'h00000001;  // Stall
inst_mem[8'h2C] = 32'h00000001;  // Stall - 1 Due to data dependenct
inst_mem[8'h30] = 32'h00000001;  // Stall - 2 Due to data dependenct
inst_mem[8'h34] = 32'h00000001;  // Stall - 3 Due to data dependenct
inst_mem[8'h38] = 32'b00110_00111_0100_0000_0010_0111_111010;   //       MUL R8, R6, R7
inst_mem[8'h3C] = 32'h00000001;  // Stall
inst_mem[8'h40] = 32'h00000001;  // Stall - 2 Due to data dependenct
inst_mem[8'h44] = 32'h00000001;  // Stall - 3 Due to data dependenct
inst_mem[8'h48] = 32'h00000001;  // Stall - 1 Due to data dependenct // Unneccesary stall can remove
inst_mem[8'h4C] = 32'b00101_01000_0010_1000_0011_0001_110001;   //       ADD R5, R5, R8
inst_mem[8'h50] = 32'b00010_00010_0000_0000_0000_0100_000100;   //       ADDI R2, R2, 4
inst_mem[8'h54] = 32'b00011_00011_0000_0000_0000_0100_000100;   //       ADDI R3, R3, 4
inst_mem[8'h58] = 32'b00100_00100_1111_1111_1111_1111_000100;   //       ADDI R4, R4, -1
inst_mem[8'h5C] = 32'b00000_00100_0000_0000_0010_0000_010110;   //       BLT R0, R4, LOOP
inst_mem[8'h60] = 32'h00000001;  // Stall - 1 Due to Control Hazard
inst_mem[8'h64] = 32'h00000001;  // Stall - 2 Due to Control Hazard
inst_mem[8'h68] = 32'h00000001;  // Stall - 2 Due to Control Hazard
inst_mem[8'h6C] = 32'b00000_00101_0000_0000_0000_0000_010101;   //       STW R5, DOT_PRODUCT(R0)
inst_mem[8'h70] = 32'h00000001;  // Stall - 1 Due to Control Hazard
//inst_mem[8'h74] = 32'h00000001;  // Stall - 2 Due to Control Hazard
//inst_mem[8'h78] = 32'h00000001;  // Stall - 2 Due to Control Hazard
//inst_mem[8'h7C] = 32'h208409FA;  // mult 2,2,4
//inst_mem[8'h80] = 32'hEFC00117;  // ldw 31,4(29)
//inst_mem[8'h84] = 32'hEF800217;  // ldw 30,8(29)
//inst_mem[8'h88] = 32'hEF400304;  // addi 29,29,12 
//inst_mem[8'h8C] = 32'h00000001;  // Stall - 1 Due to Control Hazard
//inst_mem[8'h90] = 32'h00000001;  // Stall - 2 Due to Control Hazard
//inst_mem[8'h94] = 32'h00000001;  // Stall - 2 Due to Control Hazard
//inst_mem[8'h98] = 32'hF800077A;  // Jump Instruction call subroutine jr $31
//inst_mem[8'h9C] = 32'h00000001;  // Stall - 2 Due to Control Hazard
//inst_mem[8'hA0] = 32'h00000001;  // Stall - 2 Due to Control Hazard
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

