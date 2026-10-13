// 10 random (CurrentPC, SignExtImm64) pairs for each of the 8 combinations of
// {Branch, Uncondbranch, ALUZero}. Every result is compared with a reference model,
// and each mismatch prints an ERROR line. A VCD file is written for waveform viewing.

`timescale 1ns/1ps

module NextPClogic_tb;

    reg  [63:0] CurrentPC;
    reg  [63:0] SignExtImm64;
    reg         Branch, Uncondbranch, ALUZero;
    wire [63:0] NextPC;

    integer errors, tests;
    integer combo, j;

    NextPClogic dut (
        .NextPC      (NextPC),
        .CurrentPC   (CurrentPC),
        .SignExtImm64(SignExtImm64),
        .Branch      (Branch),
        .ALUZero     (ALUZero),
        .Uncondbranch(Uncondbranch)
    );

    // Reference model. The mux select comes straight from the truth table
    // (indexed by {Branch, Uncondbranch, ALUZero}) instead of the DUT's boolean equation.
    function [63:0] expected;
        input        br, un, zr;
        input [63:0] pc, imm;
        reg          sel;
        begin
            case ({br, un, zr})
                3'b000:  sel = 1'b0;
                3'b001:  sel = 1'b0;
                3'b010:  sel = 1'b1;
                3'b011:  sel = 1'b1;
                3'b100:  sel = 1'b0;
                3'b101:  sel = 1'b1;
                3'b110:  sel = 1'b1;
                3'b111:  sel = 1'b1;
                default: sel = 1'b0;
            endcase
            expected = sel ? (pc + imm) : (pc + 64'd4);
        end
    endfunction

    // Apply one vector, wait for the combinational logic, then compare.
    task check;
        input        br, un, zr;
        input [63:0] pc, imm;
        reg   [63:0] exp_pc;
        begin
            Branch       = br;
            Uncondbranch = un;
            ALUZero      = zr;
            CurrentPC    = pc;
            SignExtImm64 = imm;
            #10;
            exp_pc = expected(br, un, zr, pc, imm);
            tests = tests + 1;
            if (NextPC !== exp_pc) begin
                errors = errors + 1;
                $display("ERROR: Branch=%b Uncond=%b ALUZero=%b PC=%h Imm=%h | NextPC=%h expected %h",
                         br, un, zr, pc, imm, NextPC, exp_pc);
            end
        end
    endtask

    initial begin
        $dumpfile("NextPClogic_tb.vcd");
        $dumpvars(0, NextPClogic_tb);

        errors = 0;
        tests  = 0;

        // combo counts 000..111 = {Branch, Uncondbranch, ALUZero}, same order as the truth table
        for (combo = 0; combo < 8; combo = combo + 1)
            for (j = 0; j < 10; j = j + 1)
                check(combo[2], combo[1], combo[0], {$random, $random}, {$random, $random});

        if (errors == 0)
            $display("PASS: NextPClogic, %0d tests, 0 errors", tests);
        else
            $display("FAIL: NextPClogic, %0d errors in %0d tests", errors, tests);

        #10 $finish;
    end

endmodule
