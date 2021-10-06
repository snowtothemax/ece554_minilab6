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
   
	/* -------------------- Localparams ------------------ */
	localparam ROWBITS = $clog2(DIM);
	localparam COUNTER_BITS = $clog2(DIM*4);
	
	/* -------------------- Interconnects ---------------- */
	logic signed [BITS_AB-1:0] memA_in [DIM-1:0];
	logic signed [BITS_AB-1:0] memA_out [DIM-1:0];
	logic signed [BITS_AB-1:0] memB_in [DIM-1:0];
	logic signed [BITS_AB-1:0] memB_out [DIM-1:0];
	logic signed [BITS_C-1:0] macC_in [DIM-1:0];
	logic signed [BITS_C-1:0] macC_out [DIM-1:0];
	logic signed [BITS_C-1:0] outReg [DIM-1:0];
	//logic [DATAW-1:0] cWord;
	logic [ROWBITS-1:0] aRow, cRow;

	/* -------------------- Control Signals -------------- */
	logic WrEn_A, WrEn_B, WrEn_SA, en;
	logic ballsOut;
	/*
	######################################################################################
	#                                                                                    # 
	#                            ,.--------._                                            #
	#                           /            ''.                                         #
	#                         ,'                \     |"\                /\          /\  #
	#                /"|     /                   \    |__"              ( \\        // ) #
	#               "_"|    /           z#####z   \  //                  \ \\      // /  #
	#                 \\  #####        ##------".  \//                    \_\\||||//_/   #
	#                  \\/-----\     /          ".  \                      \/ _  _ \     #
	#                   \|      \   |   ,,--..       \                    \/|(O)(O)|     #
	#                   | ,.--._ \  (  | ##   \)      \                  \/ |      |     #
	#                   |(  ##  )/   \ `-....-//       |///////////////_\/  \      /     #
	#                     '--'."      \                \              //     |____|      #
	#                  /'    /         ) --.            \            ||     /      \     #
	#               ,..|     \.________/    `-..         \   \       \|     \ 0  0 /     #
	#            _,##/ |   ,/   /   \           \         \   \       U    / \_//_/      #
	#          :###.-  |  ,/   /     \        /' ""\      .\        (     /              #
	#         /####|   |   (.___________,---',/    |       |\=._____|  |_/               #
	#        /#####|   |     \__|__|__|__|_,/             |####\    |  ||                #
	#       /######\   \      \__________/                /#####|   \  ||                #
	#      /|#######`. `\                                /#######\   | ||                #
	#     /++\#########\  \                      _,'    _/#########\ | ||                #
	#    /++++|#########|  \      .---..       ,/      ,'##########.\|_||  Donkey By     #
	#   //++++|#########\.  \.              ,-/      ,'########,+++++\\_\\ Hard'96       #
	#  /++++++|##########\.   '._        _,/       ,'######,''++++++++\                  #
	# |+++++++|###########|       -----."        _'#######' +++++++++++\                 #
	# |+++++++|############\.     \\     //      /#######/++++ S@yaN +++\                #
	#      ________________________\\___//______________________________________         #
	#     / ____________________________________________________________________)        #
	#    / /              _                                             _                #
	#    | |             | |                                           | |               #
	#     \ \            | | _           ____           ____           | |  _            #
	#      \ \           | || \         / ___)         / _  )          | | / )           #
	#  _____) )          | | | |        | |           (  __ /          | |< (            #
	# (______/           |_| |_|        |_|            \_____)         |_| \_)           #
	#                                                                           19.08.02 #
	######################################################################################
	*/	
	/* -------------------- Counter Signals -------------- */
	reg [COUNTER_BITS-1:0] counter;
	logic startCount;

	/* -------------------- Gen Vars --------------------- */
	genvar i;
	
	/* -------------------- Modules ---------------------- */
	systolic_array #(.BITS_AB(BITS_AB), .BITS_C(BITS_C), .DIM(DIM)) systolic_array_DUT (
		.clk(clk),
    .rst_n(rst_n),
    .en(en),
    .WrEn(WrEn_SA),
    .A(memA_out),
    .B(memB_out),
    .Cin(macC_in),
    .Crow(cRow),
    .Cout(macC_out)
  );

	memA #(.BITS_AB(BITS_AB), .DIM(DIM)) memA_DUT (
		.clk(clk),
    .rst_n(rst_n),
		.en(en),
		.WrEn(WrEn_A),
		.Ain(memA_in),
		.Arow(aRow),
		.Aout(memA_out)
	);
	
	memB #(.BITS_AB(BITS_AB), .DIM(DIM)) memB_DUT (
		.clk(clk),
		.rst_n(rst_n),
		.en(en | WrEn_B),
		.Bin(memB_in),
		.Bout(memB_out)
	);
	
	/* -------------------- Assignments ------------------- */
	assign en = |counter;
	//assign dataOut = cWord;
	assign aRow = addr[5:3];
	assign cRow = addr[6:4];

	/* -------------------- Counter ----------------------- */
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			counter <= 0;
		else if (startCount || en)
			counter <= counter + 1;
	end

	/* --------------- Generates Interconnects ------------ */
	
	// assign for A
	generate
		for(i = 0; i < DIM; i++) begin
			assign memA_in[i] = WrEn_A ? dataIn[(((i + 1) * BITS_AB) - 1):(i * BITS_AB)] : '0;
		end
	endgenerate
	
	// assign for B
	generate
		for(i = 0; i < DIM; i++) begin
			assign memB_in[i] = WrEn_B ? dataIn[((i + 1) * BITS_AB) - 1:(i * BITS_AB)] : '0;
		end
	endgenerate
	
	// Assign for Cin (low word)
	generate
		for(i = 0; i < DIM/2; i++) begin
			assign macC_in[i] = addr[3] ? macC_out[i] : dataIn[(((i + 1) * BITS_C) - 1):(i * BITS_C)];
		end
	endgenerate
	
	// assign for Cin (high word)
	generate
		for(i = DIM/2; i < DIM; i++) begin
			assign macC_in[i] = addr[3] ? dataIn[((i + 1 - (DIM/2)) * BITS_C) - 1:(i - DIM/2) * (BITS_C)] : macC_out[i];
		end
	endgenerate
	
	// assign dataOut
	generate
		for(i = 0; i < DIM/2; i++) begin
			assign dataOut[((BITS_C) * i) + (BITS_C - 1):(BITS_C * i)] = addr[3] ? outReg[i + DIM/2] : outReg[i];
		end
	endgenerate
	
	/* -------------------- Combinational --------------------- */
	always_comb begin
		// 
		// Defaults
		//		
		WrEn_A = 0;
		WrEn_B = 0;
		WrEn_SA = 0;
		startCount = 0;
		//cWord = 0;
		for (int i = 0; i < DIM; i++) begin
			outReg[i] = 0;
		end

		case (addr[11:8])
			// write to A
			4'h1: begin
				if (r_w) begin
					WrEn_A = 1;
				end
			end
			// write to B
			4'h2: begin
				if (r_w) begin
					WrEn_B = 1;
				end
			end
			// read / write to C
			4'h3: begin
				if (r_w) begin
					WrEn_SA = 1;
				end
				else begin
					outReg = macC_out;
				end
			end
			// matmul
			4'h4: begin
			    startCount = 1;
			end
		endcase
	end
endmodule
