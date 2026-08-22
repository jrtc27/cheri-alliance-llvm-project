//===- RISCVSystemOperandsZCheriPurecap.td -----------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the symbolic operands permitted for various kinds of
// CHERI RISC-V system instruction.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// CHERI CSR (control and status register read/write) instruction options.
//===----------------------------------------------------------------------===//


class CheriSysReg<string name, bits<12> op> {
  string Name = name;
  bits<12> Encoding = op;
  bit isYName = 0;
  bit isZcheriName = 0;
}

multiclass CheriExtSysReg<string name, bits<12> op> {
  let isYName = 1 in
  def "" : CheriSysReg<name, op>;
  let isZcheriName = 1 in
  def C  : CheriSysReg<!strconcat(name, "c"), op>;
}

def CheriSysRegsList : GenericTable {
  let FilterClass = "CheriSysReg";
  let Fields = [
    "Name", "Encoding", "isYName", "isZcheriName"
  ];

  let PrimaryKey = [ "Encoding" ];
  let PrimaryKeyName = "lookupCheriSysRegByEncoding";
  let PrimaryKeyReturnRange = true;
}

def lookupCheriSysRegByName : SearchIndex {
  let Table = CheriSysRegsList;
  let Key = [ "Name" ];
}

//===----------------------------------------------------------------------===//
// Debug-mode Cheri CSRs
//===----------------------------------------------------------------------===//
defm : CheriExtSysReg<"dpc", 0x7b1>;
defm : CheriExtSysReg<"dscratch0", 0x7b2>;
defm : CheriExtSysReg<"dscratch1", 0x7b3>;
def : CheriSysReg<"dinfc", 0x7bd>;

//===----------------------------------------------------------------------===//
// Machine-mode Cheri CSRs
//===----------------------------------------------------------------------===//
defm : CheriExtSysReg<"mtvec", 0x305>;
defm : CheriExtSysReg<"mscratch", 0x340>;
defm : CheriExtSysReg<"mepc", 0x341>;
def : CheriSysReg<"mtidc", 0x780>;

//===----------------------------------------------------------------------===//
// Supervisor-mode Cheri CSRs
//===----------------------------------------------------------------------===//
defm : CheriExtSysReg<"stvec", 0x105>;
defm : CheriExtSysReg<"sscratch", 0x140>;
defm : CheriExtSysReg<"sepc", 0x141>;
def : SysReg<"stval2", 0x14b>;
def : CheriSysReg<"stidc", 0x580>;

//===----------------------------------------------------------------------===//
// User-mode Cheri CSRs
//===----------------------------------------------------------------------===//
defm : CheriExtSysReg<"jvt", 0x017>;
def : CheriSysReg<"utidc", 0x480>;

//===----------------------------------------------------------------------===//
// Zcherihybrid CSRs
//===----------------------------------------------------------------------===//
def : CheriSysReg<"dddc", 0x7bc>;
def : CheriSysReg<"mtdc", 0x74c>;
def : CheriSysReg<"stdc", 0x163>;
def CSR_DDC : CheriSysReg<"ddc" , 0x416>;

//===----------------------------------------------------------------------===//
// Hypervisor Trap Handling
//===----------------------------------------------------------------------===//
def : SysReg<"htval2", 0x64b>;

//===----------------------------------------------------------------------===//
// Virtual Supervisor Registers
//===----------------------------------------------------------------------===//
defm : CheriExtSysReg<"vstvec", 0x205>;
defm : CheriExtSysReg<"vsscratch", 0x240>;
defm : CheriExtSysReg<"vsepc", 0x241>;
def : CheriSysReg<"vstdc", 0x245>;
def : SysReg<"vstval2", 0x24b>;
def : CheriSysReg<"vstidc", 0xa80>;
