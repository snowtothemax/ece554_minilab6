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
	localparam COUNTER_BITS = $clog2(DIM*3);
	
	///////////////////////////////
	/// intermediate signals
	//////////////////////////////
	logic WrEn_SA, WrEn_A;
	logic [ROWBITS-1:0] Arow;
	logic [ROWBITS-1:0] Crow;
	logic signed [BITS_AB-1:0] A [DIM-1:0];
	logic signed [BITS_AB-1:0] B [DIM-1:0];
	logic signed [BITS_C-1:0] Cin [DIM-1:0];
	logic signed [BITS_C-1:0] Cout [DIM-1:0];

	logic signed [BITS_AB-1:0] Amem_int [DIM-1:0];
	logic signed [BITS_AB-1:0] Bmem_int [DIM-1:0];

	logic signed [BITS_AB-1:0] nextA [DIM-1:0];
	logic signed [BITS_AB-1:0] nextB [DIM-1:0];
	
	logic signed [COUNTER_BITS-1:0] countSA_cycles;
	
	logic signed [BITS_C-1:0] out_reg [DIM-1:0];
	
	genvar rowcolA, rowcolB, rowcolC, ballsOut, rowcolC2;
	
	// control signals
	logic startCount_SA;
	logic countSA_done;
	logic en_SA, en_memA, en_memB;
	logic loadB;
	
	////////////////////////////////
	///// DUTS
	////////////////////////////////
	
	systolic_array #(
					.BITS_AB(BITS_AB),
                    .BITS_C(BITS_C),
                    .DIM(DIM))
                    systolic_array_DUT (.clk(clk),
                                        .rst_n(rst_n),
                                        .en(en_SA),
                                        .WrEn(WrEn_SA),
                                        .A(Amem_int),
                                        .B(Bmem_int),
                                        .Cin(Cin),
                                        .Crow(Crow),
                                        .Cout(Cout)
                                        );
	
	memA #(.BITS_AB(BITS_AB),
          .DIM(DIM))
          memA_DUT (.clk(clk),
                    .rst_n(rst_n),
                    .en(en_memA),
                    .WrEn(WrEn_A),
                    .Ain(A),
                    .Arow(Arow),
                    .Aout(Amem_int)
                    );
	
	memB #(.BITS_AB(BITS_AB),
          .DIM(DIM))
          memB_DUT (.clk(clk),
                    .rst_n(rst_n),
                    .en(en_memB),
                    .Bin(B),
                    .Bout(Bmem_int)
                    );
	
	/////////////////////////
	/// counter ff
	/////////////////////////
	
	// SA
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			countSA_cycles <= (DIM*3);
			countSA_done <= 0;
			en_memA = 0;
			//en_memB = 0;
			en_SA = 0;
		end
		else if (startCount_SA && countSA_done) begin
			countSA_cycles <= countSA_cycles - 1;
			countSA_done <= 0;
			en_memA = 1;
			//en_memB = 1;
			en_SA = 1;
		end
		else if (countSA_cycles === 16'h0) begin
			countSA_cycles <= 16'h0;
			countSA_done <= 1;
			en_memA = 0;
			//en_memB = 0;
			en_SA = 0;
		end
    else begin
		countSA_cycles <= countSA_cycles - 1;
		countSA_done <= 0;
		en_memA = 1;
		//en_memB = 1;
		en_SA = 1;
		end
	end
	
	/////////////////
	// generates
	////////////////
	
	// assign for A
	generate
		for(rowcolA=0;rowcolA<DIM;++rowcolA) begin
			assign A[rowcolA] = WrEn_A ? dataIn[(((rowcolA+1)*BITS_AB)-1):(rowcolA*BITS_AB)] : '0;
		end
	endgenerate
	
	// assign for B
	generate
		for(rowcolB=0;rowcolB<DIM;++rowcolB) begin
			assign B[rowcolB] = loadB ? dataIn[((rowcolB+1)*BITS_AB)-1:(rowcolB*BITS_AB)] : '0;
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
		  A[rowcol] = {BITS_AB{1'b0}};
		  B[rowcol] = {BITS_AB{1'b0}};
		  out_reg[rowcol] = {BITS_C{1'b0}};
		end
		
		en_memB = 0;
		//en_memA = 0;
		//en_SA = 0;
		WrEn_A = 0;
		WrEn_SA = 0;
		startCount_SA = 0;
		loadB = 0;
		case (addr[11:8])
			// write to A
			4'h1: begin
				WrEn_A = 1;
				Arow = addr[ROWBITS+2:ROWBITS];
			end
			// write to B
			4'h2: begin
				en_memB = 1;
				loadB = 1;
      end
			// read / write to C
			4'h3: begin
				Crow = addr[ROWBITS+3:ROWBITS+1];
				
				if (!r_w) begin
					out_reg = Cout;
				end
				else begin
					WrEn_SA = 1;
				end
			end
			4'h4: begin
			    startCount_SA = 1;
			end
			default: begin
				// balls
        if (~countSA_done) begin
          en_memB = 1;
        end
			end
		endcase
	end
   
   
   
endmodule
