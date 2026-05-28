/* LzmaStubsST.c
   Single-threaded stubs that satisfy LzmaEnc.c references to MatchFinderMt_*
   symbols without dragging in LzFindMt.c + its OS threading dependencies.

   In _7ZIP_ST builds the runtime control flow never actually calls these
   (the MT path is guarded by numThreads > 1, which we never set), so the
   bodies are no-ops that just satisfy the linker.

   Compiled with:  bcc32c -c -O2 -D_7ZIP_ST -o LzmaStubsST.obj LzmaStubsST.c
*/

#include <stddef.h>

typedef int SRes;
#define SZ_OK 0
#define SZ_ERROR_UNSUPPORTED 4

void MatchFinderMt_Construct(void *p) { (void)p; }
void MatchFinderMt_Destruct(void *p, const void *alloc) { (void)p; (void)alloc; }
SRes MatchFinderMt_Create(void *p, unsigned hist, unsigned a, unsigned b,
                          unsigned c, unsigned d, const void *alloc) {
  (void)p; (void)hist; (void)a; (void)b; (void)c; (void)d; (void)alloc;
  return SZ_ERROR_UNSUPPORTED;
}
void MatchFinderMt_CreateVTable(void *p, void *v) { (void)p; (void)v; }
void MatchFinderMt_ReleaseStream(void *p) { (void)p; }
SRes MatchFinderMt_InitMt(void *p) { (void)p; return SZ_OK; }
