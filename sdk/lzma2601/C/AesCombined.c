/* AesCombined.c
 *
 * Combina Aes.c + AesOpt.c em um unico OBJ. Motivacao: Aes.c referencia
 * AesCbc_Encode_HW / AesCbc_Decode_HW / AesCtr_Code_HW definidos em
 * AesOpt.c, enquanto AesOpt.c referencia simbolos de Aes.c. O linker
 * single-pass ELF do Delphi bcc64 nao resolve refs mutuas entre dois
 * OBJs separados — colocando-as num unico compilation unit, os simbolos
 * resolvem-se internamente.
 *
 * Compilado por Build-LzmaObjs.ps1 para Win64 (substituindo Aes.o +
 * AesOpt.o). Win32 OMF linker (BCC102 ilink32) e multi-pass: Aes.obj +
 * AesOpt.obj separados continuam funcionando la — combinado e Win64-only.
 *
 * IMPORTANTE: bcc64 (Embarcadero clang) tem frontend clang completo mas
 * backend LLVM incompleto — nao suporta intrinsics x86 AES-NI
 * (llvm.x86.aesni.aesdec etc.). A heuristica de AesOpt.c detecta clang
 * via Z7_LLVM_CLANG_VERSION e ativa USE_INTEL_AES, gerando intrinsics
 * que bcc64 nao consegue selecionar. Para evitar, forcamos uso da
 * variante stub puro-SW via Z7_USE_AES_HW_STUB + #undef das gates de
 * detecao Clang ANTES de incluir AesOpt.c.
 *
 * v3.1.1 — Adicionado para fechar TSevenZFile Win64.
 */

#include "Aes.c"

/* Suprime deteccao de clang/gcc/icc dentro de AesOpt.c. Forca caminho
 * de stub (Z7_USE_AES_HW_STUB) que emite wrappers SW para Aes*_HW. */
#undef Z7_LLVM_CLANG_VERSION
#undef Z7_APPLE_CLANG_VERSION
#undef Z7_CLANG_VERSION
#undef Z7_GCC_VERSION
#undef __INTEL_COMPILER
#define Z7_USE_AES_HW_STUB
#define Z7_USE_VAES_HW_STUB

#include "AesOpt.c"
