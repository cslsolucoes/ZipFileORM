/* SevenZWrapper.c
 *
 * Minimal C wrapper around LZMA SDK 24.07 7zip read-only API for use from
 * Object Pascal (Delphi D24..D37 + FPC/Lazarus). Encapsulates:
 *   - CFileInStream + CLookToRead2 (file I/O machinery)
 *   - ISzAlloc instances
 *   - CSzArEx archive directory
 *   - Solid-block extract cache
 *
 * Pascal side only deals with: open path, list entries, get name, extract.
 * No raw struct exposure -> ABI-stable across SDK versions.
 *
 * Build (joins existing Build-LzmaObjs.ps1 set):
 *   bcc32c -c -O2 -D_7ZIP_ST SevenZWrapper.c
 *   bcc64  -c -O2 -D_7ZIP_ST SevenZWrapper.c
 */

#include "Precomp.h"
#include <stdlib.h>
#include <string.h>

#include "7z.h"
#include "7zAlloc.h"
#include "7zCrc.h"
#include "7zFile.h"
#include "7zVersion.h"

/* ----------------------------------------------------------------
 *   Opaque context — Pascal sees only void*
 * ---------------------------------------------------------------- */
typedef struct {
  CSzArEx       db;
  CFileInStream archiveStream;
  CLookToRead2  lookStream;
  ISzAlloc      allocImp;
  ISzAlloc      allocTempImp;
  /* Cache for solid-block extraction */
  UInt32        blockIndex;
  Byte*         outBuffer;
  size_t        outBufferSize;
  int           opened;
  /* Pre-allocated UTF-16 name scratch */
  UInt16*       nameBuf;
  size_t        nameBufSize;
} SzCtx;

#define LOOKBUF_SIZE (1 << 16)

/* ----------------------------------------------------------------
 *   Internal helpers
 * ---------------------------------------------------------------- */
static int g_crcInited = 0;

static void EnsureCrcInited(void) {
  if (!g_crcInited) {
    CrcGenerateTable();
    g_crcInited = 1;
  }
}

/* ----------------------------------------------------------------
 *   Public API exposed to Pascal
 *   All exports use cdecl. Pascal Win64 sees `SzCtx_Open`; Win32
 *   OMF sees `_SzCtx_Open` (bcc32c auto-prefixes).
 * ---------------------------------------------------------------- */

/* Returns non-NULL on success, NULL on failure. Pascal can compare to nil. */
SzCtx* SzCtx_Open(const char* path) {
  SzCtx* ctx;
  SRes res;

  EnsureCrcInited();
  ctx = (SzCtx*) malloc(sizeof(SzCtx));
  if (!ctx) return NULL;
  memset(ctx, 0, sizeof(SzCtx));

  if (InFile_Open(&ctx->archiveStream.file, path) != 0) {
    free(ctx);
    return NULL;
  }

  ctx->allocImp.Alloc     = SzAlloc;
  ctx->allocImp.Free      = SzFree;
  ctx->allocTempImp.Alloc = SzAllocTemp;
  ctx->allocTempImp.Free  = SzFreeTemp;

  FileInStream_CreateVTable(&ctx->archiveStream);
  ctx->archiveStream.wres = 0;

  LookToRead2_CreateVTable(&ctx->lookStream, 0);
  ctx->lookStream.buf = (Byte*) ISzAlloc_Alloc(&ctx->allocImp, LOOKBUF_SIZE);
  if (!ctx->lookStream.buf) {
    File_Close(&ctx->archiveStream.file);
    free(ctx);
    return NULL;
  }
  ctx->lookStream.bufSize    = LOOKBUF_SIZE;
  ctx->lookStream.realStream = &ctx->archiveStream.vt;
  LookToRead2_INIT(&ctx->lookStream);

  SzArEx_Init(&ctx->db);
  res = SzArEx_Open(&ctx->db, &ctx->lookStream.vt, &ctx->allocImp, &ctx->allocTempImp);
  if (res != SZ_OK) {
    ISzAlloc_Free(&ctx->allocImp, ctx->lookStream.buf);
    File_Close(&ctx->archiveStream.file);
    free(ctx);
    return NULL;
  }

  ctx->blockIndex    = 0xFFFFFFFF;
  ctx->outBuffer     = NULL;
  ctx->outBufferSize = 0;
  ctx->opened        = 1;
  return ctx;
}

void SzCtx_Close(SzCtx* ctx) {
  if (!ctx) return;
  if (ctx->opened) {
    if (ctx->outBuffer) {
      ISzAlloc_Free(&ctx->allocImp, ctx->outBuffer);
      ctx->outBuffer = NULL;
    }
    SzArEx_Free(&ctx->db, &ctx->allocImp);
    if (ctx->lookStream.buf) {
      ISzAlloc_Free(&ctx->allocImp, ctx->lookStream.buf);
      ctx->lookStream.buf = NULL;
    }
    File_Close(&ctx->archiveStream.file);
    if (ctx->nameBuf) {
      free(ctx->nameBuf);
      ctx->nameBuf = NULL;
    }
    ctx->opened = 0;
  }
  free(ctx);
}

/* Number of entries (files + directories) in archive. */
unsigned SzCtx_FileCount(const SzCtx* ctx) {
  if (!ctx || !ctx->opened) return 0;
  return (unsigned) ctx->db.NumFiles;
}

/* Returns 1 if entry idx is a directory, 0 if file. */
int SzCtx_IsDir(const SzCtx* ctx, unsigned idx) {
  if (!ctx || !ctx->opened || idx >= ctx->db.NumFiles) return 0;
  return SzArEx_IsDir(&ctx->db, idx) ? 1 : 0;
}

/* Uncompressed size of entry idx. */
unsigned long long SzCtx_FileSize(const SzCtx* ctx, unsigned idx) {
  if (!ctx || !ctx->opened || idx >= ctx->db.NumFiles) return 0;
  return (unsigned long long) SzArEx_GetFileSize(&ctx->db, idx);
}

/* Writes UTF-8 name of entry idx into outBuf (NUL-terminated).
 * Returns required buffer size (incl. NUL). If outBuf is NULL, only
 * returns the required size without writing. */
unsigned SzCtx_GetNameUtf8(SzCtx* ctx, unsigned idx, char* outBuf, unsigned bufSize) {
  size_t neededU16, i, u8len;
  UInt16 c;

  if (!ctx || !ctx->opened || idx >= ctx->db.NumFiles) return 0;

  /* First call: get required UTF-16 size (incl. NUL) */
  neededU16 = SzArEx_GetFileNameUtf16(&ctx->db, idx, NULL);
  if (neededU16 == 0) return 0;

  if (ctx->nameBufSize < neededU16) {
    if (ctx->nameBuf) free(ctx->nameBuf);
    ctx->nameBuf = (UInt16*) malloc(sizeof(UInt16) * neededU16);
    if (!ctx->nameBuf) { ctx->nameBufSize = 0; return 0; }
    ctx->nameBufSize = neededU16;
  }
  SzArEx_GetFileNameUtf16(&ctx->db, idx, ctx->nameBuf);

  /* Compute UTF-8 length (rough — assumes ASCII / simple BMP).
   * For full UTF-8 conversion we'd need a real encoder; here we do
   * the basic 3-tier (1/2/3-byte) BMP mapping. Surrogate pairs not
   * supported (rare in archive names). */
  u8len = 0;
  for (i = 0; i + 1 < neededU16; i++) {
    c = ctx->nameBuf[i];
    if (c == 0) break;
    if (c < 0x80) u8len += 1;
    else if (c < 0x800) u8len += 2;
    else u8len += 3;
  }
  u8len += 1; /* NUL */

  if (!outBuf || bufSize == 0) return (unsigned) u8len;
  if (bufSize < u8len) return (unsigned) u8len; /* caller should retry */

  /* Encode UTF-8 */
  u8len = 0;
  for (i = 0; i + 1 < neededU16; i++) {
    c = ctx->nameBuf[i];
    if (c == 0) break;
    if (c < 0x80) {
      outBuf[u8len++] = (char) c;
    } else if (c < 0x800) {
      outBuf[u8len++] = (char) (0xC0 | (c >> 6));
      outBuf[u8len++] = (char) (0x80 | (c & 0x3F));
    } else {
      outBuf[u8len++] = (char) (0xE0 | (c >> 12));
      outBuf[u8len++] = (char) (0x80 | ((c >> 6) & 0x3F));
      outBuf[u8len++] = (char) (0x80 | (c & 0x3F));
    }
  }
  outBuf[u8len++] = '\0';
  return (unsigned) u8len;
}

/* Extracts entry idx into outBuf. outBuf must be pre-allocated by caller
 * with size >= SzCtx_FileSize(ctx, idx). Returns SZ_OK (0) on success,
 * SDK SRes error otherwise. */
int SzCtx_Extract(SzCtx* ctx, unsigned idx, unsigned char* outBuf, unsigned long long bufSize) {
  SRes res;
  size_t offset = 0;
  size_t outSizeProcessed = 0;
  unsigned long long fileSize;

  if (!ctx || !ctx->opened || idx >= ctx->db.NumFiles) return SZ_ERROR_PARAM;
  if (SzArEx_IsDir(&ctx->db, idx)) return SZ_ERROR_PARAM;

  fileSize = SzCtx_FileSize(ctx, idx);
  if (bufSize < fileSize) return SZ_ERROR_OUTPUT_EOF;

  res = SzArEx_Extract(
    &ctx->db,
    &ctx->lookStream.vt,
    (UInt32) idx,
    &ctx->blockIndex,
    &ctx->outBuffer,
    &ctx->outBufferSize,
    &offset,
    &outSizeProcessed,
    &ctx->allocImp,
    &ctx->allocTempImp
  );
  if (res != SZ_OK) return (int) res;
  if (outSizeProcessed > 0 && outBuf) {
    memcpy(outBuf, ctx->outBuffer + offset, outSizeProcessed);
  }
  return SZ_OK;
}
