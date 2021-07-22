`timescale 1ns / 1ps

module Read_ADC_Top
  (input  i_Clk,       // Wire from the Main Clock, 100 MHz
   output io_PMOD_1,     // Wiring to the ADC board ~ chip select (active low)
   input  io_PMOD_3,     // data from ADC
   output io_PMOD_4,   // clock to read out data
   output reg io_PMOD_10,
   output reg o_ADC_Data_Valid, 
   output reg o_ADC_Data_Last,
   input i_ADC_Data_Ready_Config,
   input i_ADC_Data_Ready_Axis,
   output reg [15:0] o_ADC_Data_Axis
   //output reg [15:0] o_ADC_Data_Config = {5'b00000, 10'b0101010101, 1'b1}
   );
 
  wire [11:0] w_ADC_Data;
  wire w_ADC_Data_Valid;
  wire w_ADC_Data_Last;
  wire w_Start_ADC_Conversion;
  reg [31:0] r_Readout_Count  = 0;
  parameter Readout_Period = 1;  // 20 MS/s (100 MHz clock / 2 )
  //reg [11:0] r_ADC_Data;   // Only low order 12 bits are used.   Four high order bits always zero
  reg r_ADC_Data_Requested = 1'b0;
 
  // Code to read the ADC
  always @(posedge i_Clk) begin
    o_ADC_Data_Valid <= w_ADC_Data_Valid;
    //o_ADC_Data_Config = {5'b00000, 10'b0101010101, 1'b1};
    if (r_Readout_Count >= Readout_Period) begin
      r_Readout_Count <= 0;
      r_ADC_Data_Requested <= 1'b1;    //  Tell Read_ADC we want data
      io_PMOD_10 <= 1'b0;
    end else begin
      r_Readout_Count <= r_Readout_Count + 1;
      r_ADC_Data_Requested <= 1'b0;
      io_PMOD_10 <= 1'b1;
    end
    if (w_ADC_Data_Valid == 1'b1 && i_ADC_Data_Ready_Axis && i_ADC_Data_Ready_Config) begin
    //if (1'b1 == 1'b1) begin
      o_ADC_Data_Axis <= {4'b0000, w_ADC_Data[11:0]};    // Get the data from Read_ADC
      o_ADC_Data_Last <= w_ADC_Data_Last;
    end  
  end
  
  // Interface (instantiation) to the code that triggers the ADC and reads its data.
  // parameter ADC_CLKS_PER_BIT determines the readout speed of the bits from the ADC.
  // Its the clock frequency divided by the parameter.
  Read_ADC #(.ADC_CLKS_PER_BIT(4)) Read_ADC_Inst   // 4 is gets me 6.25 Mbaud, 160 ns clock
  (.i_Clock(i_Clk),
   .i_ADC_Data_Serial(io_PMOD_3),
   .i_ADC_Data_Requested(r_ADC_Data_Requested),
   .o_ADC_Data_Valid(w_ADC_Data_Valid),
   .o_ADC_Data(w_ADC_Data),
   .o_ADC_Chip_Select_Not(io_PMOD_1),
   .o_ADC_Data_Last(w_ADC_Data_Last),
   .o_ADC_Clock(io_PMOD_4));
   
endmodule // Read_ADC_Top
