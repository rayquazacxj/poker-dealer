## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	#create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
	
#Buttons
    set_property PACKAGE_PIN U18 [get_ports rst]                        
        set_property IOSTANDARD LVCMOS33 [get_ports rst]
    set_property PACKAGE_PIN W19 [get_ports play]                        
        set_property IOSTANDARD LVCMOS33 [get_ports play]
    set_property PACKAGE_PIN T18 [get_ports people]                        
        set_property IOSTANDARD LVCMOS33 [get_ports people]

# Switches
set_property PACKAGE_PIN V17 [get_ports {direction}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {direction}]
set_property PACKAGE_PIN V16 [get_ports {en}]					
    set_property IOSTANDARD LVCMOS33 [get_ports {en}]
set_property PACKAGE_PIN R2 [get_ports {_mute}]					
    set_property IOSTANDARD LVCMOS33 [get_ports {_mute}]




# 7 segment display
set_property PACKAGE_PIN W7 [get_ports {DISPLAY[0]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[0]}]
set_property PACKAGE_PIN W6 [get_ports {DISPLAY[1]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[1]}]
set_property PACKAGE_PIN U8 [get_ports {DISPLAY[2]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[2]}]
set_property PACKAGE_PIN V8 [get_ports {DISPLAY[3]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[3]}]
set_property PACKAGE_PIN U5 [get_ports {DISPLAY[4]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[4]}]
set_property PACKAGE_PIN V5 [get_ports {DISPLAY[5]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[5]}]
set_property PACKAGE_PIN U7 [get_ports {DISPLAY[6]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[6]}]

# set_property PACKAGE_PIN V7 [get_ports dp]
#    set_property IOSTANDARD LVCMOS33 [get_ports dp]

set_property PACKAGE_PIN U2 [get_ports {DIGIT[0]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DIGIT[0]}]
set_property PACKAGE_PIN U4 [get_ports {DIGIT[1]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DIGIT[1]}]
set_property PACKAGE_PIN V4 [get_ports {DIGIT[2]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DIGIT[2]}]
set_property PACKAGE_PIN W4 [get_ports {DIGIT[3]}]
   set_property IOSTANDARD LVCMOS33 [get_ports {DIGIT[3]}]
	
##Pmod Header JC
    ##Sch name = JC1
#    set_property PACKAGE_PIN K17 [get_ports {JC[0]}]                    
#        set_property IOSTANDARD LVCMOS33 [get_ports {JC[0]}]
    ##Sch name = JC2
    #set_property PACKAGE_PIN M18 [get_ports {JC[1]}]                    
        #set_property IOSTANDARD LVCMOS33 [get_ports {JC[1]}]
    ##Sch name = JC3
    #set_property PACKAGE_PIN N17 [get_ports {JC[2]}]                    
        #set_property IOSTANDARD LVCMOS33 [get_ports {JC[2]}]
    ##Sch name = JC4
    #set_property PACKAGE_PIN P18 [get_ports {JC[3]}]                    
        #set_property IOSTANDARD LVCMOS33 [get_ports {JC[3]}]
    #Sch name = JC7
    set_property PACKAGE_PIN L17 [get_ports {signal_out[0]}]                    
        set_property IOSTANDARD LVCMOS33 [get_ports {signal_out[0]}]
    #Sch name = JC8
    set_property PACKAGE_PIN M19 [get_ports {signal_out[1]}]                    
        set_property IOSTANDARD LVCMOS33 [get_ports {signal_out[1]}]
    #Sch name = JC9
    set_property PACKAGE_PIN P17 [get_ports {signal_out[2]}]                    
        set_property IOSTANDARD LVCMOS33 [get_ports {signal_out[2]}]
    #Sch name = JC10
    set_property PACKAGE_PIN R18 [get_ports {signal_out[3]}]                    
        set_property IOSTANDARD LVCMOS33 [get_ports {signal_out[3]}]

# Pmod I2S
set_property PACKAGE_PIN J1 [get_ports audio_mclk]
    set_property IOSTANDARD LVCMOS33 [get_ports audio_mclk]
set_property PACKAGE_PIN L2 [get_ports audio_lrck]
    set_property IOSTANDARD LVCMOS33 [get_ports audio_lrck]
set_property PACKAGE_PIN J2 [get_ports audio_sck]
    set_property IOSTANDARD LVCMOS33 [get_ports audio_sck]
set_property PACKAGE_PIN G2 [get_ports audio_sdin]
    set_property IOSTANDARD LVCMOS33 [get_ports audio_sdin]
  
#small motor
set_property PACKAGE_PIN A14 [get_ports A]
    set_property IOSTANDARD LVCMOS33 [get_ports A]
set_property PACKAGE_PIN A16 [get_ports B]
    set_property IOSTANDARD LVCMOS33 [get_ports B]


 # LEDs
 set_property PACKAGE_PIN U16 [get_ports {LED[0]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
 set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
 set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
 set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]
 set_property PACKAGE_PIN W18 [get_ports {LED[4]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
 set_property PACKAGE_PIN U15 [get_ports {LED[5]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
 set_property PACKAGE_PIN U14 [get_ports {LED[6]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
 set_property PACKAGE_PIN V14 [get_ports {LED[7]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
 set_property PACKAGE_PIN V13 [get_ports {LED[8]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[8]}]
 set_property PACKAGE_PIN V3 [get_ports {LED[9]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[9]}]
 set_property PACKAGE_PIN W3 [get_ports {LED[10]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[10]}]
 set_property PACKAGE_PIN U3 [get_ports {LED[11]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[11]}]
 set_property PACKAGE_PIN P3 [get_ports {LED[12]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[12]}]
 set_property PACKAGE_PIN N3 [get_ports {LED[13]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[13]}]
 set_property PACKAGE_PIN P1 [get_ports {LED[14]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[14]}]
 set_property PACKAGE_PIN L1 [get_ports {LED[15]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {LED[15]}]


##VGA Connector
set_property PACKAGE_PIN G19 [get_ports {vgaRed[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[0]}]
set_property PACKAGE_PIN H19 [get_ports {vgaRed[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[1]}]
set_property PACKAGE_PIN J19 [get_ports {vgaRed[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[2]}]
set_property PACKAGE_PIN N19 [get_ports {vgaRed[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[3]}]
set_property PACKAGE_PIN N18 [get_ports {vgaBlue[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[0]}]
set_property PACKAGE_PIN L18 [get_ports {vgaBlue[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[1]}]
set_property PACKAGE_PIN K18 [get_ports {vgaBlue[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[2]}]
set_property PACKAGE_PIN J18 [get_ports {vgaBlue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[3]}]
set_property PACKAGE_PIN J17 [get_ports {vgaGreen[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[0]}]
set_property PACKAGE_PIN H17 [get_ports {vgaGreen[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[1]}]
set_property PACKAGE_PIN G17 [get_ports {vgaGreen[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[2]}]
set_property PACKAGE_PIN D17 [get_ports {vgaGreen[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[3]}]
set_property PACKAGE_PIN P19 [get_ports hsync]
set_property IOSTANDARD LVCMOS33 [get_ports hsync]
set_property PACKAGE_PIN R19 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]




	
#7 segment display
#set_property PACKAGE_PIN W7 [get_ports {display[0]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {display[0]}]
#set_property PACKAGE_PIN W6 [get_ports {display[1]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {display[1]}]
#set_property PACKAGE_PIN U8 [get_ports {display[2]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {display[2]}]
#set_property PACKAGE_PIN V8 [get_ports {display[3]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {display[3]}]
#set_property PACKAGE_PIN U5 [get_ports {display[4]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {display[4]}]
#set_property PACKAGE_PIN V5 [get_ports {display[5]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {display[5]}]
#set_property PACKAGE_PIN U7 [get_ports {display[6]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {display[6]}]

#set_property PACKAGE_PIN V7 [get_ports dp]							
	#set_property IOSTANDARD LVCMOS33 [get_ports dp]

#set_property PACKAGE_PIN U2 [get_ports {digit[0]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {digit[0]}]
#set_property PACKAGE_PIN U4 [get_ports {digit[1]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {digit[1]}]
#set_property PACKAGE_PIN V4 [get_ports {digit[2]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {digit[2]}]
#set_property PACKAGE_PIN W4 [get_ports {digit[3]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {digit[3]}]


 
#USB HID (PS/2)
set_property PACKAGE_PIN C17 [get_ports PS2_CLK]						
	set_property IOSTANDARD LVCMOS33 [get_ports PS2_CLK]
	set_property PULLUP true [get_ports PS2_CLK]
set_property PACKAGE_PIN B17 [get_ports PS2_DATA]					
	set_property IOSTANDARD LVCMOS33 [get_ports PS2_DATA]	
	set_property PULLUP true [get_ports PS2_DATA]





#         #leds
#           set_property PACKAGE_PIN U16 [get_ports {signal_out[0]}]                    
#               set_property IOSTANDARD LVCMOS33 [get_ports {signal_out[0]}]
#           #Sch name = JC8
#           set_property PACKAGE_PIN E19 [get_ports {signal_out[1]}]                    
#               set_property IOSTANDARD LVCMOS33 [get_ports {signal_out[1]}]
#           #Sch name = JC9
#           set_property PACKAGE_PIN U19 [get_ports {signal_out[2]}]                    
#               set_property IOSTANDARD LVCMOS33 [get_ports {signal_out[2]}]
#           #Sch name = JC10
#           set_property PACKAGE_PIN V19 [get_ports {signal_out[3]}]                    
#               set_property IOSTANDARD LVCMOS33 [get_ports {signal_out[3]}]
               
               
               set_property CFGBVS Vcco [current_design]
               set_property config_voltage 3.3 [current_design]
