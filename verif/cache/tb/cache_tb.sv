`include "macros.sv"

module cache_tb ;

import cache_param_pkg::*;  
logic             clk;
logic             rst;
t_req             core2cache_req;
logic             stall;
t_rd_rsp          cache2core_rsp;
t_fm_wr_req       cache2fm_wr_req_q3;
t_fm_rd_req       cache2fm_rd_req_q3;
t_fm_rd_rsp [9:0] samp_fm2cache_rd_rsp;
t_fm_rd_rsp       fm2cache_rd_rsp;

//==================
//      clk Gen
//==================
initial begin: clock_gen
    forever begin
        #5 clk = 1'b0;
        #5 clk = 1'b1;
    end
end// clock_gen

initial begin : assign_input
$display("================\n     START\n================\n");
            rst= 1'b1;
            core2cache_req     = '0;
delay(80);  rst= 1'b0;
$display("====== Reset Done =======\n");
delay(20);  $display("-----------First Write Request ----------");
delay(2);   wr_req(20'h11_0A_0, 32'hDEAD_BEAF , 5'b0);
delay(20);  $display("-----------Seconde Write Request ----------");
delay(2);   wr_req(20'h11_0B_0, 32'hFAFA_FAFA , 5'b1);
$display("\n\n================\n     Done\n================\n");

delay(80); $finish;
end// initial

`include "cache_trk.vh"

cache cache ( //DUT
   .clk                (clk),            //input   logic
   .rst                (rst),            //input   logic
    //Agent Inteface                      
   .core2cache_req     (core2cache_req), //input   
   .stall              (stall),          //output  logic
   .cache2core_rsp     (cache2core_rsp), //output  t_rd_rsp
    // FM Interface                   
   .cache2fm_wr_req_q3 (cache2fm_wr_req_q3),//output  t_fm_wr_req
   .cache2fm_rd_req_q3 (cache2fm_rd_req_q3),//output  t_fm_rd_req
   .fm2cache_rd_rsp    (fm2cache_rd_rsp)    //input   var t_fm_rd_rsp
);

task delay(input int cycles);
  for(int i =0; i< cycles; i++) begin
    @(posedge clk);
  end
endtask

task wr_req( input logic [19:0]  address, 
             input logic [127:0] data ,
             input logic [4:0]   id );
    while (stall) begin
      delay(1); $display("-> stall! cant send write: %h ", address );
    end
    core2cache_req.valid   =  1'b1;
    core2cache_req.opcode  =  WR_OP;
    core2cache_req.address =  address;
    core2cache_req.data    =  data;
    core2cache_req.reg_id  =  id;
    delay(1); 
    core2cache_req     = '0;
endtask

task rd_req( input logic [19:0] address,
             input logic [4:0] id); 
    while (stall) begin 
    delay(1);  $display("-> stall! cant send read: %h ", address);
    end
    core2cache_req.valid   =  1'b1;
    core2cache_req.opcode  =  RD_OP;
    core2cache_req.address =  address;
    core2cache_req.reg_id =  id;
    delay(1);
    core2cache_req     = '0;
endtask

//============================
//          Far Memory ARRAY
//============================
array  #(
    .WORD_WIDTH     (CL_WIDTH),
    .ADRS_WIDTH     (SET_ADRS_WIDTH + TAG_WIDTH)
) far_memory_array (
    .clk            (clk),                                     //input
    .rst            (rst),                                     //input
    //write interface
    .wr_en          (cache2fm_wr_req_q3.valid),                   //input
    .wr_address     (cache2fm_wr_req_q3.address[MSB_TAG:LSB_SET]),//input
    .wr_data        (cache2fm_wr_req_q3.data),                    //input
    //read interface
    .rd_address     (cache2fm_rd_req_q3.address[MSB_TAG:LSB_SET]),//input
    .q              (samp_fm2cache_rd_rsp[0].data)                //output
);

// One Cycle Latency on memory read - sample the id & Valid.
`RVC_DFF(samp_fm2cache_rd_rsp[0].tq_id   ,cache2fm_rd_req_q3.tq_id     , clk)
`RVC_DFF(samp_fm2cache_rd_rsp[0].valid   ,cache2fm_rd_req_q3.valid     , clk)
// Shift register to add 10 cycle latecy on FM read.
`RVC_DFF(samp_fm2cache_rd_rsp[9:1]       ,samp_fm2cache_rd_rsp[8:0] , clk)
`RVC_DFF(fm2cache_rd_rsp                 ,samp_fm2cache_rd_rsp[9]   , clk)




endmodule // test_tb
