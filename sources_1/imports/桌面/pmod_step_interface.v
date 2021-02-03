`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent
// Engineer: Kaitlyn Franz
// 
// Create Date: 01/23/2016 03:44:35 PM
// Design Name: Claw
// Module Name: pmod_step_interface
// Project Name: Claw_game
// Target Devices: Basys3
// Tool Versions: 2015.4
// Description: This module is the top module for a stepper motor controller
// using the PmodSTEP. It operates in Full Step mode and encludes an enable signal
// as well as direction control. The Enable signal is connected to switch one and 
// the direction signal is connected to switch zero. 
// 
// Dependencies: 
// 
// Revision: 1
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pmod_step_interface(
    input clk,
    input rst,
    input direction,
    input en,
    input play,
    input people,
    input  _mute,
    input _music,
    inout PS2_CLK,
    inout PS2_DATA,
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock
    output audio_sck, // serial clock
    output audio_sdin, // serial audio data input
    output [15:0] LED,
    output [6:0] DISPLAY,
    output [3:0] DIGIT,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync,
    output A,
    output B,
    output [3:0] signal_out
    );
    
    // Wire to connect the clock signal 
    // that controls the speed that the motor
    // steps from the clock divider to the 
    // state machine. 
    wire new_clk_net;
    wire [1:0] motor_state;
    wire [1:0]keyboard_choose;
    wire [3:0] BCD4;
    wire [3:0] random;

    wire clock_debounce,clk_segment,clk_segment_debounce;
    clock_divider #(.n(16)) clock_16(
        .clk(clk),
        .clk_div(clk_debounce)
    );
    clock_divider #(.n(13)) clock_13(
        .clk(clk),
        .clk_div(clk_segment)
    );
    clock_divider #(.n(10)) clock_10(
        .clk(clk),
        .clk_div(clk_segment_debounce)
    );

    wire debounced_play,debounced_people;
    wire onepulse_play,onepulse_people;
    debounce de1(.pb_debounced(debounced_play),.pb(play),.clk(clk_debounce));
    onepulse one1(.signal(debounced_play),.clk(new_clk_net),.op(onepulse_play));
    debounce de2(.pb_debounced(debounced_people),.pb(people),.clk(clk_segment_debounce));
    onepulse one2(.signal(debounced_people),.clk(clk_segment),.op(onepulse_people));
    
    // Clock Divider to take the on-board clock
    // to the desired frequency.
    clock_div clock_Div(
        .clk(clk),
        .rst(rst),
        .new_clk(new_clk_net)
        );
    
    // The state machine that controls which 
    // signal on the stepper motor is high.      
    pmod_step_driver control(
        .rst(rst),
        .direction(direction),
        .clk(new_clk_net),
        .en(en),
        .play(play), //or onepulse
        .LED(LED),
        .BCD4(BCD4),
        .keyboard_choose(keyboard_choose),
        .motor_state(motor_state),
        .random(random),
        .signal(signal_out)
        );

    seven_segment display(
        .rst(rst),
        .clk(clk_segment),
        .people(onepulse_people),
        .motor_state(motor_state),
        .BCD4(BCD4),
        .DISPLAY(DISPLAY),
        .DIGIT(DIGIT)
        );
    
    LFSR random_gen(
        .rst(rst),
        .clk(clk_debounce),
        .random(random)
    );
    
    speaker music(
    .clk(clk), // clock from crystal
    .rst(rst), // active high reset: BTNC
    ._mute(_mute), // SW: Mute
    ._nostop(en), // SW: Music
    .motor_state(motor_state),
    .audio_mclk(audio_mclk), // master clock
    .audio_lrck(audio_lrck), // left-right clock
    .audio_sck(audio_sck), // serial clock
    .audio_sdin(audio_sdin) // serial audio data input
    );
/*
    vga_control vga(
        .clk(clk),
        .rst(rst),
        .vgaRed(vgaRed),
        .vgaBlue(vgaBlue),
        .vgaGreen(vgaGreen),
        .hsync(hsync),
        .vsync(vsync)
    );*/
    VGA vgaa(
       .clk(clk),
       .rst(rst),
       .state(motor_state),
       .keyboard_choose(keyboard_choose),
       .vgaRed(vgaRed),
       .vgaGreen(vgaGreen),
       .vgaBlue(vgaBlue),
       .hsync(hsync),
       .vsync(vsync)
    );
    
    keyboard kb(
        .clk(clk),
        .rst(rst),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .keyboard_choose(keyboard_choose)
        
    );

    motor small_motor(
        .clk(clk),
        .rst(rst),
        .motor_state(motor_state),
        .en(en),
        .A(A),
        .B(B)
    );
    
endmodule
