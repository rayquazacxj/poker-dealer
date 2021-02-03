module motor(
    input clk,
    input rst,
    input [1:0] motor_state,
    input en,
    output  A,
    output  B
);
    parameter RESET=2'b00;
    parameter ROTATE=1'b01;
    parameter WAIT=2'b10;
    parameter REMAIN=2'b11;

    wire de_enable,pul_enable,clkDiv15,clkDiv22;
    wire enable;
    assign enable= (motor_state==WAIT && en==1) ? 1 : 0;
   
    
    clock_divider c6(clk, clkDiv15);
    clock_divider c22(clk, clkDiv22);
 
    PWM_genA mA(clkDiv15, rst,enable,motor_state, A);
    PWM_genB mB(clkDiv15, rst,enable,motor_state, B);
    
    
endmodule


//generte PWM by input frequency & duty
module PWM_genA (
    input wire clk,
    input wire reset,
    input enable,
    input [1:0]motor_state,
    output reg PWM
);
    //wire [31:0] count_max = 100_000_000 / freq;
    
    parameter[1:0] STOP=2'd0;
    parameter[1:0] FORWARD=2'd1;
    parameter[1:0] REVERSE=2'd2;
    
    parameter WAIT=2'b10;
    
    wire [31:0] count_max = 1;
    wire [31:0] count_duty = 0;//count_max * duty / 1024;
    reg [31:0] count,next_count;
    reg next_PWM;
    reg once,next_once;
        
    reg [1:0]state,next_state;
    always @(posedge clk, posedge reset) begin
        if (reset)state<=STOP;
        else state<=next_state;
    end 
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            PWM <= 0;  
            once<=0; 
        end 
        else begin
            count <= next_count;
            PWM <= next_PWM;  
            once<=next_once; 
        end
    end
    always @(*) begin
        next_count = count;
        next_PWM = PWM;
        next_state = state;
        
        if(motor_state != WAIT)next_once = 0;
        
        case(state)
            STOP:begin
                next_count = 0;
                next_PWM = 0;
                next_state = STOP;
                if(enable && once==0)next_state = FORWARD;
            end
            FORWARD:begin
               if (count < 2) begin
                    next_count = count + 1;
                    next_PWM = 1;
                   
                end else begin
                    next_count = 0;
                    next_PWM = 0;
                    next_state = REVERSE;
                    //next_state = STOP;
                end
            end
            REVERSE:begin
               if (count < 1) begin
                    next_count = count + 1;
                    next_PWM = 0;
                end else begin
                    next_count = 0;
                    next_PWM = 0;
                    next_state = STOP;
                    next_once = 1;
                end
            end
          endcase

    end 
endmodule

module PWM_genB (
    input wire clk,
    input wire reset,
    input enable,
    input [1:0]motor_state,
    output reg PWM
);
    //wire [31:0] count_max = 100_000_000 / freq;
    
    parameter[1:0] STOP=2'd0;
    parameter[1:0] FORWARD=2'd1;
    parameter[1:0] REVERSE=2'd2;
    
    parameter WAIT=2'b10;
    
    wire [31:0] count_max = 1;
    wire [31:0] count_duty = 0; //count_max * duty / 1024;
    reg [31:0] count,next_count;
    reg next_PWM;
    reg once,next_once;
        
    reg [1:0]state,next_state;
    always @(posedge clk, posedge reset) begin
        if (reset)state<=STOP;
        else state<=next_state;
    end 
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            PWM <= 0;
            once<=0;           
        end 
        else begin
            count <= next_count;
            PWM <= next_PWM;
            once<=next_once;   
        end
    end
    always @(*) begin
        next_count = count;
        next_PWM = PWM;
        next_state = state;
       
       if(motor_state != WAIT)next_once = 0;
       
        case(state)
            STOP:begin
                next_count = 0;
                next_PWM = 0;
                next_state = STOP;
                if(enable && once==0)next_state = FORWARD;
            end
            FORWARD:begin
               if (count < 2) begin
                    next_count = count + 1;
                    next_PWM = 0;
                    
                end else begin
                    next_count = 0;
                    next_PWM = 0;
                    next_state = REVERSE;
                    //next_state = STOP;
                end
            end
            REVERSE:begin
               if (count < 1) begin
                    next_count = count + 1;
                    next_PWM = 1;
                    
                end else begin
                    next_count = 0;
                    next_PWM = 0;
                    next_state = STOP;
                    next_once = 1;
                end
            end
          endcase
        
        
    end 
endmodule
