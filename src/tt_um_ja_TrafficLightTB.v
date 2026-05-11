`timescale 1us / 1ns
module tt_um_Onchip_TrafficLight_TB;
    reg clk;
    reg [7:0] ui_in;
    wire [7:0] uo_out;

    tt_um_Onchip_TrafficLight uut(
        .clk(clk),
        .ui_in(ui_in),
        .uo_out(uo_out)
    );

    //Clock Generation
    always #15.25 clk = ~clk;

    initial begin
        $dumpfile("Traffic_Light.vcd");
        $dumpvars(0, uut);
        clk = 0;
        ui_in[0] = 1;
        #1 ui_in[0] = 0;  //Reset goes low after 10 time units

        // Simulate for a period of time
        #100000000;
        $finish;
    end

    initial begin
        $monitor("State = %b, Red = %b, Yellow = %b, Green = %b", uut.state, uo_out[2], uo_out[1], uo_out[0]);
    end
endmodule