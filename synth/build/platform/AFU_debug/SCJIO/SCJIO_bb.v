module SCJIO #(
		parameter ENABLE_JTAG_IO_SELECTION = 0,
		parameter NEGEDGE_TDO_LATCH        = 1
	) (
		input  wire  tms, // jtag.tms
		input  wire  tdi, //     .tdi
		output wire  tdo, //     .tdo
		input  wire  tck  //  tck.clk
	);
endmodule

