module tpuv1
  #(
    parameter BITS_AB=8,
    parameter BITS_C=16,
    parameter DIM=8,
    parameter ADDRW=16,
    parameter DATAW=64
    )
   (
    input clk, rst_n, r_w, // r_w=0 read, =1 write
    input [DATAW-1:0] dataIn,
    output [DATAW-1:0] dataOut,
    input [ADDRW-1:0] addr
   );
   

	// Interconnects
	wire signed [BITS_AB-1:0] memAInput[DIM-1:0];
	wire signed [BITS_AB-1:0] memBInput[DIM-1:0];
	
	wire signed [BITS_AB-1:0] memAOut[DIM-1:0];
	wire signed [BITS_AB-1:0] memBOut[DIM-1:0];
	
	// Store for high low C outs read/writes
	wire signed [BITS_C-1:0] macCIn[DIM-1:0];
	wire signed [BITS_C-1:0] macCOut[DIM-1:0];
	
	logic [DATAW-1:0] readC;
	assign dataOut = readC;
	
	// Regs for counter
	reg [($clog2(4*DIM))-1:0] counter;
	
	// Control sigs
	logic write_a, write_b, write_c, en, start;
	
	// Row Sel
	wire [($clog2(DIM))-1:0] aRowSel;
	wire [($clog2(DIM))-1:0] cRowSel;
	assign aRowSel = addr[5:3];
	assign cRowSel = addr[6:4];
	
	//----------------------------------------------------------------------------------------
	
	// Connecting Interconnets to inputs
	// A,B
	genvar i;
	generate
		for (i = 1; i < DIM+1; i++) begin
			assign memAInput[i-1] = dataIn[(i*BITS_AB)-1:((i-1)*BITS_AB)];
			assign memBInput[i-1] = (en) ? (0) : (dataIn[(i*BITS_AB)-1:((i-1)*BITS_AB)]); // fill zeros
		end
	endgenerate
	
	// C
	generate
		for (i = 1; i < DIM+1; i++) begin
			if (i < (DIM/2)+1) begin // low case
				assign macCIn[i-1] = (addr[3:0] == 'h0) ? (dataIn[(i*BITS_C)-1:(i-1)*BITS_C]) : (macCOut[i-1]);
			end
			else begin // high case
				assign macCIn[i-1]  = (addr[3:0] == 'h8) ? (dataIn[((i-DIM/2)*BITS_C)-1:((i-DIM/2)-1)*BITS_C]) : (macCOut[i-1]);
			end
		end
	endgenerate
	
	
	// Modules
	memA #(.BITS_AB(BITS_AB), .DIM(DIM)) iMEMA(
		.clk(clk),
		.rst_n(rst_n),
		.en(en),
		.WrEn(write_a),
		.Ain(memAInput),
		.Arow(aRowSel),
		.Aout(memAOut)
		);
		
	memB #(.BITS_AB(BITS_AB), .DIM(DIM)) iMEMB(
		.clk(clk),
		.rst_n(rst_n),
		.en(en | write_b),
		.Bin(memBInput),
		.Bout(memBOut)
		);
	
	systolic_array #(.BITS_AB(BITS_AB), .BITS_C(BITS_C), .DIM(DIM)) iSYSARRY(
		.clk(clk),
		.rst_n(rst_n),
		.WrEn(write_c),
		.en(en),
		.A(memAOut),
		.B(memBOut),
		.Cin(macCIn),
		.Crow(cRowSel),
		.Cout(macCOut)
		);
	
	
	// Control gen
	always_comb begin
		// Defaults
		write_a = 0;
		write_b = 0;
		write_c = 0;
		start = 0;
		readC = 0;
		
		// Cases from addrs lines
		casex(addr)
			// Write A
			'h1xx:
				if (r_w) begin
					write_a = 1;
				end
			
			// Write BITS_AB
			'h2xx:
				if (r_w) begin
					write_b = 1;
				end
				
			// Read C High word
			'h3x8:
				if(r_w) begin
					write_c = 1;
				end
				else begin
					for(integer x = DIM/2; x < DIM; x++) begin
						readC |= (macCOut[x] << ((x-DIM/2)*BITS_C));
					end
				end
			
			// Read C Low word
			'h3x0:
				if(r_w) begin
					write_c = 1;
				end
				else begin
					for(integer x = 0; x < DIM/2; x++) begin
						readC |= (macCOut[x] << (x*BITS_C));
					end
				end
			
			// Start
			'h400:
			if (r_w) begin
				start = 1; // Starts counter
			end
		endcase
	
	end
	
	
	// Counter/en sig
	assign en = |counter;
	always_ff @(posedge clk) begin
		if (~rst_n) begin
			counter <= 0;
		end	
		else if (start || en) begin
			counter <= counter+1;
		end
	end
   
endmodule