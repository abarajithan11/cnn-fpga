`timescale 1ns/1ps
module huffman_decoder_tb;
parameter IN_WORD_WIDTH          = 5;
parameter OUT_WORD_WIDTH         = 4;
logic clk, rstn;
logic s_valid, s_ready, m_valid, m_ready;
logic [IN_WORD_WIDTH-1:0]  s_data;
logic [OUT_WORD_WIDTH-1:0] m_data;

huffman_decoder decoder_i(.*);

forever begin
    clk = 1;
    #1;
    clk=0;
    #1;
end

initial begin
    rstn=0;
    #5;
    repeat(5) begin
        roun
    end
end


endmodule