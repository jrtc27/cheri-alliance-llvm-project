//===-- RISCVInstrInfoY.td - RISCV instructions -------------*- tblgen-*---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the RISC-V instructions from the standard 'Base Y'
// instruction set.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Operand definitions.
//===----------------------------------------------------------------------===//

def YGPRNoX0ZeroOffsetMemOpOperand : AsmOperandClass {
  let Name = "YGPRNoX0ZeroOffsetMemOpOperand";
  let RenderMethod = "addRegOperands";
  let PredicateMethod = "isYGPRNoX0";
  let ParserMethod = "parseZeroOffsetMemOp";
  let DiagnosticType = "InvalidYGPRNoX0";
}

def YGPRNoX0MemZeroOffset : MemOperand<GPCRNoC0> {
  let ParserMatchClass = YGPRNoX0ZeroOffsetMemOpOperand;
  let PrintMethod = "printZeroOffsetMemOp";
}

def YGPRNoX0Mem : MemOperand<GPCRNoC0> {
  let ParserMatchClass = YGPRNoX0Operand;
}

def YBNDSWImmOperand : AsmOperandClass {
  let Name = "YBNDSWImm";
  let RenderMethod = "addImmOperands";
  let DiagnosticType = "InvalidYBNDSWImm";
}

def ybndsw_imm : RISCVOp<XLenVT>, ImmLeaf<XLenVT, [{
  return llvm::RISCV::isValidYBNDSWImm(Imm);
}]> {
  let EncoderMethod = "getYBNDSWImmOpValue";
  let ParserMatchClass = YBNDSWImmOperand;
  let DecoderMethod = "DecodeYBNDSWImm";
  let OperandType = "OPERAND_UIMM9_YBNDSWI";
}

def uimm7_eq_xlen : RISCVUImmOp<7>, ImmLeaf<XLenVT, [{
  return Imm == Subtarget->getXLen();
}]> {
  let ParserMatchClass = UImmAsmOperand<7, "EqXLen">;
  let DecoderMethod = "decodeUImm7EqXLenOperand";
  let MCOperandPredicate = [{
    int64_t Imm;
    if (!MCOp.evaluateAsConstantImm(Imm))
      return false;
    return Imm == Subtarget->getXLen()
  }];
  let OperandType = "OPERAND_UIMM7_EQ_XLEN";
}

//===----------------------------------------------------------------------===//
// Instruction Formats and class templates
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
// All regular 3-operand RVY instructions use opc=CUSTOM-3/RVY-A with funct3=0
defvar OPC_RVY_A = OPC_CUSTOM_3;
class RVY_rr<bits<7> funct7, string opcodestr, DAGOperand rdOp,
             DAGOperand rs1Op, DAGOperand rs2Op>
    : RVInstR<funct7, 0b000, OPC_RVY_A, (outs rdOp:$rd),
              (ins rs1Op:$rs1, rs2Op:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Like RVY_rr, except rs1=0
class RVY_0r<bits<7> funct7, string opcodestr, DAGOperand rdOp,
             DAGOperand rs2Op>
    : RVInstR<funct7, 0b000, OPC_RVY_A, (outs rdOp:$rd),
              (ins rs2Op:$rs2), opcodestr, "$rd, $rs2"> {
  let rs1 = 0;
}

// Like RVY_rr, except rs2 is now an additional function code.
class RVYInst2Op<bits<7> funct7, bits<5> funct5, DAGOperand rdOp,
                 DAGOperand rs1Op, string opcodestr, string argstr>
    : RVInst<(outs rdOp:$rd), (ins rs1Op:$rs1), opcodestr, argstr, [],
             InstFormatR> {
  bits<5> rs1;
  bits<5> rd;

  let Inst{31-25} = funct7;
  let Inst{24-20} = funct5;
  let Inst{19-15} = rs1;
  let Inst{14-12} = 0b000; // funct3
  let Inst{11-7} = rd;
  let Inst{6-0} = OPC_RVY_A.Value;
}

class RVY_r_xx<bits<5> funct5, string opcodestr>
    : RVYInst2Op<0b1111000, funct5, GPR, GPR, opcodestr, "$rd, $rs1">;
class RVY_r_xy<bits<5> funct5, string opcodestr>
    : RVYInst2Op<0b1111010, funct5, GPR, YGPR, opcodestr, "$rd, $rs1">;
class RVY_ri<bits<3> funct3, string opcodestr, DAGOperand rdOp = YGPR,
             DAGOperand rs1Op = YGPR>
    : RVInstI<funct3, OPC_RVY_A, (outs rdOp:$rd),
              (ins rs1Op:$rs1, simm12:$imm12), opcodestr,
              "$rd, $rs1, $imm12">;
class RVY_bndswi<string opcodestr>
   : RVInstIBase<0b101, OPC_RVY_A, (outs YGPR:$rd),
                 (ins YGPR:$rs1, ybndsw_imm:$imm), opcodestr,
                 "$rd, $rs1, $imm"> {
  bits<5> rd;
  bits<5> rs1;
  bits<9> imm;

  let Inst{31-29} = 0b111;
  let Inst{28-20} = imm;
}
class RVY_srli<string opcodestr>
    : RVInstIBase<0b101, OPC_RVY_A, (outs GPR:$rd),
                  (ins YGPR:$rs1, uimm7_eq_xlen:$shamt), opcodestr,
                  "$rd, $rs1, $shamt"> {
  bits<7> shamt;

  let Inst{31-27} = 0b00000;
  let Inst{26-20} = shamt;
}

let mayLoad = 1 in
class RVY_load<bits<3> funct3, string opcodestr, DAGOperand rs1Op>
    : RVInstI<funct3, OPC_RVY_A, (outs YGPR:$rd),
              (ins rs1Op:$rs1, simm12:$imm12),
              opcodestr, "$rd, ${imm12}(${rs1})">;

let mayStore = 1 in
class RVY_store<bits<3> funct3, string opcodestr, DAGOperand rs1Op>
    : RVInstS<funct3, OPC_RVY_A, (outs),
              (ins YGPR:$rs2, rs1Op:$rs1, simm12:$imm12),
              opcodestr, "$rs2, ${imm12}(${rs1})">;

class RVY_ymodesw<bits<5> funct5, string opcodestr>
    : RVInstR<0b0101011, 0b000, OPC_RVY_A, (outs), (ins), opcodestr, ""> {
  let rs2 = funct5;
  let rs1 = 0;
  let rd = 0;
}

let mayLoad = 1 in
class LR_Y_r<bits<5> funct5, bit aq, bit rl, string opcodestr,
             DAGOperand rs1Op>
    : RVInstRAtomic<funct5, aq, rl, 0b011, OPC_RVY_A,
                    (outs YGPR:$rd), (ins rs1Op:$rs1),
                    opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

multiclass LR_Y_r_aq_rl<bits<5> funct5, string opcodestr,
                        DAGOperand rs1Op> {
  def ""     : LR_Y_r<funct5, 0, 0, opcodestr, rs1Op>;
  def _AQ    : LR_Y_r<funct5, 1, 0, opcodestr # ".aq", rs1Op>;
  def _RL    : LR_Y_r<funct5, 0, 1, opcodestr # ".rl", rs1Op>;
  def _AQ_RL : LR_Y_r<funct5, 1, 1, opcodestr # ".aqrl", rs1Op>;
}

let mayLoad = 1, mayStore = 1 in
class AMO_Y_rr<bits<5> funct5, bit aq, bit rl, string opcodestr,
               DAGOperand rdOp, DAGOperand rs1Op>
    : RVInstRAtomic<funct5, aq, rl, 0b011, OPC_RVY_A,
                    (outs rdOp:$rd), (ins rs1Op:$rs1, YGPR:$rs2),
                    opcodestr, "$rd, $rs2, $rs1">;

multiclass AMO_Y_rr_aq_rl<bits<5> funct5, string opcodestr,
                          DAGOperand rdOp, DAGOperand rs1Op> {
  def ""     : AMO_Y_rr<funct5, 0, 0, opcodestr, rdOp, rs1Op>;
  def _AQ    : AMO_Y_rr<funct5, 1, 0, opcodestr # ".aq", rdOp, rs1Op>;
  def _RL    : AMO_Y_rr<funct5, 0, 1, opcodestr # ".rl", rdOp, rs1Op>;
  def _AQ_RL : AMO_Y_rr<funct5, 1, 1, opcodestr # ".aqrl", rdOp, rs1Op>;
}
} // hasSideEffects = 0, mayLoad = 0, mayStore = 0

let Predicates = [HasStdExtY] in {
//
// Instructions to Update The Capability Pointer
//
let isReMaterializable = true, isAsCheapAsAMove = true in {
def YADD : RVY_rr<0b0000011, "yadd", YGPR, YGPR, GPRNoX0>;
def YADDI : RVY_ri<0b100, "yaddi">;
}
def : InstAlias<"yadd $rd, $rs1, $imm12",
                (YADDI YGPR:$rd, YGPR:$rs1, simm12:$imm12), 0>;
def YADDRW : RVY_rr<0b0001011, "yaddrw", YGPR, YGPR, GPR>;

//
// Instructions to Manipulate Capabilities
//
def YPERMC : RVY_rr<0b0010011, "ypermc", YGPR, YGPR, GPR>;
// YMV is encoded as YADD with rs2=x0
let isReMaterializable = true, isAsCheapAsAMove = true, isMoveReg = true in
def YMV : RVYInst2Op<0b0000011, 0b00000, YGPR, YGPR, "ymv", "$rd, $rs1">;
def PACKY : RVY_rr<0b0000001, "packy", YGPR, YGPR, GPR>;
def : MnemonicAlias<"yhiw", "packy">;
def YBNDSW : RVY_rr<0b0011011, "ybndsw", YGPR, YGPR, GPR>;
def YBNDSWI : RVY_bndswi<"ybndswi">;
def : InstAlias<"ybndsw $rd, $rs1, $imm",
                (YBNDSWI YGPR:$rd, YGPR:$rs1, ybndsw_imm:$imm), 0>;
def YBNDSRW : RVY_rr<0b0100011, "ybndsrw", YGPR, YGPR, GPR>;
def YSUNSEAL : RVY_rr<0b0000111, "ysunseal", YGPR, YGPR, YGPR>;
def YBLD : RVY_rr<0b0001111, "ybld", YGPR, YGPR, YGPR>;
def YSENTRY : RVY_0r<0b0010111, "ysentry", YGPR, YGPR>;

//
// Instructions to Decode Capability Bounds
//
def YBASER : RVY_r_xy<0b00000, "ybaser">;
def YLENR : RVY_r_xy<0b00011, "ylenr">;
def YTOPR : RVY_r_xy<0b00010, "ytopr">;

//
// Instructions to Extract Capability Fields
//
def YTAGR : RVY_r_xy<0b00100, "ytagr">;
def YPERMR : RVY_r_xy<0b00001, "ypermr">;
def YTYPER : RVY_r_xy<0b00101, "ytyper">;
// Extracting the high bits of capabilities is effectively a XLEN-bit right
// shift. It is encoded this way so that a future "YLEN arithmetic" extension
// can define shifts with arbitrary shift amounts. YHIR is a pseudo that expands
// to the XLEN-wide shift value depending on RV32/RV64.
def SRLIY : RVY_srli<"srliy">;
let Predicates = [HasStdExtY, IsRV64] in {
def : InstAlias<"yhir $rd, $rs1", (SRLIY GPR:$rd, YGPR:$rs1, 64)>;
}
let Predicates = [HasStdExtY, IsRV32] in {
def : InstAlias<"yhir $rd, $rs1", (SRLIY GPR:$rd, YGPR:$rs1, 32)>;
}
//
// Miscellaneous Instructions to Handle Capability Data
//
def YEQ : RVY_rr<0b0000110, "yeq", GPR, YGPR, YGPR>;
def YSS : RVY_rr<0b0001110, "yss", GPR, YGPR, YGPR>;
def YAMASK : RVY_r_xx<0b00000, "yamask">;
} // Predicates = [HasStdExtY]

//
// Instructions to Load/Store Capabilities
//
let Predicates = [HasStdExtY, NotCapMode] in {
def LY : RVY_load<0b001, "ly", GPRMem>;
def SY : RVY_store<0b010, "sy", GPRMem>;
}
let Predicates = [HasStdExtY, IsCapMode], DecoderNamespace = "CapModeOnly_" in {
def CLY : RVY_load<0b001, "ly", YGPRNoX0Mem>;
def CSY : RVY_store<0b010, "sy", YGPRNoX0Mem>;
}

//
// 'Zyhybrid' extension
//
let Predicates = [HasStdExtZyhybrid] in {
def YMODER : RVY_r_xy<0b00110, "ymoder">;
def YMODEW : RVY_rr<0b0101011, "ymodew", YGPR, YGPRNoX0, GPR>;
def YMODESWY : RVY_ymodesw<0b00000, "ymodeswy">;
def YMODESWI : RVY_ymodesw<0b00001, "ymodeswi">;
}

//
// 'Y' + 'A' extension
//
let Predicates = [HasStdExtY, HasStdExtA, NotCapMode] in {
defm LR_Y : LR_Y_r_aq_rl<0b00010, "lr.y", GPRMemZeroOffset>;
defm AMOSWAP_Y : AMO_Y_rr_aq_rl<0b00001, "amoswap.y", YGPR, GPRMemZeroOffset>;
defm SC_Y : AMO_Y_rr_aq_rl<0b00011, "sc.y", GPR, GPRMemZeroOffset>;
}
let Predicates = [HasStdExtY, HasStdExtA, IsCapMode], DecoderNamespace = "CapModeOnly_" in {
defm CLR_Y : LR_Y_r_aq_rl<0b00010, "lr.y", YGPRNoX0MemZeroOffset>;
defm CAMOSWAP_Y : AMO_Y_rr_aq_rl<0b00001, "amoswap.y", YGPR, YGPRNoX0MemZeroOffset>;
defm CSC_Y : AMO_Y_rr_aq_rl<0b00011, "sc.y", GPR, YGPRNoX0MemZeroOffset>;
}

// YZba
