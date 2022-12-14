//-----------------------------------------------------------------------------
// Title            : 
// Project          : 
//-----------------------------------------------------------------------------
// File             : <TODO>
// Original Author  : 
// Code Owner       : 
// Created          : 
//-----------------------------------------------------------------------------
// Description : 
//
//
//-----------------------------------------------------------------------------
`include "macros.sv"

module cache_pipe
    import cache_param_pkg::*;  
(
    input   logic            clk,
    input   logic            rst,
    //tq interface 
    input   var t_lu_req     pipe_lu_req_q1,
    output  t_lu_rsp         pipe_lu_rsp_q3,
    // FM interface Reqiuets 
    output  t_fm_wr_req      cache2fm_wr_req_q3,
    output  t_fm_rd_req      cache2fm_rd_req_q3,
    //tag_array interface 
    output  t_set_rd_req     rd_set_req_q1,
    input   var t_set_rd_rsp pre_rd_data_set_rsp_q2,
    output  t_set_wr_req     wr_data_set_q2,
    //data_array interface 
    output  t_cl_rd_req      rd_cl_req_q2,
    input   var t_cl_rd_rsp  rd_data_cl_rsp_q3,
    output  t_cl_wr_req      wr_data_cl_q3
);

    assign pipe_lu_rsp_q3     = '0;
    //assign cache2fm_wr_req_q3 = '0;
    //assign cache2fm_rd_req_q3 = '0;
    assign wr_data_set_q2     = '0;
    //assign rd_cl_req_q2       = '0;

//==============================================
// FIXME Not functinal -  just to test the FM tracker
//==============================================
t_lu_req     pipe_lu_req_q2;
t_lu_req     pipe_lu_req_q3;
`RVC_DFF(pipe_lu_req_q2 ,pipe_lu_req_q1 , clk)
`RVC_DFF(pipe_lu_req_q3 ,pipe_lu_req_q2 , clk)
//
//assign cache2fm_wr_req_q3.valid    = pipe_lu_req_q3.valid && (pipe_lu_req_q3.lu_op == WR_LU);
//assign cache2fm_wr_req_q3.address  = pipe_lu_req_q3.address;
//assign cache2fm_wr_req_q3.data     = pipe_lu_req_q3.cl_data;
//
//assign cache2fm_rd_req_q3.valid    = pipe_lu_req_q3.valid && (pipe_lu_req_q3.lu_op == RD_LU);
//assign cache2fm_rd_req_q3.address  = pipe_lu_req_q3.address;
//assign cache2fm_rd_req_q3.tq_id    = pipe_lu_req_q3.tq_id;

//==================================================================
//       ____    _                     ___    _ 
//      |  _ \  (_)  _ __     ___     / _ \  / |
//      | |_) | | | | '_ \   / _ \   | | | | | |
//      |  __/  | | | |_) | |  __/   | |_| | | |
//      |_|     |_| | .__/   \___|    \__\_\ |_|
//                  |_|                         
//==================================================================
//      assign signals to the PIPE BUS 
//      Hold the pipe transaction indications & Data
//      assign the signals to the tag array lookup request
//=================================================================
//======================
//  assign PIPE BUS
//======================

//======================
//  SET_LOOKUP / TAG Array Lookup
//======================
    assign rd_set_req_q1.set = pipe_lu_req_q1.address[MSB_SET:LSB_SET];
//==================================================================
//`DFF(pre_pipe_bus_q2, pipe_bus_q1, clk)
//==================================================================
//       ____    _                     ___    ____  
//      |  _ \  (_)  _ __     ___     / _ \  |___ \ 
//      | |_) | | | | '_ \   / _ \   | | | |   __) |
//      |  __/  | | | |_) | |  __/   | |_| |  / __/ 
//      |_|     |_| | .__/   \___|    \__\_\ |_____|
//                  |_|                             
//==================================================================
//  1. Solve hazard - If detect that q2 & q3 use the same set
//  2. TAG compare - find which way hit if any
//  3. incase of fill - choose victim for allocation
//  4. update the tag array. (MRU, tag incase of fill, etc)
//  5. rd request from data array
//==================================================================

//======================
//     Data_Hazard - accessing same set B2B 
//====================== 

//======================
//     TAG_COMPARE 
//====================== 
logic [NUM_WAYS-1:0] way_tag_match_q2;
always_comb begin
    for( int WAY =0; WAY<NUM_WAYS; WAY++) begin
        way_tag_match_q2[WAY] = (pre_rd_data_set_rsp_q2.tags[WAY] == pipe_lu_req_q2.address[MSB_TAG:LSB_TAG])  && 
                              pre_rd_data_set_rsp_q2.valid[WAY] &&
                              pipe_lu_req_q2.valid ;
    end
end
//======================
//    ALOC_VICTIM (incase of miss)
//====================== 

//======================
//    WRITE_SET_UPDATE
//======================


//======================
//    DATA_FETCH
//======================
logic [WAY_WIDTH-1:0] way_tag_enc_match_q2;
logic                 valid_match;
//`ENCODER(way_tag_enc_match_q2 , valid_match, way_tag_match_q2 )
always_comb begin
    unique case (way_tag_match_q2)
        4'b0001 : way_tag_enc_match_q2 = 2'b00;
        4'b0010 : way_tag_enc_match_q2 = 2'b01;
        4'b0100 : way_tag_enc_match_q2 = 2'b10;
        4'b1000 : way_tag_enc_match_q2 = 2'b11;
        default : way_tag_enc_match_q2 = 2'b00;
    endcase
end
assign rd_cl_req_q2.cl_address = {pipe_lu_req_q2.address[MSB_SET:LSB_SET],way_tag_enc_match_q2};
//==================================================================
//`DFF(pipe_bus_q3,        pipe_bus_q2,        clk)
//`DFF(wr_data_set_q3,     wr_data_set_q2,     clk)
//`DFF(cache2fm_rd_req_q3, cache2fm_rd_req_q2, clk)
//==================================================================
//       ____    _                     ___    _____ 
//      |  _ \  (_)  _ __     ___     / _ \  |___ / 
//      | |_) | | | | '_ \   / _ \   | | | |   |_ \ 
//      |  __/  | | | |_) | |  __/   | |_| |  ___) |
//      |_|     |_| | .__/   \___|    \__\_\ |____/ 
//                  |_|                             
//==================================================================
//
//
//==================================================================


//======================
//    TQ_UPDATE -> PIPE_LU_RSP_q3
//======================

//======================
//    DIRTY_EVICT 
//======================

assign cache2fm_wr_req_q3.valid    = pipe_lu_req_q3.valid && (pipe_lu_req_q3.lu_op == WR_LU);
assign cache2fm_wr_req_q3.address  = pipe_lu_req_q3.address;
assign cache2fm_wr_req_q3.data     = pipe_lu_req_q3.cl_data;
//
assign cache2fm_rd_req_q3.valid    = pipe_lu_req_q3.valid && (pipe_lu_req_q3.lu_op == RD_LU);
assign cache2fm_rd_req_q3.address  = pipe_lu_req_q3.address;
assign cache2fm_rd_req_q3.data     = rd_data_cl_rsp_q3.cl_data;
//======================
//    WRITE_DATA
//======================
logic [WAY_WIDTH-1:0] way_tag_enc_match_q3;
`RVC_DFF(way_tag_enc_match_q3, way_tag_enc_match_q2, clk)

always_comb begin
    wr_data_cl_q3            = '0;
    wr_data_cl_q3.data       = pipe_lu_req_q3.cl_data;
    wr_data_cl_q3.cl_address = {pipe_lu_req_q3.address[MSB_SET:LSB_SET],way_tag_enc_match_q3};
    wr_data_cl_q3.valid      = (pipe_lu_req_q3.valid && (pipe_lu_req_q3.lu_op == WR_LU));
    
end




endmodule
