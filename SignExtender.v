// Extends the immediate field of an ARMv8 (LEGv8) instruction to 64 bits.
//
//  SignOp  Type     Field used          Extension  Shift left 2?
//  00      I-Type   Instruction[21:10]  zero       no
//  01      D-Type   Instruction[20:12]  sign       no
//  10      CB-Type  Instruction[23:5]   sign       yes
//  11      B-Type   Instruction[25:0]   sign       yes

`define Itype  2'b00
`define Dtype  2'b01
`define CBtype 2'b10
`define Btype  2'b11

module SignExtender(
    output reg [63:0] SignExOut,
    input      [25:0] Instruction,
    input      [1:0]  SignOp
);

    always @(*) begin
        case (SignOp)
            // 12-bit unsigned immediate: 52 zeros + 12 bits = 64
            `Itype:  SignExOut = {52'b0, Instruction[21:10]};

            // 9-bit signed offset: 55 copies of the sign bit (bit 20) + 9 bits = 64
            `Dtype:  SignExOut = {{55{Instruction[20]}}, Instruction[20:12]};

            // 19-bit signed word offset: 43 copies of bit 23 + 19 bits + 2 zeros = 64
            `CBtype: SignExOut = {{43{Instruction[23]}}, Instruction[23:5], 2'b00};

            // 26-bit signed word offset: 36 copies of bit 25 + 26 bits + 2 zeros = 64
            `Btype:  SignExOut = {{36{Instruction[25]}}, Instruction[25:0], 2'b00};

            default: SignExOut = 64'b0;   // unreachable for a 2-bit SignOp, keeps the case fully specified
        endcase
    end

endmodule
