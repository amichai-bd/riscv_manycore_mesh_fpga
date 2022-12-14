
`include "macros.sv"

module mini_top
import mini_core_pkg::*;
(
                input  logic        Clock  ,
                input  logic        Rst    ,
                //============================================
                //      fabric interface
                //============================================
                input  logic        F2C_ReqValidQ503H     ,
                input  t_fab_op     F2C_ReqOpcodeQ503H    ,
                input  logic [31:0] F2C_ReqAddressQ503H   ,
                input  logic [31:0] F2C_ReqDataQ503H      ,
                output logic        F2C_RspValidQ504H     , 
                output logic [31:0] F2C_RspDataQ504H 
);

logic [31:0] PcQ100H;             // To I_MEM
logic [31:0] PreInstructionQ101H; // From I_MEM
logic [31:0] DMemWrDataQ103H;     // To D_MEM
logic [31:0] DMemAddressQ103H;    // To D_MEM
logic [3:0]  DMemByteEnQ103H;     // To D_MEM
logic        DMemWrEnQ103H;       // To D_MEM
logic [31:0] DMemRdRspQ104H;      // From D_MEM


mini_core mini_core (
   .Clock               ( Clock              ), // input  logic        Clock,
   .Rst                 ( Rst                ), // input  logic        Rst,
   // Instruction Memory
   .PcQ100H             ( PcQ100H            ), // output logic [31:0] PcQ100H,             // To I_MEM
   .PreInstructionQ101H ( PreInstructionQ101H), // input  logic [31:0] PreInstructionQ101H, // From I_MEM
   // Data Memory
   .DMemWrDataQ103H     ( DMemWrDataQ103H    ), // output logic [31:0] DMemWrDataQ103H,     // To D_MEM
   .DMemAddressQ103H    ( DMemAddressQ103H   ), // output logic [31:0] DMemAddressQ103H,    // To D_MEM
   .DMemByteEnQ103H     ( DMemByteEnQ103H    ), // output logic [3:0]  DMemByteEnQ103H,     // To D_MEM
   .DMemWrEnQ103H       ( DMemWrEnQ103H      ), // output logic        DMemWrEnQ103H,       // To D_MEM
   .DMemRdRspQ104H      ( DMemRdRspQ104H     )  // input  logic [31:0] DMemRdRspQ104H       // From D_MEM
);

//---------------------------------------------------
mini_mem_wrap mini_mem_wrap(
 .Clock                 (Clock)  ,               // input  logic        Clock  ,
 .Rst                   (Rst)    ,               // input  logic        Rst    ,
// //============================================
// //      core interface
// //============================================
// i_mem
 .PcQ100H               (PcQ100H),             //input  logic [31:0] PcQ100H,        //curr_pc    ,
 .PreInstructionQ101H   (PreInstructionQ101H), //output logic [31:0] PreInstructionQ101H, //instruction,
// d_mem
 .DMemWrDataQ103H       (DMemWrDataQ103H),     // input  logic [31:0] DMemWrDataQ103H,     // To D_MEM
 .DMemAddressQ103H      (DMemAddressQ103H),    // input  logic [31:0] DMemAddressQ103H,    // To D_MEM
 .DMemByteEnQ103H       (DMemByteEnQ103H),     // input  logic [3:0]  DMemByteEnQ103H,     // To D_MEM
 .DMemWrEnQ103H         (DMemWrEnQ103H),       // input  logic        DMemWrEnQ103H,       // To D_MEM
 .DMemRdRspQ104H        (DMemRdRspQ104H),      // output logic [31:0] DMemRdRspQ104H       // From D_MEM
// //============================================
// //      fabric interface
// //============================================
 .F2C_ReqValidQ503H     (F2C_ReqValidQ503H),   // input  logic        F2C_ReqValidQ503H     ,
 .F2C_ReqOpcodeQ503H    (F2C_ReqOpcodeQ503H),  // input  t_opcode     F2C_ReqOpcodeQ503H    ,
 .F2C_ReqAddressQ503H   (F2C_ReqAddressQ503H), // input  logic [31:0] F2C_ReqAddressQ503H   ,
 .F2C_ReqDataQ503H      (F2C_ReqDataQ503H),    // input  logic [31:0] F2C_ReqDataQ503H      ,
 .F2C_RspValidQ504H     (F2C_RspValidQ504H),   // output logic        F2C_RspValidQ504H     , 
 .F2C_RspDataQ504H      (F2C_RspDataQ504H)     // output logic [31:0] F2C_RspDataQ504H 
);


endmodule