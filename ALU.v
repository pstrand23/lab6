// 64-bit ALU: AND, OR, ADD, SUB, PassB. Zero is 1 whenever BusW is all 0s.

`define AND   4'b0000
`define OR    4'b0001
`define ADD   4'b0010
`define SUB   4'b0110
`define PassB 4'b0111

module ALU(
    output reg [63:0] BusW,
    input      [63:0] BusA,
    input      [63:0] BusB,
    input      [3:0]  ALUCtrl,
    output            Zero
);

    always @(*) begin
        case (ALUCtrl)
            `AND:    BusW = BusA & BusB;
            `OR:     BusW = BusA | BusB;
            `ADD:    BusW = BusA + BusB;      // wraps modulo 2^64 on overflow
            `SUB:    BusW = BusA - BusB;
            `PassB:  BusW = BusB;             // used by CBZ
            default: BusW = 64'b0;            // unused ALUCtrl codes: drive 0 so no latch is inferred
        endcase
    end

    // Zero depends only on the final BusW value, so it is correct for every operation
    assign Zero = (BusW == 64'b0);

endmodule
