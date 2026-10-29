`timescale 1ns/1ps
// Exercises actual Vivado-generated AXI GPIO input IP. CPU/GIC/ISR are not simulated.
module tb_axi_gpio_irq;
    reg clk=0, resetn=0, raw=0;
    always #10 clk=~clk;
    wire pressed, irq;
    reg [8:0] awaddr=0, araddr=0;
    reg awvalid=0,wvalid=0,bready=0,arvalid=0,rready=0;
    reg [31:0] wdata=0;
    wire awready,wready,bvalid,arready,rvalid;
    wire [1:0] bresp,rresp;
    wire [31:0] rdata;
    reg [31:0] value;
    button_conditioner #(.STABLE_CYCLES(4)) filter(clk,resetn,raw,pressed);
    system_axi_gpio_button_0 gpio(
        .s_axi_aclk(clk),.s_axi_aresetn(resetn),
        .s_axi_awaddr(awaddr),.s_axi_awvalid(awvalid),.s_axi_awready(awready),
        .s_axi_wdata(wdata),.s_axi_wstrb(4'hf),.s_axi_wvalid(wvalid),.s_axi_wready(wready),
        .s_axi_bresp(bresp),.s_axi_bvalid(bvalid),.s_axi_bready(bready),
        .s_axi_araddr(araddr),.s_axi_arvalid(arvalid),.s_axi_arready(arready),
        .s_axi_rdata(rdata),.s_axi_rresp(rresp),.s_axi_rvalid(rvalid),.s_axi_rready(rready),
        .ip2intc_irpt(irq),.gpio_io_i(pressed));
    task cycles; input integer n; repeat(n) @(negedge clk); endtask
    task wr;
        input [8:0] addr; input [31:0] data;
        begin
            @(negedge clk); awaddr=addr;wdata=data;awvalid=1;wvalid=1;
            fork
                begin @(posedge clk); while(!awready) @(posedge clk); @(negedge clk); awvalid=0; end
                begin @(posedge clk); while(!wready) @(posedge clk); @(negedge clk); wvalid=0; end
            join
            bready=1;
            @(posedge clk); while(!bvalid) @(posedge clk);
            if(bresp!=0) $fatal(1,"AXI write error");
            @(negedge clk); bready=0;
            $display("AXI WRITE %h = %h, IRQ=%b", addr,data,irq);
        end
    endtask
    task rd;
        input [8:0] addr; output [31:0] data;
        begin
            @(negedge clk); araddr=addr;arvalid=1;
            @(posedge clk); while(!arready) @(posedge clk);
            @(negedge clk);arvalid=0;rready=1;
            @(posedge clk);while(!rvalid) @(posedge clk);
            data=rdata;if(rresp!=0) $fatal(1,"AXI read error");
            @(negedge clk);rready=0;
            $display("AXI READ %h = %h, IRQ=%b", addr,data,irq);
        end
    endtask
    initial begin #200000; $fatal(1,"AXI simulation timeout"); end
    initial begin
        // Hold reset beyond the simulator's 100 ns global startup reset.
        cycles(20);resetn=1;cycles(10);
        // Input initialization itself may leave a pending change event.
        // Match the application: clear only current status before enabling.
        rd(9'h120,value);wr(9'h120,value & 1);
        wr(9'h128,1);wr(9'h11c,32'h80000000);cycles(4);
        rd(9'h128,value);if(value!==1) $fatal(1,"IER write failed");
        rd(9'h11c,value);if(value!==32'h80000000) $fatal(1,"GIER write failed");
        if(irq!==0) $fatal(1,"unexpected initial IRQ");
        raw=1;cycles(1);raw=0;cycles(12);
        if(irq!==0) $fatal(1,"bounce generated interrupt");
        raw=1;cycles(24);
        $display("pressed=%b raw=%b irq=%b",pressed,raw,irq);
        rd(9'h000,value);rd(9'h120,value);
        if(irq!==1) $fatal(1,"press IRQ missing");
        rd(9'h000,value);if(value!==1) $fatal(1,"pressed data mismatch");
        rd(9'h120,value);if(value!==1) $fatal(1,"IPISR mismatch");
        cycles(10);if(irq!==1) $fatal(1,"IRQ did not stay high until clear");
        wr(9'h120,value);cycles(5);if(irq!==0) $fatal(1,"clear failed");
        cycles(12);if(irq!==0) $fatal(1,"held button retriggered");
        raw=0;cycles(40);if(irq!==1) $fatal(1,"release IRQ missing");
        rd(9'h000,value);if(value!==0) $fatal(1,"released data mismatch");
        wr(9'h120,1);cycles(5);if(irq!==0) $fatal(1,"release clear failed");
        wr(9'h128,0);raw=1;cycles(40);if(irq!==0) $fatal(1,"IER masking failed");
        wr(9'h128,1);cycles(5);if(irq!==1) $fatal(1,"pending event not delivered");
        wr(9'h120,1);cycles(5);
        $display("PASS: actual AXI GPIO press/release IRQ, level held, clear, hold, mask/pending, bounce");
        $finish;
    end
endmodule
