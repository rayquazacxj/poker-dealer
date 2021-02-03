module seven_segment(
    input clk,
    input rst,
    input people,
    input [1:0] motor_state,
    output reg [3:0] BCD4,
    output reg [6:0] DISPLAY,
    output reg [3:0] DIGIT
);

reg [3:0] value;
reg [3:0] BCD1,BCD2,BCD3;
parameter RESET=2'b00;
parameter ROTATE=2'b01;
parameter WAIT=2'b10;
parameter REMAIN=2'b11;

always @(posedge clk or posedge rst) begin
    if(rst)
        BCD4=4'd2;
    else if(motor_state==RESET)
        if(people) begin
            if(BCD4!=4'd4)
                BCD4=BCD4+1'd1;
            else
                BCD4=4'd2;
        end
end

always @(posedge clk) begin
        case(DIGIT)
        4'b1110:begin
            value=motor_state;
            DIGIT=4'b0111;
        end
        4'b0111:begin
            value=4'd0;
            DIGIT=4'b1011;
        end
        4'b1011:begin
            value=4'd0;
            DIGIT=4'b1101;
        end
        4'b1101:begin
            value=BCD4;
            DIGIT=4'b1110;
        end
        default begin
            value=4'd0;
            DIGIT=4'b0111;
        end
        endcase
    end

    always @* begin
        case(value)
        4'd0: DISPLAY=7'b1111111;
        4'd1: DISPLAY=7'b1111001;
        4'd2: DISPLAY=7'b0100100;
        4'd3: DISPLAY=7'b0110000;
        4'd4: DISPLAY=7'b0011001;
        4'd5: DISPLAY=7'b0010010;
        4'd6: DISPLAY=7'b0000010;
        4'd7: DISPLAY=7'b1111000;
        4'd8: DISPLAY=7'b0000000;
        4'd9: DISPLAY=7'b0010000;
        default DISPLAY=7'b1111111;
        endcase
    end

endmodule