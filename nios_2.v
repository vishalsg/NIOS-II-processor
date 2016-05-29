module nios_2 (
input clk,
input rst,
input enable,  // Enables Nios2
input  [31:0] inst_fetch,
output wire [7:0] prog_count_o,
output wire        data_mem_wr_o,    // Data memory Write Operation
output wire        data_mem_rd_o,    // Data memory Read Operation
output wire [31:0] data_mem_addr_o,  // Data memory Address
output wire [31:0] data_mem_wdata_o,  // Write Data
input       [31:0] data_mem_rdata_i   // Data Memory Read Data
);

wire  [7:0] prog_count_c;
wire  [5:0] opcode_c;  // Opcode extraction from memory Fetch
wire [10:0] opcode_ext_c;  // Opcode Extension for R-type
wire [31:0] immi_val_c;  // Sign extended immidiate value
wire  [4:0] rega_addr_c; // Address of Register A
wire  [4:0] regb_addr_c; // Address of Register B
wire  [4:0] regc_addr_c; // Address of Register C
reg   [4:0] rega_addr; // Address of Register A for execute Stage
reg   [4:0] regb_addr; // Address of Register B for execute Stage
reg   [4:0] regc_addr; // Address of Register C for execute Stage
reg   [4:0] rega_addr_mem; //Address of Register A for memory Stage
reg   [4:0] regb_addr_mem; //Address of Register B for memory Stage
reg   [4:0] regc_addr_mem; //Address of Register C for memory Stage
reg   [4:0] rega_addr_wb; //Address of Register A for Write back Stage
reg   [4:0] regb_addr_wb; //Address of Register B for Write back Stage
reg   [4:0] regc_addr_wb; //Address of Register C for Write back Stage
reg         forwarding;   // Indicates Forwarding for data hazard
wire [31:0] twos_comp;  // Two's compliment for addition
wire [31:0] alu_op_c;  // ALU Operation Output
wire  [1:0] alu_opr_c; // ALU Operation 00 -- No Operation
                       //               01 -- Addition
                       //               10 -- Substraction
                       //               11 -- Multiplication
wire        mem_op_c;       // Data Memory Operation

wire        wb_exec;      // Write Back Stage Need Execution
wire [31:0] wb_data;      // Write Back State Data
wire  [4:0] wb_reg_addr;  // Write Back Stage Address of register
wire        cmp_op_c;     // Comparision Operation
wire        branch_taken; // Indicates Branch is taken
wire        equ_chk_c;    // Equality Check Operation
wire        non_equ_c;    // Non Equality Check Operation
wire        uncnd_jmp_inst_r_typ; // Unconditional Jump Instruction R-type
wire        uncnd_jmp_inst_j_typ; // Unconditional Jump Instruction J-type
// wire        wr_prog_cnt_c;        // Write back programme counter to Register 31

reg [31:0] reg_mem [31:0];
reg  [7:0] prog_count;
reg  [7:0] prog_count_de; // Program Count in Decode Stage
reg  [7:0] prog_count_ex; // Program Count in Execution Stage
reg  [5:0] opcode_ex;   // Opcode for Execution Stage
reg  [5:0] opcode_mem;  // Opcode for Memory Stage
reg [10:0] opcode_ext_ex;  // Opcode Extension for R-type execution Stage
reg [10:0] opcode_ext_mem;  // Opcode Extension for R-type Memory Stage
reg [31:0] immi_val;    // Immidiate value for Execution stage
reg [31:0] regA;        // Register to be used in Execution Stage
reg [31:0] regB;        // Register to be used in Execution Stage
reg [31:0] regC;        // Register to be used in Execution Stage
reg [31:0] regA_mem;    // Register to be used in Memory Stage
reg [31:0] regB_mem;    // Register to be used in Memory Stage
reg [31:0] regC_mem;    // Register to be used in Memory Stage
reg [31:0] alu_op;      // ALU Output Registed version
reg [31:0] alu_op_wb;   // ALU Output Registed version for use in Write Back Stage
reg        i_type;      // I-Type instruction flag is used for Execution stage
reg        j_type;      // J-Type instruction flag is used for Execution stage
reg        r_type;      // R-Type instruction flag is used for Execution stage
reg        i_type_mem; // I-Type instruction flag is used for Memory stage
reg        j_type_mem; // J-Type instruction flag is used for Memory stage
reg        r_type_mem; // R-Type instruction flag is used for Memory stage
reg        i_type_wb; // I-Type instruction flag is used for Write Back stage
reg        j_type_wb; // J-Type instruction flag is used for Write Back stage
reg        r_type_wb; // R-Type instruction flag is used for Write Back stage
reg        data_mem_rd_d;
//-------------------------------------------
// Instruction Fetch
//-------------------------------------------

assign prog_count_o = prog_count;

assign prog_count_c={8{enable & !branch_taken & !uncnd_jmp_inst_r_typ & !uncnd_jmp_inst_j_typ}} & (prog_count + 8'h04)  |
                    {8{enable & !branch_taken &  uncnd_jmp_inst_r_typ}} & (regA)                |
                    {8{enable & !branch_taken &  uncnd_jmp_inst_j_typ}} & (immi_val)            |
                    {8{enable &  branch_taken &  cmp_op_c}} & (immi_val)                        |
                    {8{enable &  branch_taken }} & (alu_op_c)            | 
                    {8{~enable}} & prog_count;


assign opcode_c = inst_fetch[5:0];

assign i_type_c = ( (opcode_c == 6'h04) |
                    (opcode_c == 6'h15) |
                    (opcode_c == 6'h16) |
                    (opcode_c == 6'h17) |
                    (opcode_c == 6'h1E) |
                    (opcode_c == 6'h26));
 
assign j_type_c = (opcode_c == 6'h06) |
                  (opcode_c == 6'h00);

assign r_type_c = ( (opcode_c == 6'h3A) |
                    (opcode_c == 6'h31));

//-------------------------------------------
// Instruction Decode/ Register Fetch
//-------------------------------------------
assign rega_addr_c = {5{(i_type_c | r_type_c)}} & inst_fetch[31:27];

assign regb_addr_c = {5{(i_type_c | r_type_c)}} & inst_fetch[26:22];

assign regc_addr_c = {5{r_type_c}} & inst_fetch[21:17] |
                     {5{(opcode_c == 6'h00)}} & 6'h1F;  // Add code for opcode extension

assign immi_val_c = {32{i_type_c}} & {{16{inst_fetch[21]}}, inst_fetch[21:6]} |
                    {32{j_type_c}} & {5'h00,inst_fetch[31:6]};

assign opcode_ext_c = {11{r_type_c}} & inst_fetch[16:6];




//-------------------------------------------
// Execution Stage
//-------------------------------------------

assign cmp_op_c =  (opcode_ex == 6'h16);

assign equ_chk_c =  (opcode_ex == 6'h26);  // Equality Check

assign non_equ_c = (opcode_ex == 6'h1E);  // Non Equality Check

assign alu_opr_c = {2{((opcode_ex == 6'h31) | 
                       (opcode_ex == 6'h04 & !immi_val[31]) | 
                       (opcode_ex == 6'h15) | 
                       (opcode_ex == 6'h1E) | 
                       (opcode_ex == 6'h26) | 
                       (opcode_ex == 6'h00) | 
                       (opcode_ex == 6'h17))}} & 2'b01 |
                   {2{(opcode_ex == 6'h04 & immi_val[31])}} & 2'b10 | 
                   {2{((opcode_ex == 6'h3A) & (opcode_ext_ex == 6'h27))}} & 2'b11;

assign branch_taken = ((cmp_op_c)  & (regB > regA))  |
                      ((non_equ_c) & (regB != regA)) |
                      ((equ_chk_c) & (regB == regA));

assign uncnd_jmp_inst_r_typ = ((opcode_ex == 6'h3A) & (opcode_ext_ex == 6'h1D));  // Unconditional Jump Instruction R-type
assign uncnd_jmp_inst_j_typ = (opcode_ex == 6'h00);  // Unconditional Jump Instruction J-type
// assign wr_prog_cnt_c = (opcode_ex == 6'h00);         // Write back programme counter to Register 31
assign twos_comp = ((~immi_val) + 1'b1);             // Two's compliment for addition

assign alu_op_c = {32{(alu_opr_c == 2'b01) & i_type & !branch_taken}} & (regA + immi_val) |
                  {32{(alu_opr_c == 2'b01) & i_type &  branch_taken}} & (prog_count_ex + immi_val) |
                  {32{(alu_opr_c == 2'b01) & uncnd_jmp_inst_j_typ}} & (prog_count_ex + 32'h04) |
                  {32{(alu_opr_c == 2'b01) & r_type}} & (regA + regB)     |
                  {32{(alu_opr_c == 2'b10) & i_type}} & (regA - twos_comp)  |
                  {32{(alu_opr_c == 2'b11) & i_type}} & (regA * immi_val) |
                  {32{(alu_opr_c == 2'b11) & r_type}} & (regA * regB);

//-------------------------------------------
// Memory Stage
//-------------------------------------------

assign mem_op_c         = (data_mem_rd_o | data_mem_wr_o);
assign data_mem_rd_o    = (opcode_mem == 6'h17);
assign data_mem_wr_o    = (opcode_mem == 6'h15);
assign data_mem_addr_o  = {32{mem_op_c}} & alu_op;
assign data_mem_wdata_o = {32{mem_op_c}} & regB_mem;

assign i_type_wb_c = (i_type_mem & (opcode_mem == 6'h04));
assign j_type_wb_c = (j_type_mem & (opcode_mem == 6'h00));


//-------------------------------------------
// Write Back Stage
//-------------------------------------------

assign wb_exec     =  data_mem_rd_d | r_type_wb | i_type_wb | j_type_wb;
assign wb_data     = {32{data_mem_rd_d}} & data_mem_rdata_i |
                     {32{r_type_wb | i_type_wb | j_type_wb}}     & alu_op_wb;
assign wb_reg_addr = {5{data_mem_rd_d | i_type_wb}} & regb_addr_wb |
                     {5{r_type_wb | j_type_wb}}     & regc_addr_wb;


always @ (posedge clk or negedge rst)
begin
  if(!rst) 
  begin
    reg_mem[0]    <= #1 'h00;
    reg_mem[1]    <= #1 'h00;
    reg_mem[2]    <= #1 'h00;
    reg_mem[3]    <= #1 'h00;
    reg_mem[4]    <= #1 'h04;
    reg_mem[5]    <= #1 'h00;
    reg_mem[6]    <= #1 'h00;
    reg_mem[7]    <= #1 'h00;
    reg_mem[8]    <= #1 'h00;
    reg_mem[9]    <= #1 'h00;
    reg_mem[8'h1D]<= #1 'h0000FFFF;
    reg_mem[8'h1E]<= #1 'h00;
    reg_mem[8'h1F]<= #1 'hA0;
    prog_count    <= #1 8'h00;
    prog_count_de <= #1 8'h00;
    prog_count_ex <= #1 8'h00;
    immi_val      <= #1 32'h00;
    opcode_ext_ex <= #1 10'h00;
    opcode_ext_mem<= #1 10'h00;
    regA          <= #1 32'h00;
    regB          <= #1 32'h00;
    regC          <= #1 32'h00;
    rega_addr     <= #1 'h00; 
    regb_addr     <= #1 'h00; 
    regc_addr     <= #1 'h00; 
    rega_addr_mem <= #1 'h00; 
    regb_addr_mem <= #1 'h00; 
    regc_addr_mem <= #1 'h00; 
    rega_addr_wb  <= #1 'h00; 
    regb_addr_wb  <= #1 'h00; 
    regc_addr_wb  <= #1 'h00; 
    regA_mem      <= #1 32'h00;
    regB_mem      <= #1 32'h00;
    regC_mem      <= #1 32'h00;
    opcode_ex     <= #1 'h00;
    opcode_mem    <= #1 'h00;
    i_type        <= #1 'b0;
    j_type        <= #1 'b0;
    r_type        <= #1 'b0;
    i_type_mem    <= #1 'b0;
    j_type_mem    <= #1 'b0;
    r_type_mem    <= #1 'b0;
    i_type_wb     <= #1 'b0;
    j_type_wb     <= #1 'b0;
    r_type_wb     <= #1 'b0;
    alu_op        <= #1 32'h0000;
    alu_op_wb     <= #1 32'h0000;
    data_mem_rd_d <= #1 'h0;
    forwarding    <= #1 1'b0;
  end
  else
  begin
    if((rega_addr_c == regb_addr) & (rega_addr_c != 5'b0) & (opcode_ex != 5'h15)) begin
     regA          <= #1 alu_op_c;
     forwarding    <= #1 1'b1;
    end 
    else if( (rega_addr_c == regb_addr_mem) & (rega_addr_c != 5'b0)) begin
     regA          <= #1 alu_op;
     forwarding    <= #1 1'b1;
    end
    else begin
     regA          <= #1 reg_mem[rega_addr_c];
     forwarding    <= #1 1'b0;
    end
     regB           <= #1 reg_mem[regb_addr_c];
     regC           <= #1 reg_mem[regc_addr_c];
     regA_mem       <= #1 regA;
     regB_mem       <= #1 regB;
     regC_mem       <= #1 regC;
     rega_addr      <= #1 rega_addr_c;
     regb_addr      <= #1 regb_addr_c;
     regc_addr      <= #1 regc_addr_c;
     rega_addr_mem  <= #1 rega_addr;
     regb_addr_mem  <= #1 regb_addr;
     regc_addr_mem  <= #1 regc_addr;
     rega_addr_wb   <= #1 rega_addr_mem;
     regb_addr_wb   <= #1 regb_addr_mem;
     regc_addr_wb   <= #1 regc_addr_mem;
     prog_count     <= #1 prog_count_c;
     prog_count_de  <= #1 prog_count;
     prog_count_ex  <= #1 prog_count_de;
     opcode_ext_ex  <= #1 opcode_ext_c;
     opcode_ext_mem <= #1 opcode_ext_ex;
     immi_val       <= #1 immi_val_c;
     opcode_ex      <= #1 opcode_c;
     opcode_mem     <= #1 opcode_ex;
     i_type         <= #1 i_type_c;
     j_type         <= #1 j_type_c;
     r_type         <= #1 r_type_c;
     i_type_mem     <= #1 i_type;
     j_type_mem     <= #1 j_type;
     r_type_mem     <= #1 r_type;
     i_type_wb      <= #1 i_type_wb_c;
     j_type_wb      <= #1 j_type_wb_c;
     r_type_wb      <= #1 r_type_mem;
     alu_op         <= #1 alu_op_c;
     alu_op_wb      <= #1 alu_op;
     data_mem_rd_d  <= #1 data_mem_rd_o;
     if (wb_exec) begin
//      $display("Write @ Reg[%d] = %d ",wb_reg_addr,wb_data);
      reg_mem[wb_reg_addr] <= #1 wb_data;
     end
  end
end

endmodule
