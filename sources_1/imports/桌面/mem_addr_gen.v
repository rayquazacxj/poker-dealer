module mem_addr_gen(
   input clk,
   input rst,
   input [1:0]outer_state,
   input [9:0] h_cnt,
   input [9:0] v_cnt,
   input [1:0]choose, // 0: no choose, 1: choose sequential ,2: choose random
   output reg red,
   output reg green,
   output reg black,
   output reg[16:0] pixel_addr
   );
    
   
   parameter[1:0] INIT = 0;
   parameter[1:0] CHOOSE_SEQ = 1;
   parameter[1:0] CHOOSE_RANDOM = 2;
   
   reg [1:0]state,next_state;
   
   parameter RESET=2'b00;
   //parameter ROTATE=1'b01;
    //parameter WAIT=2'b10;
    //parameter REMAIN=2'b11;
  
  always @ (posedge clk or posedge rst) begin
		if(rst)begin
            state <= INIT;
        end
        else begin
            state <= next_state;
        end
    end
	
	always@(*)begin
		black =0;
		
		if(outer_state== RESET)begin
			case(state)
				INIT:begin
					if(choose==1)next_state = CHOOSE_SEQ ;
					else if(choose==2)next_state = CHOOSE_RANDOM ;
					else next_state = INIT;
					
				end
				
				CHOOSE_SEQ:begin
					next_state = CHOOSE_SEQ;
					if(choose==2)next_state = CHOOSE_RANDOM ;
				end
				CHOOSE_RANDOM:begin
					next_state = CHOOSE_RANDOM; 
					if(choose==1)next_state = CHOOSE_SEQ ;
				end
				
			endcase
		end
		else black =1;
		
    end
   
   always @ (*) begin  //640*480 --> 320*240
        red=0; 
		green=0;
		if(state == CHOOSE_SEQ)begin
			if((h_cnt>>1) >= 160  )begin //r 180 270
				//pixel_addr = (((h_cnt>>1) - position)%320 + 320*(v_cnt>>1))% 76800;
				if((h_cnt>>1) >= 160 && (h_cnt>>1) < 180)green=1;
				else if ((h_cnt>>1) >= 270 )green=1;
				else if ((h_cnt>>1) >= 180 && (h_cnt>>1) < 270 && (v_cnt>>1) <= 60 )green=1;
				else if ((h_cnt>>1) >= 180 && (h_cnt>>1) < 270 && (v_cnt>>1) >= 165 )green=1;
				else pixel_addr = (((h_cnt>>1) )%320 + 320*(v_cnt>>1))% 76800;
			end
		end
		else if(state == CHOOSE_RANDOM)begin
			if((h_cnt>>1) < 160  )begin //r
				//pixel_addr = (((h_cnt>>1) - position)%320 + 320*(v_cnt>>1))% 76800; 
				//red=1;
				if((h_cnt>>1) < 40 )red=1;
				else if ((h_cnt>>1) >= 120 )red=1;
				else if ((h_cnt>>1) >= 40 && (h_cnt>>1) < 120 && (v_cnt>>1) <= 60 )red=1;
				else if ((h_cnt>>1) >= 40 && (h_cnt>>1) < 120 && (v_cnt>>1) >= 165 )red=1;
				else pixel_addr = (((h_cnt>>1) )%320 + 320*(v_cnt>>1))% 76800;
			end
		end
		else  pixel_addr = (((h_cnt>>1) )%320 + 320*(v_cnt>>1))% 76800;
    
	end
   
   
   
   
   
   
   /*
   
        if(state == TB)begin
			
			if( (v_cnt>>1) >= 240 - position )begin //  b.
				pixel_addr = ((h_cnt>>1) + 320*(v_cnt>>1) + 320 * (120+position))% 76800; //up down	
			end
			else if ( (v_cnt>>1) <  position )begin // t
				pixel_addr = ((h_cnt>>1) + 320*(v_cnt>>1) - 320 * (120+position))% 76800;
			end
			else  begin
			 pixel_addr = 0;
			 black = 1;
			end
                
		end
		else if(state == LR)begin
			
			if ((h_cnt>>1) < 160 - position )begin //l .
				pixel_addr = (((h_cnt>>1) + position)%320 + 320*(v_cnt>>1))% 76800; // left right
				
			end
			else if((h_cnt>>1) >= 160 + position )begin //r
				pixel_addr = (((h_cnt>>1) - position)%320 + 320*(v_cnt>>1))% 76800; 
				
			end
			
			else  begin
			 pixel_addr = 0;
			 black = 1;
			end
			
		end
		else begin
			pixel_addr= ((h_cnt>>1)+320*(v_cnt>>1) )% 76800;
		end
	end*/
	
endmodule