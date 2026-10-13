//   1) all-zeros / all-ones on BusA and BusB (all 4 combinations) for every function
//   2) directed tests giving Zero=1 and Zero=0 for every function
//   3) ADD overflow tests
//   4) 100 random (BusA, BusB) pairs for every function
// Every vector is checked against a reference model; each mismatch prints an ERROR line.
// A VCD file is written for waveform viewing.

`timescale 1ns/1ps

module ALU_tb;

    reg  [63:0] BusA;
    reg  [63:0] BusB;
    reg  [3:0]  ALUCtrl;
    wire [63:0] BusW;
    wire        Zero;

    // ALUCtrl codes from the prelab table (localparams, so they don't clash with the `defines in ALU.v)
    localparam [3:0] C_AND   = 4'b0000,
                     C_OR    = 4'b0001,
                     C_ADD   = 4'b0010,
                     C_SUB   = 4'b0110,
                     C_PASSB = 4'b0111;

    localparam [63:0] ZEROS = 64'h0000_0000_0000_0000,
                      ONES  = 64'hFFFF_FFFF_FFFF_FFFF;

    reg [3:0] ops [0:4];        // the five functions, so loops can walk through them
    integer   errors, tests;
    integer   k, m, n;

    ALU dut (
        .BusW   (BusW),
        .BusA   (BusA),
        .BusB   (BusB),
        .ALUCtrl(ALUCtrl),
        .Zero   (Zero)
    );

    // Reference model for BusW. SUB is written as A + ~B + 1 (two's complement)
    // rather than A - B, so it is not just a copy of the DUT's expression.
    function [63:0] alu_expected;
        input [3:0]  ctrl;
        input [63:0] a, b;
        begin
            case (ctrl)
                C_AND:   alu_expected = a & b;
                C_OR:    alu_expected = a | b;
                C_ADD:   alu_expected = a + b;
                C_SUB:   alu_expected = a + ~b + 64'd1;
                C_PASSB: alu_expected = b;
                default: alu_expected = 64'd0;
            endcase
        end
    endfunction

    // Apply one vector, wait for the combinational logic, compare BusW and Zero.
    task check;
        input [3:0]  ctrl;
        input [63:0] a, b;
        reg   [63:0] exp_w;
        reg          exp_z;
        begin
            ALUCtrl = ctrl;
            BusA    = a;
            BusB    = b;
            #10;
            exp_w = alu_expected(ctrl, a, b);
            exp_z = (exp_w == 64'd0);
            tests = tests + 1;
            if (BusW !== exp_w || Zero !== exp_z) begin
                errors = errors + 1;
                $display("ERROR: ALUCtrl=%b A=%h B=%h | BusW=%h (expected %h)  Zero=%b (expected %b)",
                         ctrl, a, b, BusW, exp_w, Zero, exp_z);
            end
        end
    endtask

    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(0, ALU_tb);

        errors = 0;
        tests  = 0;
        ops[0] = C_AND;  ops[1] = C_OR;  ops[2] = C_ADD;  ops[3] = C_SUB;  ops[4] = C_PASSB;

        // 1) every all-zeros / all-ones combination of BusA and BusB, for every function
        for (k = 0; k < 5; k = k + 1)
            for (m = 0; m < 4; m = m + 1)
                check(ops[k], m[1] ? ONES : ZEROS, m[0] ? ONES : ZEROS);

        // 2) directed tests: one with Zero=1 and one with Zero=0 for each function
        check(C_AND,   64'hAAAA_AAAA_AAAA_AAAA, 64'h5555_5555_5555_5555);  // result 0      -> Zero=1
        check(C_AND,   64'h0123_4567_89AB_CDEF, ONES);                      // result != 0   -> Zero=0
        check(C_OR,    ZEROS,                   ZEROS);                     // result 0      -> Zero=1
        check(C_OR,    64'h0000_0000_0000_0001, ZEROS);                     // result != 0   -> Zero=0
        check(C_ADD,   64'd5,                   64'hFFFF_FFFF_FFFF_FFFB);   // 5 + (-5) = 0  -> Zero=1
        check(C_ADD,   64'd5,                   64'd7);                     // 12            -> Zero=0
        check(C_SUB,   64'd42,                  64'd42);                    // 0             -> Zero=1
        check(C_SUB,   64'd42,                  64'd7);                     // 35            -> Zero=0
        check(C_PASSB, 64'h1234_5678_9ABC_DEF0, ZEROS);                     // B = 0         -> Zero=1
        check(C_PASSB, ZEROS,                   64'h1234_5678_9ABC_DEF0);   // B != 0        -> Zero=0

        // 3) ADD overflow (the 64-bit result wraps around)
        check(C_ADD, 64'h7FFF_FFFF_FFFF_FFFF, 64'd1);                       // max positive + 1: signed overflow, result 0x8000...
        check(C_ADD, ONES,                    64'd1);                       // carry out of bit 63, wraps to 0 (Zero=1)
        check(C_ADD, 64'h8000_0000_0000_0000, 64'h8000_0000_0000_0000);     // most negative twice: signed overflow, wraps to 0

        // 4) 100 random (BusA, BusB) pairs for every function
        for (k = 0; k < 5; k = k + 1)
            for (n = 0; n < 100; n = n + 1)
                check(ops[k], {$random, $random}, {$random, $random});

        if (errors == 0)
            $display("PASS: ALU, %0d tests, 0 errors", tests);
        else
            $display("FAIL: ALU, %0d errors in %0d tests", errors, tests);

        #10 $finish;
    end

endmodule
