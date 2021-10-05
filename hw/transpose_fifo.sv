// fifo.sv
// Implements delay buffer (fifo)
// On reset all entries are set to 0
// Shift causes fifo to shift out oldest entry to q, shift in d

module transpose_fifo
  #(
  parameter DEPTH=8,
  parameter BITS=64
  )
  (
  input clk,rst_n,en, WrEn,
  input signed [BITS-1:0] rowIn [0:DEPTH-1],
  input signed [BITS-1:0] d,
  output signed [BITS-1:0] q
  );
  
  logic signed [BITS-1:0] fifo_data [0:DEPTH-1];
  genvar i;
  
  assign q = fifo_data[DEPTH-1];
  
  // FLOP BUFFER
  // Form flop buffer //
  /*
  generate
  	for (i = 0; i < DEPTH; i=i+1) begin
		always_ff @(posedge clk, negedge rst_n) begin
	
			// reset	
			if (!rst_n) begin
				fifo_data[i] <= 0;
			end

			// shift
			else if (en) begin	
				if (i === 0) begin
			        	fifo_data[i] <= d;
				end
				else begin
			        	fifo_data[i] <= fifo_data[i-1];
				end
			end
			
			// parallel load
			else if (WrEn && ~en) begin
				// input the row on the clock
				fifo_data <= rowIn;
			end
		   end
		end
	endgenerate
*/

	generate
		always_ff @(posedge clk, negedge rst_n) begin
	

			// reset	
			if (!rst_n) begin
				for (int i = 0; i < DEPTH; i++) begin
					fifo_data[i] <= 0;
				end
			end
			// parallel load
			else if (WrEn) begin
				// input the row on the clock
				fifo_data <= rowIn;
			end
			// shift
			else if (en) begin	
				for (int i = 0; i < DEPTH; i++) begin
					if (i === 0) begin
						fifo_data[i] <= d;
					end
					else begin
						fifo_data[i] <= fifo_data[i-1];
					end
				end
			end
		end
	endgenerate



endmodule // fifo
