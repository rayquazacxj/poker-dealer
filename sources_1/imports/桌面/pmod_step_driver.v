`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent    
// Engineer: Kaitlyn Franz
// 
// Create Date: 01/23/2016 03:44:35 PM
// Design Name: Claw
// Module Name: pmod_step_driver
// Project Name: Claw_game
// Target Devices: Basys3
// Tool Versions: 2015.4
// Description: This is the state machine that drives
// the output to the PmodSTEP. It alternates one of four pins being
// high at a rate set by the clock divider. 
// 
// Dependencies: 
// 
// Revision: 1
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

module pmod_step_driver(
    input rst,
    input direction,
    input clk,
    input en,
    input play,
    input [3:0] BCD4,
    input [3:0] random,
    input [1:0] keyboard_choose,
    output reg [1:0] motor_state,
    output reg [15:0] LED,
    output reg [3:0] signal
    );
    
    // local parameters that hold the values of
    // each of the states. This way the states
    // can be referenced by name.
    localparam sig4 = 3'b001;
    localparam sig3 = 3'b011;
    localparam sig2 = 3'b010;
    localparam sig1 = 3'b110;
    localparam sig0 = 3'b000;

    parameter RESET=2'b00;
    parameter ROTATE=1'b01;
    parameter WAIT=2'b10;
    parameter REMAIN=2'b11;
    reg [1:0]  motor_next_state;
    // reg [8:0] rotate_four;
    // reg [9:0] rotate_three;
    // reg [9:0] rotate_two;
    reg [10:0] rotate;
    reg [12:0] stop_four; //30second
    reg [7:0] led_stop; //1second
    reg [5:0] cards;
    reg changetowait;
    reg dir;
    reg random_choose;
    reg [10:0] how_rotate;
    reg [2:0] rotate_round;
    reg [3:0] get_random;

    //避免發牌中途轉換dir switch導致發牌順序亂掉，只紀錄按下開始時的數值
    always @ (posedge clk, posedge rst)
    begin
        if (rst == 1'b1)
            dir=0;
        else if(motor_state==RESET)
            dir=direction;
    end
    always @ (posedge clk, posedge rst)
    begin
        if (rst == 1'b1)
            random_choose=0;
        else if(motor_state==RESET)
            if(keyboard_choose==2'd1)
                random_choose=0;
            else if(keyboard_choose==2'd2)
                random_choose=1;
    end

    //LED閃爍
    always @ (posedge clk, posedge rst)
    begin
        if (rst == 1'b1)
            LED[15:0] = 0;
        else if(led_stop==8'b11111111)
            LED =~LED;
        else if(motor_state==WAIT)
            LED=LED;
        else
            LED[15:0]=0;
    end

    always @ (posedge clk, posedge rst)
    begin
        if (rst == 1'b1)
            led_stop = 0;
        else if(motor_state==WAIT)
            led_stop= led_stop+1'b1;
        else
            led_stop=0;
    end

    //發牌時間
    always @ (posedge clk, posedge rst)
    begin
        if (rst == 1'b1)
            stop_four = 0;
        else if(motor_state!=WAIT)
            stop_four = 0;
        else if(en==0)
            stop_four=stop_four;
        else
            stop_four = stop_four+1;
    end

    //轉角度
    always @ (posedge clk, posedge rst)
    begin
        if (rst == 1'b1)
            rotate = 0;
        else if(en==0)
            rotate=rotate;
        else if(motor_state==ROTATE||motor_state==REMAIN)
            rotate = rotate+1;
        else
            rotate = 0;
    end


    //記錄發多少牌
    always @ (posedge clk, posedge rst)
    begin
        if (rst == 1'b1)
            cards = 0;
        else if(motor_state==RESET)
            cards = 0;
        else if(changetowait)
            cards=cards+1'd1;
    end

    //FSM-順序性發牌
    always @ (posedge clk, posedge rst)
    begin
        if (rst == 1'b1)
            motor_state = RESET;
        else 
            motor_state = motor_next_state;
    end
    always @* begin
        motor_next_state=RESET;
        changetowait=0;
        case(motor_state)
        RESET: begin
            if(play)
                motor_next_state=ROTATE;
            else
                motor_next_state=RESET;
        end
        ROTATE: begin
            if((BCD4==4'd4)&&(rotate==how_rotate)) begin
                motor_next_state=WAIT;
                changetowait=1;
            end
            else if((BCD4==4'd3)&&(rotate==how_rotate)) begin
                motor_next_state=WAIT;
                changetowait=1;
            end
            else if((BCD4==4'd2)&&(rotate==how_rotate)) begin
                motor_next_state=WAIT;
                changetowait=1;
            end
            else
                motor_next_state=ROTATE;
        end
        WAIT: begin
            if(stop_four==10'b111111111) //30second is 13 bit
                motor_next_state=ROTATE;
            else if(BCD4==4'd3&&cards==6'd51)
                motor_next_state=REMAIN;
            else if(cards==6'd52)
                motor_next_state=RESET;
            else
                motor_next_state=WAIT;
        end
        REMAIN: begin
            if(rotate==10'd341) begin
                motor_next_state=WAIT;
            end
            else
                motor_next_state=REMAIN;
        end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if(rst)
            get_random=4'b1000;
        else if(BCD4==4'd4&&changetowait&&rotate_round==3'd3)
            get_random=random;
        else if(BCD4==4'd3&&changetowait&&rotate_round==3'd2)
            get_random=random;
        else if(BCD4==4'd2&&changetowait&&rotate_round==3'd1)
            get_random=random;

    end
    always @(posedge clk or posedge rst) begin
        if(rst)
            rotate_round<=0;
        else if(changetowait) begin
            if(BCD4==4'd4&&rotate_round==3'd3)
                rotate_round=0;
            else if(BCD4==4'd3&&rotate_round==3'd2)
                rotate_round=0;
            else if(BCD4==4'd2&&rotate_round==3'd1)
                rotate_round=0;
            else
                rotate_round<=rotate_round+1'd1;
        end
    end


    always @(posedge clk or posedge rst) begin
        if(rst)
            how_rotate=9'd50;
        else if(random_choose==1'b0) begin
            if(BCD4==4'd4)
                how_rotate=9'd50;
            else if(BCD4==4'd3)
                how_rotate=9'd67;
            else
                how_rotate=9'd100;
        end
        else begin
        if(motor_state==ROTATE) begin
            if((BCD4==4'd4)) begin
                if(get_random==4'b1000||get_random==4'b0101) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd100;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd100;
                    else if(rotate_round==3'd2)
                        how_rotate=9'd50;
                    else
                        how_rotate=9'd100;
                end
                else if(get_random==4'b0100||get_random==4'b0111) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd150;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd150;
                    else if(rotate_round==3'd2)
                        how_rotate=9'd100;
                    else
                        how_rotate=9'd50;
                end
                else if(get_random==4'b0010||get_random==4'b0011) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd50;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd50;
                    else if(rotate_round==3'd2)
                        how_rotate=9'd50;
                    else
                        how_rotate=9'd50;
                end
                else if(get_random==4'b0001||get_random==4'b1010) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd50;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd100;
                    else if(rotate_round==3'd2)
                        how_rotate=9'd150;
                    else
                        how_rotate=9'd100;
                end
                else if(get_random==4'b1101||get_random==4'b1011) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd50;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd100;
                    else if(rotate_round==3'd2)
                        how_rotate=9'd50;
                    else
                        how_rotate=9'd100;
                end
                else if(get_random==4'b1110||get_random==4'b1001) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd50;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd150;
                    else if(rotate_round==3'd2)
                        how_rotate=9'd100;
                    else
                        how_rotate=9'd50;
                end
                else if(get_random==4'b0110||get_random==4'b1100) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd150;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd100;
                    else if(rotate_round==3'd2)
                        how_rotate=9'd50;
                    else
                        how_rotate=9'd100;
                end
                else begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd150;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd50;
                    else if(rotate_round==3'd2)
                        how_rotate=9'd50;
                    else
                        how_rotate=9'd50;
                end
            end
            else if((BCD4==4'd3)) begin
                if(get_random==4'b0100||get_random==4'b0111||get_random==4'b0110||get_random==4'b1100) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd67;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd67;
                    else
                        how_rotate=9'd67;
                end
                else if(get_random==4'b0010||get_random==4'b0011||get_random==4'b1110||get_random==4'b1001) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd67;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd133;
                    else
                        how_rotate=9'd133;
                end
                else if(get_random==4'b0001||get_random==4'b1010||get_random==4'b1101||get_random==4'b1011) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd133;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd67;
                    else
                        how_rotate=9'd67;
                end
                else begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd133;
                    else if(rotate_round==3'd1)
                        how_rotate=9'd133;
                    else
                        how_rotate=9'd133;
                end
            end
            else if((BCD4==4'd2)) begin
                if(get_random==4'b0010||get_random==4'b0011||get_random==4'b1110||get_random==4'b1001||get_random==4'b0001||get_random==4'b1010||get_random==4'b1101||get_random==4'b1011) begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd200;
                    else
                        how_rotate=9'd100;
                end
                else begin
                    if(rotate_round==3'd0)
                        how_rotate=9'd100;
                    else
                        how_rotate=9'd100;
                end
            end
        end
        end
    end
    
    // register values to hold the values
    // of the present and next states. 
    reg [2:0] present_state, next_state;
    
    // run when the present state, direction
    // or enable signals change.
    always @ (present_state, dir, en)
    begin
        // Based on the present state
        // do something.
        case(present_state)
        // If the state is sig4, the state where
        // the fourth signal is held high. 
        sig4:
        begin
            // If direction is 0 and enable is high
            // the next state is sig3. If direction
            // is high and enable is high
            // next state is sig1. If enable is low
            // next state is sig0.
            if (dir == 1'b0 && en == 1'b1)
                next_state = sig3;
            else if (dir == 1'b1 && en == 1'b1)
                next_state = sig1;
            else 
                next_state = sig0;
        end  
        sig3:
        begin
            // If direction is 0 and enable is high
            // the next state is sig2. If direction
            // is high and enable is high
            // next state is sig4. If enable is low
            // next state is sig0.
            if (dir == 1'b0&& en == 1'b1)
                next_state = sig2;
            else if (dir == 1'b1 && en == 1'b1)
                next_state = sig4;
            else 
                next_state = sig0;
        end 
        sig2:
        begin
            // If direction is 0 and enable is high
            // the next state is sig1. If direction
            // is high and enable is high
            // next state is sig3. If enable is low
            // next state is sig0.
            if (dir == 1'b0&& en == 1'b1)
                next_state = sig1;
            else if (dir == 1'b1 && en == 1'b1)
                next_state = sig3;
            else 
                next_state = sig0;
        end 
        sig1:
        begin
            // If direction is 0 and enable is high
            // the next state is sig4. If direction
            // is high and enable is high
            // next state is sig2. If enable is low
            // next state is sig0.
            if (dir == 1'b0&& en == 1'b1)
                next_state = sig4;
            else if (dir == 1'b1 && en == 1'b1)
                next_state = sig2;
            else 
                next_state = sig0;
        end
        sig0:
        begin
            // If enable is high
            // the next state is sig1. 
            // If enable is low
            // next state is sig0.
            if (en == 1'b1)
                next_state = sig1;
            else 
                next_state = sig0;
        end
        default:
            next_state = sig0; 
        endcase
    end 
    
    // State register that passes the next
    // state value to the present state 
    // on the positive edge of clock
    // or reset. 
    always @ (posedge clk, posedge rst)
    begin
        if (rst == 1'b1)
            present_state = sig0;
        else if((motor_state==ROTATE)||(motor_state==REMAIN))
            present_state = next_state;
        else
            present_state = sig0;
    end
    
    // Output Logic
    // Depending on the state
    // output signal has a different
    // value.     
    always @ (posedge clk)
    begin
        if (present_state == sig4)
            signal = 4'b1000;
        else if (present_state == sig3)
            signal = 4'b0100;
        else if (present_state == sig2)
            signal = 4'b0010;
        else if (present_state == sig1)
            signal = 4'b0001;
        else
            signal = 4'b0000;
    end
endmodule



    // //轉角度_三人
    // always @ (posedge clk, posedge rst)
    // begin
    //     if (rst == 1'b1)
    //         rotate_three = 0;
    //     else if(motor_state!=ROTATE)
    //         rotate_three = 0;
    //     else if(en==0)
    //         rotate_three=rotate_three;
    //     else if(rotate_three>10'd682)
    //         rotate_three=0;
    //     else
    //         rotate_three = rotate_three+1;
    // end

    // //轉角度_二人
    // always @ (posedge clk, posedge rst)
    // begin
    //     if (rst == 1'b1)
    //         rotate_two = 0;
    //     else if(motor_state!=ROTATE)
    //         rotate_two = 0;
    //     else if(en==0)
    //         rotate_two=rotate_two;
    //     else
    //         rotate_two = rotate_two+1;
    // end