//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module tt_um_RS_Vfreq(
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    //output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    //output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to 
    );
    
    reg [7:0] counter;
    reg [6:0] second_counter;
    wire [7:0] comp;
    wire signal;
    wire counter_reset, counter_enable;
    //assign uio_oe[7:0] = 8'b11111111; //all bidirectional path used as outputs
    //assign uo_out[7:0] = 8'd0; //no 7-segment used
    assign comp = ui_in - 1;
    assign signal = counter >= comp; //compare the counter
    assign uio_out[7] = signal;
    assign uio_out[6:0] = second_counter;

    //Principal signal used as rst and clk
    assign counter_reset = signal;
    assign counter_enable = signal; // Enable the second counter when the signal is high
    
    always @(posedge clk) begin
        // if reset, set principal path & counter to 0
        if (!rst_n) begin
            counter <= 8'd0;
        end 
        else begin
            if (counter_reset) 
                counter <= 8'd0;
            else 
                counter <= counter + 1;
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            second_counter <= 7'd0;
        end 
        else if (counter_enable) begin
            if (second_counter == ((2**7)-1)) //127
                second_counter <= 7'd0;
            else 
                second_counter <= second_counter + 1;
        end
    end

    wire _unused = &{ena, uio_in[7:0], 1'b0};
endmodule
