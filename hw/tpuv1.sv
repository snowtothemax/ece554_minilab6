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
   
	localparam ROWBITS = $clog2(DIM);
	localparam COUNTER_BITS = $clog2(DIM*4);
	
	///////////////////////////////
	/// intermediate signals
	//////////////////////////////
	logic WrEn_SA, WrEn_A;
	logic signed [BITS_AB-1:0] A [DIM-1:0];
	logic signed [BITS_AB-1:0] B [DIM-1:0];
	logic signed [BITS_C-1:0] Cin [DIM-1:0];
	logic signed [BITS_C-1:0] Cout [DIM-1:0];
	logic signed [BITS_AB-1:0] Amem_int [DIM-1:0];
	logic signed [BITS_AB-1:0] Bmem_int [DIM-1:0];
	logic signed [BITS_C-1:0] out_reg [DIM-1:0];
	
	genvar rowcolA, rowcolB, rowcolC, ballsOut, rowcolC2;
	
	// control signals
	logic startCount;
	logic loadB;
	logic en;
	logic unsigned [COUNTER_BITS-1:0] counter;
	
	////////////////////////////////
	///// DUTS
	////////////////////////////////
	
	systolic_array #(
			.BITS_AB(BITS_AB),
                    	.BITS_C(BITS_C),
                    	.DIM(DIM))
                    	systolic_array_DUT (.clk(clk),
                        		.rst_n(rst_n),
                                        .en(en),
                                        .WrEn(WrEn_SA),
                                        .A(Amem_int),
                                        .B(Bmem_int),
                                        .Cin(Cin),
                                        .Crow(addr[6:4]),
                                        .Cout(Cout)
                                        );
	
	memA #(
		.BITS_AB(BITS_AB),
          	.DIM(DIM))
         	 memA_DUT (.clk(clk),
                    .rst_n(rst_n),
                    .en(en),
                    .WrEn(WrEn_A),
                    .Ain(A),
                    .Arow(addr[5:3]),
                    .Aout(Amem_int)
                    );
	
	memB #(
		.BITS_AB(BITS_AB),
          	.DIM(DIM))
          	memB_DUT (.clk(clk),
                    .rst_n(rst_n),
                    .en(en | loadB),
                    .Bin(B),
                    .Bout(Bmem_int)
                    );
	
	/////////////////////////
	// enable
	/////////////////////////
	assign en = |counter;

	/////////////////////////
	// counter 
	/////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			counter <= 0;
		else if (startCount | en)
			counter <= counter + 1;
	end

	/////////////////
	// generates
	////////////////
	
	// assign for A
	//Nate has no conidtional here
	generate
		for(rowcolA=0;rowcolA<DIM;++rowcolA) begin
			assign A[rowcolA] = /*WrEn_A ?*/ dataIn[(((rowcolA+1)*BITS_AB)-1):(rowcolA*BITS_AB)]; //: '0;
		end
	endgenerate
	
	// assign for B
	//Nate has a conditional based off of en not off of loadB
	//If en then load zeros otherwise do the math stuff (our math is right) 
	generate
		for(rowcolB=0;rowcolB<DIM;++rowcolB) begin
			assign B[rowcolB] = en ? dataIn[((rowcolB+1)*BITS_AB)-1:(rowcolB*BITS_AB)] : '0;
		end
	endgenerate
	
	// Assign for Cin ( first half )
	generate
		for(rowcolC=0;rowcolC<DIM/2;++rowcolC) begin
			assign Cin[rowcolC] = addr[3] ? Cout[rowcolC] : dataIn[((rowcolC+1)*BITS_C)-1:(rowcolC)*(BITS_C)];
		end
	endgenerate
	
	// assign for Cin (second half)
	generate
		for(rowcolC2 = DIM/2; rowcolC2< DIM; ++rowcolC2) begin
			assign Cin[rowcolC2] = addr[3] ? dataIn[((rowcolC2+1-(DIM/2))*BITS_C)-1:(rowcolC2-DIM/2)*(BITS_C)] : Cout[rowcolC2];
		end
	endgenerate
	
	// assign dataOut
	generate
		for(ballsOut=0; ballsOut < DIM/2; ballsOut++) begin
			assign dataOut[((BITS_C)*ballsOut) + (BITS_C - 1):(BITS_C*ballsOut)] = addr[3] ? out_reg[ballsOut + DIM/2] : out_reg[ballsOut];
		end
	endgenerate
	
	///////////////////////
	// case statement
	///////////////////////
	always_comb begin
		// set the input values to be 0
		for(int rowcol=0;rowcol<DIM;++rowcol) begin
		  out_reg[rowcol] = {BITS_C{1'b0}};
		end
		
		WrEn_A = 0;
		WrEn_SA = 0;
		loadB = 0;
		startCount = 0;

		case (addr[11:8])
			// write to A
			4'h1: begin
				WrEn_A = 1;
			end
			// write to B
			4'h2: begin
				loadB = 1;
      			end
			// read / write to C
			4'h3: begin
				if (!r_w) begin
					out_reg = Cout;
				end
				else begin
					WrEn_SA = 1;
				end
			end
			// matmul
			4'h4: begin
			    startCount = 1;
			end
		endcase
	end
endmodule
