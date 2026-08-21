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
// RISC-V specific DAG Nodes.
//===----------------------------------------------------------------------===//

// Target-dependent type requirements.
def SDT_RISCVYPERMC : SDTypeProfile<1, 2, [
  SDTCisPtrTy<0>, SDTCisSameAs<0, 1>, SDTCisInt<2>
]>;

// Target-dependent nodes.
def riscv_ypermc : SDNode<"RISCVISD::YPERMC", SDT_RISCVYPERMC>;

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

let mayLoad = 1 in {
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
} // mayLoad = 1

let mayLoad = 1, mayStore = 1 in {
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
} // mayLoad = 1, mayStore = 1
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

//===----------------------------------------------------------------------===//
// Pseudo-instructions and codegen patterns
//===----------------------------------------------------------------------===//

let Predicates = [HasStdExtY, IsCapMode] in {
def : Pat<(riscv_load_tgot YGPR:$base, (XLenVT 0)),
          (CLY YGPR:$base, 0)>;
def : Pat<(riscv_load_tgot YGPR:$base, tglobaltlsaddr:$lo),
          (CLY YGPR:$base, tglobaltlsaddr:$lo)>;
}

class PatYgpr<SDPatternOperator OpNode, RVInst Inst, ValueType RetVt=XLenVT>
    : Pat<(RetVt (OpNode YGPR:$rs1)), (Inst YGPR:$rs1)>;

class PatYgprYgpr<SDPatternOperator OpNode, RVInst Inst, ValueType RetVt=CLenVT>
    : Pat<(RetVt (OpNode YGPR:$rs1, YGPR:$rs2)), (Inst YGPR:$rs1, YGPR:$rs2)>;

class PatYgprGpr<SDPatternOperator OpNode, RVInst Inst>
    : Pat<(OpNode YGPR:$rs1, (XLenVT GPR:$rs2)), (Inst YGPR:$rs1, GPR:$rs2)>;

class PatYgprSimm12<SDPatternOperator OpNode, RVInstI Inst>
    : Pat<(OpNode YGPR:$rs1, simm12:$imm12), (Inst YGPR:$rs1, simm12:$imm12)>;

class PatYgprUimm12<SDPatternOperator OpNode, RVInstI Inst>
    : Pat<(OpNode YGPR:$rs1, uimm12:$imm12), (Inst YGPR:$rs1, uimm12:$imm12)>;

class PatGprYgpr<SDPatternOperator OpNode, RVInst Inst>
    : Pat<(OpNode GPR:$rs1, YGPR:$rs2), (Inst GPR:$rs1, YGPR:$rs2)>;

let Predicates = [HasStdExtY] in {
//
// Instructions to Update The Capability Pointer
//
def : PatYgprGpr<cptradd, YADD>;
def : PatYgprSimm12<cptradd, YADDI>;
def : Pat<(CapFrameAddrRegImm YGPR:$rs1, simm12:$imm12),
          (YADDI YGPR:$rs1, simm12:$imm12)>;
def : Pat<(inttoptr (XLenVT GPR:$rs2)), (YADDI C0, GPR:$rs2)>;
def : Pat<(inttoptr simm12:$imm12), (YADDI C0, simm12:$imm12)>;
// TODO: Copied from Zcheripurecap, should be DAG-to-DAG or similar
def : Pat<(XLenVT (int_cheri_cap_offset_get YGPR:$cs1)),
          (SUB (XLenVT (EXTRACT_SUBREG YGPR:$cs1, sub_cap_addr)),
               (YBASER YGPR:$cs1))>;
def : Pat<(int_cheri_cap_offset_set YGPR:$cs1, (XLenVT GPR:$rs2)),
          (CADD (YADDRW YGPR:$cs1, (YBASER YGPR:$cs1)), GPR:$rs2)>;
def : PatYgprGpr<int_cheri_cap_address_set, YADDRW>;

//
// Instructions to Manipulate Capabilities
//
def : PatYgprGpr<riscv_ypermc, YPERMC>;
def : PatYgprGpr<int_cheri_cap_high_set, PACKY>;
def : PatYgprGpr<int_cheri_cap_bounds_set_exact, YBNDSW>;
def : Pat<(int_cheri_cap_bounds_set_exact YGPR:$rs1, ybndsw_imm:$imm),
          (YBNDSWI YGPR:$rs1, ybndsw_imm:$imm)>;
def : Pat<(int_cheri_bounded_stack_cap YGPR:$rs1, ybndsw_imm:$imm),
          (YBNDSWI YGPR:$rs1, ybndsw_imm:$imm)>;
def : Pat<(int_cheri_bounded_stack_cap_dynamic YGPR:$rs1, ybndsw_imm:$imm),
          (YBNDSWI YGPR:$rs1, ybndsw_imm:$imm)>;
def : PatYgprGpr<int_cheri_cap_bounds_set, YBNDSRW>;
def : PatYgprGpr<int_cheri_bounded_stack_cap, YBNDSW>;
def : PatYgprGpr<int_cheri_bounded_stack_cap_dynamic, YBNDSW>;
def : PatYgprYgpr<int_cheri_cap_build, YBLD>;
def : PatYgpr<int_cheri_cap_seal_entry, YSENTRY, CLenVT>;

//
// Instructions to Decode Capability Bounds
//
def : PatYgpr<int_cheri_cap_base_get, YBASER>;
def : PatYgpr<int_cheri_cap_length_get, YLENR>;
// TODO: Add an int_cheri_cap_top_get for YTOPR

//
// Instructions to Extract Capability Fields
//
def : PatYgpr<riscv_cap_tag_get, YTAGR>;
def : PatYgpr<int_cheri_cap_perms_get, YPERMR>;
def : PatYgpr<int_cheri_cap_type_get, YTYPER>;
// TODO: Copied from Zcheripurecap, not valid for Zyseal, should legalise
// in DAG-to-DAG or similar as != 0.
def : PatYgpr<riscv_cap_sealed_get, YTYPER>;
let Predicates = [HasStdExtY, IsRV64] in
def : Pat<(int_cheri_cap_high_get YGPR:$rs1), (i64 (SRLIY YGPR:$rs1, 64))>;
let Predicates = [HasStdExtY, IsRV32] in
def : Pat<(int_cheri_cap_high_get YGPR:$rs1), (i32 (SRLIY YGPR:$rs1, 32))>;

//
// Miscellaneous Instructions to Handle Capability Data
//
def : PatYgprYgpr<riscv_cap_equal_exact, YEQ, XLenVT>;
def : PatYgprYgpr<riscv_cap_subset_test, YSS, XLenVT>;
// TODO: Copied from Zcheripurecap, should be DAG-to-DAG or similar
def : Pat<(XLenVT (int_cheri_round_representable_length (XLenVT GPR:$rs1))),
          (AND (ADD GPR:$rs1, (XORI (YAMASK GPR:$rs1), -1)), (YAMASK GPR:$rs1))>;
def : PatGpr<int_cheri_representable_alignment_mask, YAMASK>;

//
// Instructions to Load/Store Capabilities
//
let Predicates = [HasStdExtY, NotCapMode] in {
def  : LdPat<load, LY, CLenVT>;
def  : StPat<store, SY, GPCR, CLenVT>;
def  : LdPat<atomic_load_cap, LY, CLenVT>;
def  : StPat<atomic_store_cap, SY, GPCR, CLenVT>;
}
let Predicates = [HasStdExtY, IsCapMode] in {
defm : CheriLdPat<load, CLY, CLenVT>;
defm : CheriStPat<store, CSY, GPCR, CLenVT>;
defm : CheriLdPat<atomic_load_cap, CLY, CLenVT>;
defm : CheriStPat<atomic_store_cap, CSY, GPCR, CLenVT>;
}
} // Predicates = [HasStdExtY]

//
// 'Zyhybrid' extension
//
let Predicates = [HasStdExtZyhybrid] in {
def : PatYgpr<int_cheri_cap_flags_get, YMODER>;
def : PatYgprGpr<int_cheri_cap_flags_set, YMODEW>;
} // Predicates = [HasStdExtZyhybrid]

//
// 'Y' + 'A' extension
//
let Predicates = [HasStdExtY, HasStdExtA, NotCapMode] in
defm : AMOCapPat<"", "atomic_swap_cap", "AMOSWAP_Y">;
let Predicates = [HasStdExtY, HasStdExtA, IsCapMode] in
defm : CheriAMOCapPat<"","atomic_swap_cap", "CAMOSWAP_Y">;
