module debounce(pb_debounced, pb ,clk);
    output pb_debounced;
    input pb;
    input clk;
    
    reg [10:0] shift_reg;
    always @(posedge clk) begin
        shift_reg[10:1] <= shift_reg[9:0];
        shift_reg[0] <= pb;
    end
    
    assign pb_debounced = shift_reg == 11'b111_1111_1111 ? 1'b1 : 1'b0;
endmodule