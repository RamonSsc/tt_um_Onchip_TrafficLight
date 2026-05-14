module tt_um_Onchip_TrafficLight(
    input  wire [7:0] ui_in,  
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,                                          //Clock
    input  wire       rst_n                                 
);

wire [7:0] freqSet = 8'b11111111;
wire [7:0] OutVfreq;
wire Newclk = OutVfreq[6]; 
 
tt_um_RS_Vfreq Vfreq(
        .clk(clk),
        .ui_in(freqSet),
        .rst_n(rst_n),
//        .uo_out(uo_outVfreq),                                     //Output not used due to synthesis failure.
        .uio_in(uio_in),
        .uio_out(OutVfreq),
//        .uio_oe(uio_oeVfreq),                                     //Output not used due to synthesis failure.
        .ena(ena)
    );

assign uio_oe = 8'b11111111;                                        //Assign Output to evade synthesis problems

//Real Inputs/Outputs
wire Start;
reg Red_Light, Yellow_Light, Green_Light;                           //Color Outputs

assign Start = ui_in[0];
assign uo_out = {{5{1'b1}} , Red_Light, Yellow_Light, Green_Light}; //Seven Segment Output
assign uio_out = {{5{1'b1}} , Red_Light, Yellow_Light, Green_Light};//Bidirectional Output

// State Definition
parameter IDLE = 3'b000;                                            //Initial State
parameter RED = 3'b001;                                             //Stop
parameter RED2GREEN = 3'b010;                                       //Stop to Run Transition
parameter GREEN = 3'b011;                                           //Run 
parameter GREEN2RED = 3'b100;                                       //Run to Stop Transition

// Time Intervals
parameter TIME_RED = 6'd30;
parameter TIME_YELLOW = 6'd3;
parameter TIME_GREEN = 6'd20;

//FSM States
reg [2:0] state, next_state;
reg [5:0] counter;

//FSM Logic
always @(posedge Newclk or posedge Start) begin
    if (Start) begin
        state <= IDLE;                                              //Initial State
    end else begin
        state <= next_state;                                        //State change every clock period
    end
end

//Next State Logic
always @* begin
    case(state)
        IDLE: begin
            next_state = RED;                                       //Change to RED    
        end
        RED: begin
            if(counter > TIME_RED)                                  //Counter check for RED signal
                next_state = RED2GREEN;
            else
                next_state = RED;
        end
        RED2GREEN: begin
            if(counter > TIME_RED+TIME_YELLOW)                      //Counter check for transition signal
                next_state = GREEN;
            else
                next_state = RED2GREEN;       
        end
        GREEN: begin
            if(counter > TIME_RED+TIME_YELLOW+TIME_GREEN)           //Counter check for GREEN signal
                next_state = GREEN2RED;       
            else
                next_state = GREEN;         
        end
        GREEN2RED: begin
            if(counter > TIME_RED+2*TIME_YELLOW+TIME_GREEN)         //Counter check for transition signal
                next_state = RED;             
            else
                next_state = GREEN2RED;         
        end         
        default: begin
            next_state = IDLE;                                      //Default State
        end
    endcase
end

//Current State Logic
always @(posedge Newclk) begin
    if (counter <= TIME_RED+2*TIME_YELLOW+TIME_GREEN 
        & (state == RED | state == RED2GREEN | state == GREEN | state == GREEN2RED)) begin
        counter <= counter + 6'b000001;                             //Initial State
    end else begin
        counter <= 0;                                               //State change every clock period
    end
end

//Output assign
always @* begin
    case(state)
        IDLE: begin
            Red_Light = 0;
            Yellow_Light = 0;
            Green_Light = 0;
        end
        RED: begin
            Red_Light = 1;
            Yellow_Light = 0;
            Green_Light = 0;
        end
        RED2GREEN: begin
            Red_Light = 1;
            Yellow_Light = 1;
            Green_Light = 0;
        end
        GREEN: begin
            Red_Light = 0;
            Yellow_Light = 0;
            Green_Light = 1;
        end
        GREEN2RED: begin
            Red_Light = 0;
            Yellow_Light = 1;
            Green_Light = 0;
        end
        default: begin
            Red_Light = 1;
            Yellow_Light = 1;
            Green_Light = 1;
        end
    endcase
end


    wire _unused = &{ui_in[7:1], OutVfreq[7], OutVfreq[5:0], 1'b0};

endmodule