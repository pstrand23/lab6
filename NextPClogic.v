// Mirrors the block diagram: two adders feeding a 2-to-1 mux.
//   CurPCInc = CurrentPC + 4
//   BranchPC = CurrentPC + SignExtImm64   (the sign extender has already done the <<2)
//   mux select = (Branch & ALUZero) | Uncondbranch

module NextPClogic(
    output reg [63:0] NextPC,
    input      [63:0] CurrentPC,
    input      [63:0] SignExtImm64,
    input             Branch,
    input             ALUZero,
    input             Uncondbranch
);

    wire [63:0] CurPCInc;
    wire [63:0] BranchPC;
    wire        take_branch;     // mux select: 1 -> BranchPC, 0 -> CurPCInc

    assign CurPCInc    = CurrentPC + 64'd4;
    assign BranchPC    = CurrentPC + SignExtImm64;
    assign take_branch = (Branch & ALUZero) | Uncondbranch;

    always @(*) begin
        if (take_branch)
            NextPC = BranchPC;
        else
            NextPC = CurPCInc;
    end

endmodule
