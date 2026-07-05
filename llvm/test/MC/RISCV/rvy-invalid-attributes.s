# RUN: not --crash llvm-mc -triple=riscv32 -mattr=+y,+zcf /dev/null 2>&1 | FileCheck %s --check-prefix=RV32Y-ZCF
# RUN: not --crash llvm-mc -triple=riscv64 -mattr=+y,+zcd /dev/null 2>&1 | FileCheck %s --check-prefix=RV64Y-ZCD

# RUN: not llvm-mc -triple=riscv64 < %s 2>&1 | FileCheck %s --check-prefix=ATTR --implicit-check-not="error:"

# RV32Y-ZCF: LLVM ERROR: 'zcf' is incompatible with rv32y base
# RV64Y-ZCD: LLVM ERROR: 'zcd' is incompatible with rv64y base

.attribute arch, "rv32y0p99_zcf"
# ATTR: error: invalid arch name 'rv32y0p99_zcf', 'zcf' is incompatible with rv32y base

.attribute arch, "rv64y0p99_zcd"
# ATTR: error: invalid arch name 'rv64y0p99_zcd', 'zcd' is incompatible with rv64y base
