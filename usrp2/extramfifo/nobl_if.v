// Tested against an IDT 71v65603s150 in simulation and a Cypress 7C1356C in the real world.

module nobl_if
  #(parameter WIDTH=18,DEPTH=19)  
    (
     input clk,
     input rst,
     input [WIDTH-1:0] RAM_D_pi,
     output [WIDTH-1:0] RAM_D_po,
     output reg RAM_D_poe,
     output [DEPTH-1:0] RAM_A,
     output reg RAM_WEn,
     output RAM_CENn,
     output RAM_LDn,
     output RAM_OEn,
     output reg RAM_CE1n,
     input [DEPTH-1:0] address,
     input [WIDTH-1:0] data_out,
     output reg [WIDTH-1:0] data_in,
     output reg data_in_valid,
     input write,
     input enable
     );
   

   reg 	   enable_pipe1;
   reg [DEPTH-1:0] address_pipe1;
   reg 		   write_pipe1;
   reg [WIDTH-1:0] data_out_pipe1;
   
   reg 		   enable_pipe2;
   reg 		   write_pipe2;
   reg [WIDTH-1:0] data_out_pipe2;

   reg 		   enable_pipe3;
   reg 		   write_pipe3;
   reg [WIDTH-1:0] data_out_pipe3;

   assign 	   RAM_LDn = 0;
   // ZBT/NoBL RAM actually manages its own output enables very well.
   assign 	   RAM_OEn = 0;
   
   //
   // Pipeline stage 1
   //
   always @(posedge clk)
     if (rst)
       begin
	  enable_pipe1 <= 0;
	  address_pipe1 <= 0;
	  write_pipe1 <= 0;
	  data_out_pipe1  <= 0;
	  RAM_WEn <= 1;
	  RAM_CE1n <= 1;
	  
       end
     else
       begin
	  enable_pipe1 <= enable;
	  RAM_CE1n <= ~enable;  // Creates IOB flop
	  RAM_WEn <= ~write;  // Creates IOB flop
	  
	  if (enable)
	    begin
	       address_pipe1 <= address;
	       write_pipe1 <= write;
//	       RAM_WEn <= ~write;  // Creates IOB flop
	       
	       
	       if (write)
		 data_out_pipe1 <= data_out;
	    end
       end // always @ (posedge clk)

   // Pipeline 1 drives address, write_enable, chip_select on NoBL SRAM
   assign RAM_A = address_pipe1;
   assign RAM_CENn = 1'b0;
 //  assign RAM_WEn = ~write_pipe1;
//   assign RAM_CE1n = ~enable_pipe1;

   //
   // Pipeline stage2
   //
   always @(posedge clk)
     if (rst)
       begin
	  enable_pipe2 <= 0;
	  data_out_pipe2 <= 0;
	  write_pipe2 <= 0;   
       end
     else
       begin
	  data_out_pipe2 <= data_out_pipe1;
	  write_pipe2 <= write_pipe1;
	  enable_pipe2 <= enable_pipe1;
       end
   
   //
   // Pipeline stage3
   //
   always @(posedge clk)
     if (rst)
       begin
	  enable_pipe3 <= 0;
	  data_out_pipe3 <= 0;
	  write_pipe3 <= 0;
	  RAM_D_poe <= 0;	  
       end
     else
       begin
	  data_out_pipe3 <= data_out_pipe2;
	  write_pipe3 <= write_pipe2;
	  enable_pipe3 <= enable_pipe2;
	  RAM_D_poe <= ~(write_pipe2 & enable_pipe2); // Active low driver enable in Xilinx.	
       end

   // Pipeline 3 drives write data on NoBL SRAM
   assign RAM_D_po = data_out_pipe3;
   
   
   //
   // Pipeline stage4
   //
   always @(posedge clk)
     if (rst)
       begin
	  data_in_valid <= 0;
	  data_in <= 0;
       end
     else
       begin
	  data_in <= RAM_D_pi;
	  if (enable_pipe3 & ~write_pipe3)
	    begin
	       // Read data now available to be registered.
	       data_in_valid <= 1'b1;
	    end
	  else
	    data_in_valid <= 1'b0;
       end // always @ (posedge clk)
     
endmodule // nobl_if
