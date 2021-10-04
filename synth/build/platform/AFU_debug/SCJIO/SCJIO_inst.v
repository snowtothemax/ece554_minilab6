	SCJIO #(
		.ENABLE_JTAG_IO_SELECTION (INTEGER_VALUE_FOR_ENABLE_JTAG_IO_SELECTION),
		.NEGEDGE_TDO_LATCH        (INTEGER_VALUE_FOR_NEGEDGE_TDO_LATCH)
	) u0 (
		.tms (_connected_to_tms_), //   input,  width = 1, jtag.tms
		.tdi (_connected_to_tdi_), //   input,  width = 1,     .tdi
		.tdo (_connected_to_tdo_), //  output,  width = 1,     .tdo
		.tck (_connected_to_tck_)  //   input,  width = 1,  tck.clk
	);

