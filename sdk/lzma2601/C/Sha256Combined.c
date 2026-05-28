/* Sha256Combined.c
 *
 * Combina Sha256.c + Sha256Opt.c em um unico OBJ. Motivacao: Sha256.c
 * referencia Sha256_UpdateBlocks_HW definida em Sha256Opt.c, enquanto
 * Sha256Opt.c referencia SHA256_K_ARRAY definida em Sha256.c. O linker
 * single-pass ELF do Delphi bcc64 nao resolve refs mutuas entre dois
 * OBJs separados — colocando-as num unico compilation unit, os simbolos
 * resolvem-se internamente.
 *
 * Compilado por Build-LzmaObjs.ps1 para Win64 (substituindo Sha256.o +
 * Sha256Opt.o). Win32 OMF e multi-pass, nao precisa.
 *
 * IMPORTANTE: bcc64 (Embarcadero clang) tem frontend clang completo mas
 * backend LLVM incompleto — nao suporta intrinsics x86 SHA-NI. Forcamos
 * uso da variante stub puro-SW via Z7_USE_HW_SHA_STUB + #undef das
 * gates de detecao Clang ANTES de incluir Sha256Opt.c.
 *
 * v3.1.1 — Adicionado para fechar TSevenZFile Win64.
 */

#include "Sha256.c"

/* Suprime deteccao de clang/gcc/icc dentro de Sha256Opt.c. */
#undef Z7_LLVM_CLANG_VERSION
#undef Z7_APPLE_CLANG_VERSION
#undef Z7_CLANG_VERSION
#undef Z7_GCC_VERSION
#undef __INTEL_COMPILER
#define Z7_USE_HW_SHA_STUB

#include "Sha256Opt.c"
