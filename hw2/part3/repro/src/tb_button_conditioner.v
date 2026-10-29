`timescale 1ns/1ps
module tb_button_conditioner;
    reg clk=0, resetn=0, raw=0;
    wire pressed, pressed_low;
    integer rises=0, falls=0;
    always #10 clk=~clk;
    button_conditioner #(.STABLE_CYCLES(4)) dut(clk,resetn,raw,pressed);
    button_conditioner #(.STABLE_CYCLES(4),.ACTIVE_LOW(1)) low_dut(clk,resetn,~raw,pressed_low);
    always @(posedge pressed) rises=rises+1;
    always @(negedge pressed) if(resetn) falls=falls+1;
    task cycles;
        input integer n;
        repeat(n) @(negedge clk);
    endtask
    task expect_state;
        input integer state;
        begin
            if (pressed !== state[0] || pressed_low !== state[0]) begin
                $display("FAIL expected=%d high=%b low=%b",state,pressed,pressed_low);
                $fatal(1);
            end
        end
    endtask
    initial begin
        cycles(3); resetn=1; cycles(3); expect_state(0);
        raw=1; cycles(1); raw=0; cycles(2); raw=1; cycles(2); raw=0;
        cycles(8); expect_state(0);
        raw=1; cycles(8); expect_state(1);
        cycles(20); expect_state(1);
        raw=0; cycles(1); raw=1; cycles(2); raw=0; cycles(2); raw=1;
        cycles(8); expect_state(1);
        raw=0; cycles(8); expect_state(0);
        if(rises != 1 || falls != 1) $fatal(1,"edge count mismatch");
        $display("PASS: bounce rejected, one press/release, hold stable, both polarities");
        resetn=0; cycles(3); expect_state(0);
        $finish;
    end
endmodule
