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
 
tt_um_RS_Vfreq Vfreq(
        .clk(clk),
        .ui_in(freqSet),
        .rst_n(rst_n),
        .uio_in(uio_in),
        .uio_out(OutVfreq),
        .ena(ena)
    );

assign uio_oe[7:0] = 8'b11111111;                                        //Assign Output to evade synthesis problems

//Real Inputs/Outputs
wire Start = ui_in[0];
reg Red_Light, Yellow_Light, Green_Light;                           //Color Outputs

assign uo_out[7:0] = {1'b1, Yellow_Light, {2{1'b0}}, Green_Light, {2{1'b0}}, Red_Light}; //Seven Segment Output dot G F E D C B A
assign uio_out[7:0] = {{5{1'b0}} , Red_Light, Yellow_Light, Green_Light};//Bidirectional Output

reg Newclk_reg;
reg start_reg; 

always @(posedge clk) begin
    if (!rst_n) begin
        Newclk_reg <= 1'b0;
        start_reg  <= 1'b0; 
    end else begin
        Newclk_reg <= OutVfreq[6];
        start_reg  <= Start;      
    end
end

//Edge detector
wire clk_enable = (OutVfreq[6] == 1'b1 && Newclk_reg == 1'b0);
wire start_pulse = (Start == 1'b1 && start_reg == 1'b0);

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
always @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;                                              //Initial State
    end
    else if (start_pulse) begin
        state <= IDLE;                                              //Initial State
    end    
    else if (clk_enable) begin
        state <= next_state;                                        //State change every clock period
    end
end

//Next State Logic
always @(*) begin
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
            if(counter > TIME_RED + TIME_YELLOW)                      //Counter check for transition signal
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
always @(posedge clk) begin
    if (!rst_n) begin
        counter <= 6'd0;
    end 
    else if (start_pulse) begin
        counter <= 6'd0;
    end
    else if (clk_enable) begin
        if (counter <= TIME_RED + 6'd2*TIME_YELLOW + TIME_GREEN 
            && (state == RED || state == RED2GREEN || state == GREEN || state == GREEN2RED)) begin
            counter <= counter + 6'd1;                             //Initial State
        end else begin
            counter <= 6'd0;                                               //State change every clock period
        end
    end
end

//Output assign
always @(*) begin
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