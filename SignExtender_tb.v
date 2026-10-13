// For each of the 4 SignOp values: two corner cases (all 0s, all 1s) plus 100 random
// Instruction[25:0] values. Every result is compared with a reference model, and each
// mismatch prints an ERROR line. A VCD file is written for waveform viewing.

`timescale 1ns/1ps

module SignExtender_tb;

    reg  [25:0] Instruction;
    reg  [1:0]  SignOp;
    wire [63:0] SignExOut;

    integer errors;
    integer tests;
    integer op;
    integer i;

    SignExtender dut (
        .SignExOut  (SignExOut),
        .Instruction(Instruction),
        .SignOp     (SignOp)
    );

    // Reference model. Deliberately written differently from the DUT (signed arithmetic
    // instead of bit concatenation) so one mistake is unlikely to be repeated in both.
    function [63:0] expected;
        input [25:0] instr;
        input [1:0]  sop;
        reg signed [63:0] imm;
        begin
            case (sop)
                2'b00:   imm = instr[21:10];              // I : unsigned field, zero-extended
                2'b01:   imm = $signed(instr[20:12]);     // D : 9-bit signed value
                2'b10:   imm = $signed(instr[23:5]) * 4;  // CB: 19-bit signed value, times 4 (= <<2)
                2'b11:   imm = $signed(instr[25:0]) * 4;  // B : 26-bit signed value, times 4 (= <<2)
                default: imm = 64'd0;
            endcase
            expected = imm;
        end
    endfunction

    // Apply one vector, wait for the combinational logic to settle, then compare.
    task check;
        input [1:0]  sop;
        input [25:0] instr;
        reg   [63:0] exp_out;
        begin
            SignOp      = sop;
            Instruction = instr;
            #10;
            exp_out = expected(instr, sop);
            tests = tests + 1;
            if (SignExOut !== exp_out) begin
                errors = errors + 1;
                $display("ERROR: SignOp=%b Instruction=%h  got %h  expected %h",
                         sop, instr, SignExOut, exp_out);
            end
        end
    endtask

    initial begin
        $dumpfile("SignExtender_tb.vcd");
        $dumpvars(0, SignExtender_tb);

        errors = 0;
        tests  = 0;

        for (op = 0; op < 4; op = op + 1) begin
            check(op[1:0], 26'd0);                // corner: all zeros
            check(op[1:0], {26{1'b1}});           // corner: all ones
            for (i = 0; i < 100; i = i + 1)
                check(op[1:0], $random);          // 100 random instructions (low 26 bits used)
        end

        if (errors == 0)
            $display("PASS: SignExtender, %0d tests, 0 errors", tests);
        else
            $display("FAIL: SignExtender, %0d errors in %0d tests", errors, tests);

        #10 $finish;
    end

endmodule
