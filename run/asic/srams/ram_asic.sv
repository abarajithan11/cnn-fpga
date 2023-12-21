`timescale 1ns/1ps
`include "../../../deepsocflow/rtl/defines.svh"
`include "sram_weights/sram_weights.v"
`include "sram_edges/sram_edges.v"
//`include "sram_output/sram_output.v"

module ram_weights #(
  parameter   DEPTH   = `RAM_WEIGHTS_DEPTH,
              WIDTH   = `COLS * `K_BITS,
              NUM_SRAMS = `COLS,
              SRAM_WIDTH = `K_BITS,
              CHAIN = `K_BITS-1
)(
  input  logic clka ,
  input  logic ena  ,
  input  logic wea  ,
  input  logic [$clog2(DEPTH)-1:0] addra,
  input  logic [WIDTH        -1:0] dina ,
  output logic [WIDTH        -1:0] douta
);

  genvar i;
  for (i=0; i<`COLS; i=i+1) begin
    sram_weights RAM (
      .Q(douta[SRAM_WIDTH*i + CHAIN : SRAM_WIDTH*i]),
      .CLK(clka),
      .CEN(ena),
      .WEN(wea),
      .A(addra),
      .D(dina[SRAM_WIDTH*i + CHAIN : SRAM_WIDTH*i]),
      .EMA(3'b010),
      .EMAW(2'b00),
      .RET1N(1'b0)
    );
  end
  

endmodule

module ram_edges #(
  parameter   DEPTH   = `RAM_EDGES_DEPTH,
              WIDTH   = `X_BITS * (`KH_MAX/2)
)(
  input  logic clka ,
  input  logic ena  ,
  input  logic wea  ,
  input  logic [$clog2(DEPTH)-1:0] addra,
  input  logic [WIDTH        -1:0] dina ,
  output logic [WIDTH        -1:0] douta
);

    sram_edges RAM (
      .Q(douta),
      .CLK(clka),
      .CEN(ena),
      .WEN(wea),
      .A(addra),
      .D(dina),
      .EMA(3'b010),
      .EMAW(2'b00),
      .RET1N(1'b0)
    );

endmodule

/*
module ram_output #(
  parameter   DEPTH    = `COLS * `ROWS,
              WIDTH    = `Y_BITS
)(
  input  logic clka ,
  input  logic ena  ,
  input  logic wea  ,
  input  logic [$clog2(DEPTH)-1:0] addra,
  input  logic [WIDTH        -1:0] dina ,
  output logic [WIDTH        -1:0] douta
);

    sram_output RAM (
      .Q(douta),
      .CLK(clka),
      .CEN(ena),
      .WEN(wea),
      .A(addra),
      .D(dina),
      .EMA(3'b010),
      .EMAW(2'b00),
      .RET1N(1'b0)
    );

endmodule*/