/* cab_runtime_stubs.c
 *
 * Stubs minimos para resolver __assert/_assert que Wine cabinet
 * (fci.c, fdi.c) referenciam:
 *
 *   bcc32c emite __assert (Win32 OMF Embarcadero)
 *   bcc64  emite _assert  (Win64 ELF Embarcadero)
 *   mingw  emite __assert (Win32 COFF) e _assert (Win64 COFF)
 *
 * Definimos os 3 nomes — linker pega o que precisar; o resto fica
 * unused sem causar conflito.
 *
 * v3.7.2: zlib stubs REMOVIDOS — zlib real linkado de Lib/zlib_obj_*
 * via Pascal {$L} chain. Symbols deflate/inflate/etc agora vem do
 * zlib oficial; MSZIP compression funcional.
 *
 * Compilado em 4 toolchains:
 *   bcc32c -> Lib/cabnet_obj_win32/cab_runtime_stubs.obj   (OMF)
 *   bcc64  -> Lib/cabnet_obj_win64/cab_runtime_stubs.o     (ELF)
 *   mingw  -> Lib/cabnet_obj_fpc_win32/cab_runtime_stubs.o (COFF Win32)
 *   mingw  -> Lib/cabnet_obj_fpc_win64/cab_runtime_stubs.o (COFF Win64)
 */

#include <stddef.h>

void __assert(const char* expr, const char* file, int line) {
  (void)expr; (void)file; (void)line;
}

void _assert(const char* expr, const char* file, int line) {
  (void)expr; (void)file; (void)line;
}

void _assert_4(const char* expr, const char* file, int line, const char* func) {
  (void)expr; (void)file; (void)line; (void)func;
}

/* ===== zlib Z_SOLO mode allocators =====
 * Com -DZ_SOLO zlib nao define zcalloc/zcfree default (delega ao user).
 * Wine cabinet supply own callbacks via z_stream.zalloc/zfree;
 * mas alguns paths zlib chamam zcalloc/zcfree direto se z->zalloc eh NULL.
 * Forneco implementacoes via malloc/free. */

extern void* malloc(size_t size);
extern void  free(void* ptr);

void* zcalloc(void* opaque, unsigned items, unsigned size) {
  (void)opaque;
  return malloc((size_t)items * size);
}

void zcfree(void* opaque, void* ptr) {
  (void)opaque;
  free(ptr);
}

/* ===== Embarcadero bcc32c 64-bit math helpers =====
 * Win32 bcc32c emite __aullrem, __aulldiv etc para operacoes 64-bit
 * em codigo zlib (crc32 + others). Embarcadero crtl tem essas funcoes
 * mas precisa linkar libc explicit. Implementacao manual evita
 * dependencia. Apenas para Win32; bcc64/mingw geram codigo nativo
 * sem precisar helpers.
 */
/* Bitwise implementations evitam que bcc32c emita refs recursivas a
 * __aullrem dentro do proprio __aullrem (compiler-builtin que faria
 * a operacao % seria substituida por call helper, criando ciclo). */

static unsigned long long _udivmod64(unsigned long long a, unsigned long long b, int wantRem) {
  unsigned long long q = 0, bit = 1;
  if (b == 0) return 0;
  while (b < a && (b & (1ULL << 63)) == 0) { b <<= 1; bit <<= 1; }
  while (bit) {
    if (a >= b) { a -= b; q |= bit; }
    b >>= 1; bit >>= 1;
  }
  return wantRem ? a : q;
}

/* __attribute__((used)) impede que clang dead-code-elimine essas funcoes
 * mesmo se nada interno as referencia (referencias vem do linker). */
#ifdef __GNUC__
#define KEEP __attribute__((used,visibility("default")))
#else
#define KEEP
#endif

KEEP unsigned long long __aullrem(unsigned long long a, unsigned long long b) { return _udivmod64(a, b, 1); }
KEEP unsigned long long __aulldiv(unsigned long long a, unsigned long long b) { return _udivmod64(a, b, 0); }
long long __allrem(long long a, long long b) {
  if (b == 0) return 0;
  {
    unsigned long long ua = (a < 0) ? (unsigned long long)(-a) : (unsigned long long)a;
    unsigned long long ub = (b < 0) ? (unsigned long long)(-b) : (unsigned long long)b;
    unsigned long long r = _udivmod64(ua, ub, 1);
    return (a < 0) ? -(long long)r : (long long)r;
  }
}
long long __alldiv(long long a, long long b) {
  if (b == 0) return 0;
  {
    int neg = ((a < 0) ^ (b < 0)) ? 1 : 0;
    unsigned long long ua = (a < 0) ? (unsigned long long)(-a) : (unsigned long long)a;
    unsigned long long ub = (b < 0) ? (unsigned long long)(-b) : (unsigned long long)b;
    unsigned long long q = _udivmod64(ua, ub, 0);
    return neg ? -(long long)q : (long long)q;
  }
}
KEEP long long __allmul(long long a, long long b) { return a * b; }
KEEP long long __allshl(long long a, int shift) { return a << shift; }
KEEP long long __allshr(long long a, int shift) { return a >> shift; }
KEEP unsigned long long __aullshr(unsigned long long a, int shift) { return a >> shift; }
KEEP long long __allrem_keep(long long a, long long b) { return __allrem(a, b); }
KEEP long long __alldiv_keep(long long a, long long b) { return __alldiv(a, b); }
