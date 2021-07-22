`timescale 1ns / 1ps

module Read_ADC
  #(parameter ADC_CLKS_PER_BIT = 25)
  (
   input        i_Clock,
   input        i_ADC_Data_Serial,
   input        i_ADC_Data_Requested,// Set this to True when you want an ADC readout
   output       o_ADC_Data_Valid,    // When this is true, it means the adc data is ready
   output [11:0] o_ADC_Data,         //Its a 12 bit ADC
   output       o_ADC_Chip_Select_Not, // The ~CS line is active when False
   output       o_ADC_Data_Last,     // Last sample of the frame
   output       o_ADC_Clock          // Falling edge requests next bit, bit is read on rising edge
   );
   
  parameter IDLE                 = 2'b00;   // State Machine states
  parameter ADC_CONVERSION_DELAY = 2'b01;   // Not needed? Datasheet says 10 ns minimum is needed.
  parameter READ_DATA_BITS       = 2'b10;
  parameter CLEANUP              = 2'b11;
 
  reg [7:0]     r_Clock_Count    = 0;
  reg [3:0]     r_Bit_Index      = 15; //4 zero bits + 12 data bits = 16 bits total
  reg [15:0]    r_ADC_Data       = 0;  // First 4 bits always zero
  reg           r_ADC_Data_Valid = 0;
  reg [2:0]     r_SM_Main        = 0;
  reg           r_ADC_Chip_Select_Not = 1;
  reg           r_ADC_Clock      = 1;
  reg [7:0]    r_Delay_Clock_Count = 0;
  reg           r_Got_The_Bit    = 1'b0;
  reg           r_ADC_Data_Last = 0;
 
  // Read ADC state machine
  always @(posedge i_Clock)
  begin
    case (r_SM_Main)
      IDLE : begin
          r_ADC_Data_Valid    <= 1'b0;
          r_Clock_Count       <= 0;
          r_Delay_Clock_Count <= 0;
          r_Bit_Index         <= 14;  // ADC send 15 bits (not 16)   High order bits first
          r_ADC_Clock         <= 1'b1;
          if (i_ADC_Data_Requested == 1'b1) begin
            r_SM_Main <= ADC_CONVERSION_DELAY;
            r_ADC_Chip_Select_Not <= 1'b0;        // Start the conversion
          end else begin
            r_SM_Main <= IDLE;
            r_ADC_Chip_Select_Not <= 1'b1;        // Don't start the conversion
          end
      end // case: IDLE
      ADC_CONVERSION_DELAY : begin
        if (r_Delay_Clock_Count < 0) begin   // Adjust to give time for ADC to start a conversion
          // 0 gives 80 ns (Three cycles of 25 MHz clock), 1 gives 120 ns, 2 gives 160 ns, etc
          r_Delay_Clock_Count <= r_Delay_Clock_Count + 1;
          r_SM_Main <= ADC_CONVERSION_DELAY;
        end else begin
          r_Delay_Clock_Count <= 0;
          r_SM_Main <= READ_DATA_BITS;
        end
      end // case: ADC_CONVERSION_DELAY
      READ_DATA_BITS : begin
        if (r_Clock_Count < ADC_CLKS_PER_BIT-1) begin
          if (r_Clock_Count < (ADC_CLKS_PER_BIT/2)) begin
            r_ADC_Clock <= 1'b0;     // Falling edge tells ADC to output a bit
            r_Got_The_Bit <= 1'b0;
          end else begin
            r_ADC_Clock <= 1'b1;     // Rising edge is when we get the bit.  (It is now stable)
            if (r_Got_The_Bit == 1'b0) begin
              r_ADC_Data[r_Bit_Index] <= i_ADC_Data_Serial;  // GET THE DATA BIT!!
              r_Got_The_Bit <= 1'b1;   //We want to latch the bit only once
              // Check if we have received all bits
              if (r_Bit_Index > 0) begin      // We need to get more bits (We get 16 bits, 1st four are zero)
                r_Bit_Index <= r_Bit_Index - 1;  //ADC send bit 15 first, then bit 14, ...
                r_SM_Main   <= READ_DATA_BITS;
              end else begin
                r_ADC_Data_Valid <= 1'b1;         // All 15 bits are now valid. Tell caller to get the data.
                r_ADC_Chip_Select_Not <= 1'b1;    // Stop the conversion
                r_ADC_Data_Last <= 1'b1;
                r_SM_Main     <= CLEANUP;
              end
            end
          end
          r_Clock_Count <= r_Clock_Count + 1;
        end else begin
          r_Clock_Count <= 0;
        end
      end // case: READ_DATA_BITS      
      CLEANUP : begin      // Stay here 1 clock
         // r_Delay_Clock_Count <= 0;
          r_SM_Main <= IDLE;
          r_ADC_Data_Valid   <= 1'b0;
      end // case: CLEANUP       
      default :
        r_SM_Main <= IDLE;
    endcase
  end    

  assign o_ADC_Data_Valid   = r_ADC_Data_Valid;
  assign o_ADC_Data = r_ADC_Data[11:0];
  assign o_ADC_Chip_Select_Not = r_ADC_Chip_Select_Not;
  assign o_ADC_Clock = r_ADC_Clock;
  assign o_ADC_Data_Last = r_ADC_Data_Last;
endmodule // Read_ADC

