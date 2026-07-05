# RUN: llvm-mc %s -triple=riscv32 -filetype=asm -riscv-add-build-attributes \
# RUN:   -mattr=+y,+zce,+f | FileCheck %s --check-prefix=RV32Y-ZCE-F

## RV32Y + ZCE + F: y is enabled, so zcf is not implied by zce + f.
# RV32Y-ZCE-F: .attribute 5, "rv32i2p1_f2p2_y0p99_zicsr2p0_zca1p0_zcb1p0_zce1p0_zcmp1p0_zcmt1p0"
