`timescale 1ns/1ps
// Logical interface: pressed=1. Board polarity is configured only after schematic review.
module button_conditioner #(
    parameter integer STABLE_CYCLES = 1000000,
    parameter integer ACTIVE_LOW = 0
) (
    input wire clk,
    input wire resetn,
    input wire button_raw,
    output reg pressed
);
    (* ASYNC_REG = "TRUE" *) reg sync1, sync2;
    localparam integer CW = (STABLE_CYCLES < 2) ? 1 : $clog2(STABLE_CYCLES);
    reg [CW-1:0] count;
    wire normalized = ACTIVE_LOW ? ~sync2 : sync2;
    always @(posedge clk) begin
        if (!resetn) begin
            sync1 <= ACTIVE_LOW ? 1'b1 : 1'b0;
            sync2 <= ACTIVE_LOW ? 1'b1 : 1'b0;
            pressed <= 1'b0;
            count <= 0;
        end else begin
            sync1 <= button_raw;
            sync2 <= sync1;
            if (normalized == pressed) count <= 0;
            else if (count == STABLE_CYCLES-1) begin
                pressed <= normalized;
                count <= 0;
            end else count <= count + 1'b1;
        end
    end
endmodule
