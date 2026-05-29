// RUN: llvm-mc --triple=riscv32 -mattr=+y --riscv-no-aliases --show-encoding --defsym=XLEN=32 < %s \
// RUN:   | FileCheck --check-prefixes=CHECK,CHECK-ASM,CHECK-ASM-32,CHECK-32 %s
// RUN: llvm-mc --filetype=obj --triple=riscv32 --mattr=+y --defsym=XLEN=32 --riscv-add-build-attributes < %s \
// RUN:   | llvm-objdump -M no-aliases -d --no-print-imm-hex - | FileCheck %s --check-prefixes=CHECK,CHECK-32
// RUN: llvm-mc --triple=riscv64 --mattr=+y --riscv-no-aliases --show-encoding --defsym=XLEN=64 < %s \
// RUN:   | FileCheck --check-prefixes=CHECK,CHECK-ASM,CHECK-ASM-64,CHECK-64 %s
// RUN: llvm-mc --filetype=obj --triple=riscv64 --mattr=+y --defsym=XLEN=64 --riscv-add-build-attributes < %s \
// RUN:   | llvm-objdump -M no-aliases -d --no-print-imm-hex - | FileCheck %s --check-prefixes=CHECK,CHECK-64

yadd a0, a0, a1
// CHECK: yadd	ca0, ca0, a1
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xb5,0x06]
yaddi a0, a0, 12
// CHECK: yaddi	ca0, ca0, 12
// CHECK-ASM-SAME: # encoding: [0x7b,0x45,0xc5,0x00]
yadd a0, a0, 12
// CHECK: yaddi	ca0, ca0, 12
// CHECK-ASM-SAME: # encoding: [0x7b,0x45,0xc5,0x00]
yaddrw a0, a0, a1
// CHECK: yaddrw	ca0, ca0, a1
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xb5,0x16]
ypermc a0, a0, a0
// CHECK: ypermc	ca0, ca0, a0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xa5,0x26]
ymv a0, a0
// CHECK: ymv	ca0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0x05,0x06]
//# Note: mv expands to integer addi and not capability ymv:
mv a0, a0
// CHECK: addi	a0, a0, 0
// CHECK-ASM-SAME: # encoding: [0x13,0x05,0x05,0x00]
packy a0, a0, a0
// CHECK: packy	ca0, ca0, a0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xa5,0x02]
yhiw a0, a0, a0
// CHECK: packy	ca0, ca0, a0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xa5,0x02]
ybndsw a0, a0, a0
// CHECK: ybndsw	ca0, ca0, a0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xa5,0x36]
ybndsrw a0, a0, a0
// CHECK: ybndsrw	ca0, ca0, a0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xa5,0x46]
ybndswi a0, a0, 12
// CHECK: ybndswi	ca0, ca0, 12
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0xc5,0xe0]
ybndswi a0, a0, 12
// CHECK: ybndswi	ca0, ca0, 12
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0xc5,0xe0]
//# Test all the  min and max values for the ybndswi encoding
ybndswi a0, a0, 1
// CHECK: ybndswi	ca0, ca0, 1
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0x15,0xe0]
ybndswi a0, a0, 255
// CHECK: ybndswi	ca0, ca0, 255
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0xf5,0xef]
ybndswi a0, a0, 264
// CHECK: ybndswi	ca0, ca0, 264
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0x05,0xf1]
ybndswi a0, a0, 504
// CHECK: ybndswi	ca0, ca0, 504
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0xf5,0xf1]
ybndswi a0, a0, 512
// CHECK-ASM: ybndswi	ca0, ca0, 512
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0x05,0xf2]
ybndswi a0, a0, 528
// CHECK-ASM: ybndswi	ca0, ca0, 528
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0x15,0xf2]
ybndswi a0, a0, 2048
// CHECK-ASM: ybndswi	ca0, ca0, 2048
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0x05,0xf8]
ybndswi a0, a0, 4080
// CHECK-ASM: ybndswi	ca0, ca0, 4080
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0xf5,0xff]
ybndswi a0, a0, 4096
// CHECK: ybndswi	ca0, ca0, 4096
// CHECK-ASM-SAME: # encoding: [0x7b,0x55,0x05,0xe0]
ysunseal a0, a0, a0
// CHECK: ysunseal	ca0, ca0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xa5,0x0e]
ybld a0, a0, a0
// CHECK: ybld	ca0, ca0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xa5,0x1e]
ybaser a0, a0
// CHECK: ybaser	a0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0x05,0xf4]
ylenr a0, a0
// CHECK: ylenr	a0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0x35,0xf4]
ytopr a0, a0
// CHECK: ytopr	a0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0x25,0xf4]
ytagr a0, a0
// CHECK: ytagr	a0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0x45,0xf4]
ypermr a0, a0
// CHECK: ypermr	a0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0x15,0xf4]
ytyper a0, a0
// CHECK: ytyper	a0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0x55,0xf4]
srliy a0, a0, XLEN
// CHECK-32: srliy	a0, ca0, 32
// CHECK-64: srliy	a0, ca0, 64
// CHECK-ASM-32-SAME: # encoding: [0x7b,0x55,0x05,0x02]
// CHECK-ASM-64-SAME: # encoding: [0x7b,0x55,0x05,0x04]
yhir a0, a0
// CHECK-32: srliy	a0, ca0, 32
// CHECK-64: srliy	a0, ca0, 64
// CHECK-ASM-32-SAME: # encoding: [0x7b,0x55,0x05,0x02]
// CHECK-ASM-64-SAME: # encoding: [0x7b,0x55,0x05,0x04]
yeq a0, a0, a0
// CHECK: yeq	a0, ca0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xa5,0x0c]
yss a0, a0, a0
// CHECK: yss	a0, ca0, ca0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0xa5,0x1c]
yamask a0, a0
// CHECK: yamask	a0, a0
// CHECK-ASM-SAME: # encoding: [0x7b,0x05,0x05,0xf0]
