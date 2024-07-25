`define K_BITS 4 // TODO:for testing only, remove after
module huffman_decoder #(
    parameter IN_WORD_WIDTH          = `K_BITS + 1 ,
    parameter OUT_WORD_WIDTH         = `K_BITS     ,
    parameter BITS_SHIFT_CNTR        = $clog2(3*IN_WORD_WIDTH)
)
(
    input logic clk, resetn;

    input  logic [IN_WORD_WIDTH-1:0] s_data;
    input  logic s_valid;
    output logic  s_ready;

    input m_ready;
    output [OUT_WORD_WIDTH-1:0] m_data;
    output m_valid;
);

logic [3*IN_WORD_WIDTH-1:0] buffer;
logic [BITS_SHIFT_CNTR-1:0] shift_counter;

wire in_handshake, out_handshake;

assign m_data = buffer[0] ? buffer[OUT_WORD_WIDTH:1] : '0 ;
assign m_valid = (shift_counter > 0) ? 1'b1 : 1'b0;
assign s_ready = (shift_counter <= 2*IN_WORD_WIDTH) ? 1'b1 : 1'b0;

assign in_handshake = s_valid & s_ready;
assign out_handshake = m_valid & m_data;

// Shift Counter Update - keeps track of how many positions in the buffer are filled.
always@(posedge clk `OR_NEGEDGE(resetn)) begin
    if(~resetn) begin
        shift_counter <= 0;
    end
    else begin
        if(in_handshake) begin
            if (out_handshake) begin // in and out handshakes
                if(buffer[0]) shift_counter <= shift_counter; // one word shifted out, one word shifted in.
                else shift_counter <= shift_counter + IN_WORD_WIDTH - 1; // one bit shifted out, one word shifted in  
            end
            else begin // only in handshake
                shift_counter <= shift_counter + IN_WORD_WIDTH;
            end
        end
        else if (out_handshake) begin // in and out handshakes
            if(buffer[0]) shift_counter <= shift_counter - IN_WORD_WIDTH; // one word shifted out, one word shifted in.
            else shift_counter <= shift_counter + IN_WORD_WIDTH - 1; // one bit shifted out, one word shifted in  
        end
    end
end

// BUffer Write/Shift
genvar i;
generate
    for (i=0; i < 3*IN_WORD_WIDTH; i++) begin
        always@(posedge clk `OR_NEGEDGE(resetn)) begin
            if (~resetn) begin
                buffer[i] <= 0;
            end
            else begin
                if(out_handshake) begin
                    if(in_handshake) begin
                        if(buffer[0]) begin
                            if(i>= shift_counter-IN_WORD_WIDTH && i < shift_counter) buffer[i] <= s_data[i-shift_counter-IN_WORD_WIDTH];
                            else if(i < 2*IN_WORD_WIDTH) buffer[i] <= buffer[i+IN_WORD_WIDTH]; // shift by 1 word
                        end
                        else begin
                            if(i>= shift_counter-1&& i < shift_counter+IN_WORD_WIDTH-1) buffer[i] <= s_data[i-shift_counter-1];
                            else if(i < 3*IN_WORD_WIDTH-1) buffer[i] <= buffer[i+1]; // shift by 1 bit
                        end
                    end
                    else begin
                        if(buffer[0]) begin 
                            if(i < 2*IN_WORD_WIDTH) buffer[i] <= buffer[i+IN_WORD_WIDTH]; // shift by 1 word
                        end
                        else if (i<3*IN_WORD_WIDTH-1) buffer[i] <= buffer[i+1]; // shift by 1 bit
                    end
                end
                else begin
                    if(in_handshake) begin
                        if(i>= shift_counter && i < shift_counter + IN_WORD_WIDTH) buffer[i] <= s_data[i-shift_counter];
                    end
                end
            end
        end
    end
endgenerate

// always@(posedge clk `OR_NEGEDGE(resetn)) begin
//     if(~resetn) begin
//         buffer <= 0;
//     end
//     else begin
//         if (m_valid && m_ready) begin
//             if(buffer[0]) begin
//                 buffer <= buffer << IN_WORD_WIDTH;
//                 // TODO : cntr decrement
//                 //shift_counter <= shift_counter - IN_WORD_WIDTH;
//             end
//             else begin
//                 buffer <= buffer << 1;
//                 //shift_counter <= shift_counter - 1;
//             end
//         end
//     end
// end

endmodule