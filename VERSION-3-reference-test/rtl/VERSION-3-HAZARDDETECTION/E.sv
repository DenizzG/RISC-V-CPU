module E(
    //INPUTS
    input logic [1:0]     JumpE_i,
    input logic           BranchE_i,
    input logic [2:0]     ALUControlE_i,
    input logic           ALUSrcE_i,

    input logic [31:0]    RD1E_i,
    input logic [31:0]    RD2E_i,
    input logic [31:0]    PCE_i,
    input logic [31:0]    ImmExtE_i,

    //FORWARDING
    input logic [31:0]    ALUResultM_i_me,
    input logic [31:0]    ResultW_i_we,
    input logic [1:0]     ForwardAE,
    input logic [1:0]     ForwardBE,

    //OUTPUTS
    output logic [31:0]   PCTargetE_o,
    output logic [31:0]   WriteDataE_o,
    output logic [31:0]   ALUResultE_o,

    output logic [1:0]    PCSrcE_o

);
//=======================================
//          WIRE

logic   [1: 0] ZeroE;
logic   [31:0] SrcBE;
logic   [31:0] SrcAE;
logic   [31:0] ForwardBE_mux;

always_comb begin
    PCTargetE_o = PCE_i + ImmExtE_i;
    WriteDataE_o = ForwardBE_mux;
end
//FORWARDING
always_comb begin //mux
    case(ForwardAE)
    2'b00 : SrcAE = RD1E_i;
    2'b01 : SrcAE = ResultW_i_we;
    2'b10 : SrcAE = ALUResultM_i_me;
    default : SrcAE = RD1E_i;
    endcase
end

always_comb begin //mux
    case(ForwardBE)
    2'b00 : ForwardBE_mux = RD2E_i;
    2'b01 : ForwardBE_mux = ResultW_i_we;
    2'b10 : ForwardBE_mux = ALUResultM_i_me;
    default : ForwardBE_mux = RD2E_i;
    endcase
end
always_comb begin
    SrcBE = (ALUSrcE_i) ? ImmExtE_i : ForwardBE_mux;
end

//ENDFORWARDING

// PCSrcE case statements
always_comb begin
    case(JumpE_i)
        2'b00 : begin // BLT, BGE
            case(BranchE_i)
                1'b1 : begin
                    case(ZeroE)
                        2'b00   : PCSrcE_o = 2'b01;     // branch
                        2'b01   : PCSrcE_o = 2'b01;     // branch
                        2'b10   : PCSrcE_o = 2'b01;     // branch
                        default : PCSrcE_o = 2'b00;     // otherwise, no branch
                    endcase
                end
                default : PCSrcE_o = 2'b00;             
            endcase 
        end 

        2'b01 : begin // BNE, JAL
            case(BranchE_i)
                1'b0 : PCSrcE_o = 2'b01; // JAL          // jump (JTA)

                1'b1 : begin // BNE
                    case(ZeroE)
                        2'b01   : PCSrcE_o = 2'b00;      // no branch
                        default : PCSrcE_o = 2'b01;      // otherwise, branch
                    endcase
                end
                default : PCSrcE_o = 2'b00;
            endcase
        end

        2'b10 : begin // JALR
            case(BranchE_i)
                1'b0 : PCSrcE_o = 2'b10;                 // jump (rsl + SignExt(imm)) 

                default : PCSrcE_o = 2'b00;             
            endcase
        end

        2'b11 : begin // BEQ
            case(BranchE_i)
                1'b1 : begin
                    case(ZeroE)
                        2'b01   : PCSrcE_o = 2'b01;      // branch
                        default : PCSrcE_o = 2'b00;      // otherwise, no branch
                    endcase
                end
                default : PCSrcE_o = 2'b00;
            endcase
        end

        default : PCSrcE_o = 2'b0;
    endcase
end

ALU ALU(
    //INPUTS
    .SrcAE(SrcAE),
    .SrcBE(SrcBE),
    .ALUControlE(ALUControlE_i),

    //OUTPUTS
    .ALUResultE(ALUResultE_o),
    .ZeroE(ZeroE)
);

endmodule
