module keyboard(
	input clk,
	input rst,
	inout PS2_DATA,
	inout PS2_CLK,
	output reg[1:0]keyboard_choose
	//output reg[3:0]DIGIT,
	//output reg[6:0]DISPLAY
);

	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;
	
	reg[2:0] state,next_state;
	
	/*
	clk_divider #(26)clkdiv26(clk, clk_div26);
	clk_divider #(23)clkdiv23(clk, clk_div23);
	clk_divider #(11)clkdiv11(clk, clk_div11);
	*/
	parameter [8:0]KEY_CODES1 = 9'b0_0110_1001;
    parameter [8:0]KEY_CODES2 = 9'b0_0111_0010;

    
	KeyboardDecoder key (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	reg[1:0]next_keyboard_choose;
    always@(posedge clk or posedge rst)begin
        if(rst)keyboard_choose<=0;
        else keyboard_choose<= next_keyboard_choose;
    end
        
    
	always@(*)begin
        next_keyboard_choose = keyboard_choose;
		if( been_ready &&  key_down[last_change] )begin
		     
             if(last_change==KEY_CODES1 )next_keyboard_choose=1;
             else if(last_change==KEY_CODES2 )next_keyboard_choose=2;
             //else keyboard_choose=0;
           
		end
		
	end
	
endmodule 