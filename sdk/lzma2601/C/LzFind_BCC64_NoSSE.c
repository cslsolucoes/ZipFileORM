/* LzFind_BCC64_NoSSE.c
   Compatibility wrapper: bcc64.exe (Embarcadero Clang 5.0 Win64) ships
   without the SSE4.1 intrinsic headers (smmintrin.h, arm_neon.h, etc.),
   so the LZMA SDK 24.07 LzFind.c SATUR_SUB acceleration paths won't
   compile against it.

   This wrapper neutralises the SIMD acceleration block before including
   LzFind.c, falling back to the scalar implementation that the SDK uses
   as its default. The scalar path is fully functional — only somewhat
   slower than the SSE/AVX vectorised variant.

   Compiled in place of LzFind.c for Win64 only; the regular LzFind.c is
   still used for Win32 via bcc32c (which has its own intrinsic headers).
*/

/* Force the compile-time SIMD detection block to take the "no acceleration"
   path. Both 128- and 256-bit SATUR_SUB variants are gated by
   USE_LZFIND_SATUR_SUB_128 / _256; if neither is defined, the scalar code
   in LzFind.c runs unchanged. */
#define MY_CPU_ARM_OR_ARM64  /* fake-ARM to skip the AMD64 include block */
#define MY_CPU_ARM64
#include <stdint.h>
typedef uint32_t uint32x4_t[4];   /* dummy type so #ifdef'd ARM section compiles */
#define vsubq_u32(a, b) (a)        /* never called when USE_LZFIND_SATUR_SUB_128 undefined */
#define vmaxq_u32(a, b) (a)

/* Make sure none of the SATUR_SUB defines is set. */
#undef USE_LZFIND_SATUR_SUB_128
#undef USE_LZFIND_SATUR_SUB_256
#undef LZFIND_ATTRIB_SSE41
#undef LZFIND_ATTRIB_AVX2

/* Now compile the real LZMA LzFind.c — the SIMD blocks will be skipped
   because their guards are not satisfied. */
#include "LzFind.c"
