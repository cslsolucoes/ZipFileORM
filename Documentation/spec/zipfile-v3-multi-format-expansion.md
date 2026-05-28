# SPEC — ZipFileORM v3.x Multi-Format Expansion

**Documento:** Specification de roadmap para extensão multi-format do pacote `zipfile/`.
**Status:** ✅ **Roadmap v3.x fechado em 2026-05-27 com 21 releases entregues** (v3.0..v3.12 + patches).
**Data:** 2026-05-27.
**Estado base:** v2.3 (tag `zipfile-v2.3`, commit `06698c9`).
**Estado atual:** HEAD pós `0e8e7dd` (multi-IDE D24..D37 + design-time enrichment).

**Releases entregues (21 tags v3.x):**

- **v3.0** — TAR + Gzip + Tar.Gz + Archive.Open auto-detect (commit `38b7d12`)
- **v3.1** — 7zip READ Win32 (TSevenZFile) + FPC Linux x86_64 cross-compile (commit `b993b76`)
- **v3.1.1** — 7zip Win64 via 4 fixes bcc64 ELF (commit `69cb11d`)
- **v3.1.2** — 7zip WRITE Store pure-pascal container 7z (commit `8ced0de`)
- **v3.1.3** — 7zip WRITE LZMA2 via `Lzma2Enc.c` static-link 4 toolchains (commit `150e011`)
- **v3.2** — Streaming DEFLATE READ TZipEntryDeflateReadStream (commit `fc9fece`)
- **v3.3** — LHA Store (-lh0-) READ pure-pascal (commit `2298f63`)
- **v3.3.1** — LHA decoder OBJs 4 toolchains 36/36 (commit `e2e52b1`)
- **v3.3.2** — LH4/5/6/7 Pascal decoder port compile-verified (commit `2da3644`)
- **v3.4** — ARJ method 0 (Store) READ pure-pascal (commit `baf7d2a`)
- **v3.5** — RAR5 method 0 (Store) READ pure-pascal + vint decoder (commit `5457d64`)
- **v3.6** — LZMA FPC Win32/Win64 via mingw COFF + msvcrt (commit `aeb7e77`)
- **v3.7** — CAB READ 4 toolchains via Wine FDI/FCI (commits `8601e9c`+`9ad1239`+`c19454b`)
- **v3.7.1** — CAB WRITE Store-only via FCI (commit `75b9c34`)
- **v3.7.2** — CAB WRITE MSZIP via zlib static-link (commit `ab25e1e`)
- **v3.7.3** — CAB MSZIP Delphi Win32 fix `-DNO_DIVIDE` adler32 (commit `1116655`)
- **v3.8** — BZIP2 4 toolchains via bzip2-1.1.0-dev + stdcall fix (commit `7f2c818`)
- **v3.9** — Z LZW pure-pascal stream codec (commit `9af2346`)
- **v3.10** — UUE pure-pascal stream codec (commit `9af2346`)
- **v3.11** — ISO 9660 + Joliet READ-only pure-pascal (commit `a34c5f1`)
- **v3.12** — **Design-Time Enrichment (2026-05-27)** — palette `ZipCompress`, 10 componentes
  visuais, TGzipFile single-file, IOTA Splash + About registration, ícones gradient/rounded
  por formato, 70+ properties published cross-componente (write config + read header info +
  events OnFileChanged/OnProgress + property categories), rename unit namespace
  (TarFile/TarGzFile/GzipFile/CabFile/SevenZFile/ArjFile/IsoFile/LhaFile/RarFile sem
  prefixo `<Domain>.`). Multi-IDE D24..D37 rollout (49 BPLs deployados em
  `BDSCOMMONDIR\Bpl[\Win64]\` nos 7 IDEs). Ver §16.

**Infra entregue (commit `dc013d7` + ampliações posteriores):**

- `deps/gcc-mingw-w64/` — gcc 16.1.0 mingw-w64 standalone (Windows COFF para FPC)
- `deps/gcc-linux-musl/` — gcc 15.2.0 Linux musl cross (ELF Linux, ainda não integrado)
- `deps/win32/include/` + `deps/win64/include/` — Embarcadero Win SDK headers
- `sdk/cabnet/` — Wine cabinet source (FCI+FDI)
- `sdk/zlib/` — zlib oficial 1.3.2.1 (substituiu Wine zlib em commit `9b6bc38`)
- `sdk/{lzma2601,lha,arj,unrar,bzip2}/` — sources futuros formatos
- `sdk/lha/compat/sys/file.h` — shim para build SDK no Windows (v3.3.1)
- `sdk/arj/compat/c_defs.h` — stub autoconf-gen (v3.4.1 prep)
- `Lib/` — ~23 MB build outputs vendored (LZMA + bzip2 + cabnet + zlib + lha 4 toolchains cada)

**Investigado/deferido (substanciais, opcionais):**

- **v3.4.1** ARJ methods 1-9 (LZ77): SDK requer `msgbind` tooling para gerar `msg_*.h`
- **v3.5.1** RAR5 LZSS/PPMd: 150 .cpp C++ + Rijndael/Suns/BLAKE2; necessita bcc32x/64x + C++ ABI stubs
- **v3.12** Linux LZMA `.o` via gcc-linux-musl (já vendored, integração pendente)
- **v3.3.2 runtime** LHA -lh5+ Pascal decoder compile-OK; ambiente sem LHa CLI para gerar `.lh5` fixture validation
- **TCabFile FPC Win64** runtime AV em FCIFlushCabinet (bug interno em fci.obj mingw COFF)

**Autor:** Sessão consolidada via Claude (referência commits no histórico git master).

---

## 1. Contexto e motivação

O pacote `zipfile/` atualmente suporta **apenas o formato ZIP** com cobertura completa
(Store, Deflate via vendor, LZMA Win32+Win64, AES-256 WinZip-AE-2, ZIP64 read+write,
UTF-8, Streaming real, Fluent builder). O usuário levantou a pergunta: posso adicionar
suporte a **RAR, 7zip, ARJ, TAR, Gzip, LHA**?

Este documento analisa cada formato sob 5 critérios objetivos e propõe um plano de
expansão para uma série v3.x — preservando a API atual de `TZipFile` (zero breaking changes).

---

## 2. Critérios de avaliação

Cada formato foi avaliado contra:

| # | Critério | Significado |
|---|---|---|
| C1 | **Spec aberta** | Existe spec pública oficial ou de facto sem cláusula viral? |
| C2 | **Toolchain disponível sem DLL** | Pode ser implementado com bcc32c/bcc64 ou pure-pascal, sem dependência DLL externa? |
| C3 | **ROI técnico** | Frequência de uso real no ecossistema Delphi 2026? |
| C4 | **Esforço estimado** | LOC + horas para entregar leitura + escrita |
| C5 | **Reuso da infra existente** | Pode aproveitar `sdk/lzma2601/` ou `System.ZLib` que já estão integradas? |

---

## 3. Matriz de viabilidade por formato

> **Atualização 2026-05-25:** stakeholder forneceu material adicional —
> `zipfile/sdk/arj/` (ARJ 3.10 rev 22 source GPL-2) e `zipfile/dll/unrar_x86{,-64}/`
> (UnRAR.dll Win32 + Win64). Matriz revisada abaixo.

### 3.1 Política de licença — uso INTERNO

> **Atualização 2026-05-25 (stakeholder):** _"desconsiderar qualquer licença,
> é para uso somente interno"_.

**Implicação:** todas as restrições jurídicas analisadas em versões anteriores
deste SPEC (viral GPL-2, cláusula RARLAB UnRAR source, encoder RAR proprietário,
licença LGPL do zipfile) **não se aplicam**. O produto é deploy interno sem
distribuição comercial — gates legais não disparam.

**Critérios remanescentes:** apenas técnicos (toolchain disponível, esforço,
qualidade do source, manutenibilidade). Matriz §3.2 revisada nesta base.

### 3.2 Matriz revisada (uso interno — só critérios técnicos)

> **Update 2026-05-25:** stakeholder solicitou cobertura completa dos 12 formatos
> mainstream: **ZIP, RAR, 7-Zip, ARJ, LZH, TAR, GZip, CAB, UUE, ISO, BZIP2, Z**.
> Matriz expandida abaixo cobre todos.

| # | Formato | Toolchain | Source/binary | Esforço | Recomendação |
|---|---|---|---|---|---|
| 1 | **ZIP** | bcc32c/bcc64 + System.ZLib | ✅ Vendor + LZMA SDK | **Pronto** | ✅ **Entregue v2.3** |
| 2 | **TAR** | Pure-pascal | — | ~200 LOC / ~1h | ✅ **Entregue v3.0** |
| 3 | **Gzip** (.gz) | `System.ZLib` nativo | — | ~100 LOC / ~30min | ✅ **Entregue v3.0** |
| 4 | **Tar.Gz** (.tgz) | combo TAR+Gzip | — | ~100 LOC / ~30min | ✅ **Entregue v3.0** |
| 5a | **7zip READ Win32** (.7z) | bcc32c | ✅ `sdk/lzma2601/C/7z*.c` + SevenZCombined.c | ~6h (real) | ✅ **Entregue v3.1** |
| 5b | **7zip READ Win64** | bcc64 | ✅ `-fno-zero-initialized-in-bss` + Aes/Sha256 Combined + HW stubs + kernel32 imports | ~1.5h real | ✅ **Entregue v3.1.1** (commit `69cb11d`) |
| 5c | **7zip WRITE Store** | container 7z pure-pascal | ✅ SignatureHeader + PackInfo Copy + REAL_UINT64 + CRC32 + UTF-16 LE names | ~2h real | ✅ **Entregue v3.1.2** (commit `8ced0de`) |
| 5d | **7zip WRITE LZMA2** | `Lzma2Enc.c` static-link 4 toolchains | ✅ `-DZ7_ST` strip MtCoder + LzmaEnc deps + CLzmaEncProps 80B layout SDK 24.07 | ~2h real | ✅ **Entregue v3.1.3** (commit `150e011`) |
| 6a | **LHA Store (-lh0-)** Pure-pascal | Pure-pascal level 0/1/2 header parsing | — | ~1.5h real | ✅ **Entregue v3.3** (commit `2298f63`) — 5 plataformas |
| 6b | **LHA SDK OBJs (decoder cores)** | bcc32c/bcc64 + mingw -m32/-m64 | ✅ `sdk/lha/src/` 9 .c × 4 toolchains = 36/36 OBJ | ~1h real | ✅ **Entregue v3.3.1** (commit `e2e52b1`) |
| 6c | **LHA -lh4-/5/6/7 Pascal decoder** | Pure-pascal port do algoritmo SDK | LZSS + static Huffman + sliding dict 4-64KB | ~2h real | ⚠️ **v3.3.2 compile OK, runtime fixture pendente** (sem LHa CLI no ambiente) |
| 7a | **ARJ Store (method 0)** Pure-pascal | Pure-pascal + header parsing | — | ~1h real | ✅ **Entregue v3.4** (commit `baf7d2a`) — 5 plataformas |
| 7b | **ARJ methods 1-9** (LZ77) | bcc32c/bcc64 static-link | ⚠️ SDK requer `msgbind` tooling + `c_defs.h` autoconf-gen | ~6-10h | 🟡 **v3.4.1 deferida** — `sdk/arj/compat/c_defs.h` stub criado |
| 8a | **RAR5 Store (method 0)** Pure-pascal | Pure-pascal vint decoder + block header parsing | — | ~1.5h real | ✅ **Entregue v3.5** (commit `5457d64`) — 5 plataformas |
| 8b | **RAR5 LZSS/PPMd** | bcc32x/bcc64x (clang C++) static-link | ⚠️ 150 .cpp + C++ runtime stubs + Rijndael/Suns/BLAKE2 | ~15-25h | 🟡 **v3.5.1 deferida** — escopo multi-sessão |
| 9a | **CAB READ** (Wine FDI) | bcc32c/bcc64 + mingw 4 toolchains | ✅ `sdk/cabnet/` Wine sem cabinet.dll | ~6h real | ✅ **Entregue v3.7** (commits `8601e9c`+`9ad1239`+`c19454b`) |
| 9b | **CAB WRITE Store** (FCI) | idem 4 toolchains | ✅ FCI callbacks + cab_runtime_stubs | ~3h real | ✅ **Entregue v3.7.1** (commit `75b9c34`) |
| 9c | **CAB WRITE MSZIP** (zlib) | idem 4 toolchains + zlib oficial 1.3.2.1 | ✅ Delphi Win32 fix via `-DNO_DIVIDE` adler32 | ~3h real | ✅ **Entregue v3.7.2-v3.7.3** (commits `ab25e1e`+`1116655`) — FPC Win64 runtime AV deferido |
| 10 | **BZIP2** | bcc32c/bcc64 + mingw 4 toolchains | ✅ bzip2-1.1.0-dev source + stdcall fix + Win64 CRT stubs | ~1h real | ✅ **Entregue v3.8** (commit `7f2c818`) |
| 11 | **Z** (compress) | Pure-pascal LZW | — (patente expirou 2003) | ~2h | ✅ **Entregue v3.9** (commit `9af2346`) — 5 plataformas |
| 12 | **UUE** (uuencode) | Pure-pascal | — (spec trivial) | ~1h | ✅ **Entregue v3.10** (commit `9af2346`) — 5 plataformas |
| 13 | **ISO** (9660 + Joliet) | Pure-pascal | ✅ ECMA-119 + UCS-2 BE Joliet escape | ~2h real | ✅ **Entregue v3.11** (commit `a34c5f1`) — Delphi+FPC Win32/64 + FPC Linux64 |
| 14a | **Linux x86_64 core (FPC)** | FPC nativo cross-compile | ✅ ppcx64 -Tlinux -Px86_64 funcional | 1.5h real | ✅ **Entregue v3.1** (core sem LZMA/AES-NI) |
| 14b | **Linux x86_64 LZMA + AES-NI** | LZMA via gcc-linux-musl; asm AES-NI System V ABI | — (gcc-linux-musl 15.2 vendored em `deps/gcc-linux-musl/`) | ~4h | 🟡 **v3.12 pendente** — toolchain pronta, integração não feita |
| 14c | **Linux x86_64 Delphi** | RAD Studio Linux personality + PAServer | parcialmente instalada em D37 | ~4h | 🟡 **v3.12 opcional** |
| 15 | **LZMA FPC Win32/Win64** (compressor/decompressor standalone) | mingw -m32/-m64 + msvcrt | ✅ 6 .c × 2 toolchains = 12 OBJ | ~1.5h real | ✅ **Entregue v3.6** (commit `aeb7e77`) |
| 16 | **7zip WRITE Store** | Pure-pascal container 7z | ✅ SignatureHeader + Copy coder + REAL_UINT64 + CRC32 | ~2h real | ✅ **Entregue v3.1.2** (commit `8ced0de`) |
| 17 | **7zip WRITE LZMA2** | `Lzma2Enc.c` static-link 4 toolchains | ✅ -DZ7_ST strip MtCoder + CLzmaEncProps 80B | ~2h real | ✅ **Entregue v3.1.3** (commit `150e011`) |
| 18 | **DEFLATE Streaming READ** | Pure-pascal | ✅ TZipEntryDeflateReadStream | ~3h real | ✅ **Entregue v3.2** (commit `fc9fece`) |
| — | **RAR WRITE** | — | ❌ Sem spec aberta | inviável engenharia | 🔴 **Excluir** |

★ Material fornecido pelo stakeholder 2026-05-25 (LHA + ARJ + UnRAR.dll).
★★ Novo na lista — adicionado após solicitação completa dos 12 formatos.
★★★ Adicionado após solicitação cross-OS — não é formato, é plataforma adicional.

**Total v3.x:** 11 capacidades novas + 1 já entregue (ZIP) + Linux multi-OS
= **12 formatos × 2 OS (Windows + Linux)**. Esforço estimado: **~61–65 horas**
distribuídas em **13 releases independentes** (v3.0..v3.12).

---

## 4. Recomendação técnica — v3.0 e v3.1

### v3.0 — TAR + Gzip + Tar.Gz ✅ ENTREGUE (commit `38b7d12`, tag `zipfile-v3.0`)

**Justificativa:** Combo cobre 95% dos casos cross-platform (Linux/macOS/Docker/CI),
não exige toolchain nova (TAR é trivial; Gzip usa `System.ZLib` que Delphi já provê),
mantém política "sem DLL externa", baixo risco.

**Novos arquivos:**

```
src/
├── Tar.TarFile.pas       — TTarFile (read + write, formato POSIX ustar)
├── Tar.GzipStream.pas    — TGzipReadStream + TGzipWriteStream (wrap System.ZLib)
└── Tar.TarGzFile.pas     — TTarGzFile (compose TTarFile + TGzipStream)
```

**API proposta:** TTarFile espelha API de TZipFile (additive, não-breaking):

```pascal
var Tar: TTarFile;
begin
  Tar := TTarFile.Create(nil);
  try
    Tar.FileName := 'archive.tar.gz';
    Tar.UseGzip := True;        // ativa wrapper Gzip
    Tar.OnProgress := MyHandler;
    Tar.Active := True;
    Tar.AppendFileFromDisk('app.exe', 'bin/app.exe');
    Tar.AppendStream(Stream, 'config.json', Now);
  finally Tar.Free; end;
end;
```

**Fluent v3.0:**

```pascal
Tar.NewArchive('out.tar.gz')
   .WithGzip(True)
   .AppendFile('app.exe', 'bin/app.exe')
   .Execute;
```

**Testes DUnitX (estimado 8 cases):**

- TAR write+read round-trip (3 entries, simbolic links opcional)
- Gzip stream round-trip (memory + disk)
- Tar.Gz combo round-trip
- POSIX ustar header validation (long names, modes)
- Gzip stream interop com `gzip -d` externo (smoke)

**Fixtures:**

- `tests/Tar.Tests.Core.pas` (read/write/list/extract)
- `tests/Tar.Tests.Gzip.pas` (wrap/unwrap)
- `tests/Tar.Tests.TarGz.pas` (combo end-to-end)

---

### v3.1 — 7zip READ-ONLY ✅ ENTREGUE (commit `b993b76`, tag `zipfile-v3.1`)

**Justificativa:** 7-Zip é o concorrente mais relevante de ZIP em 2026. Habilitar
**leitura** de archives `.7z` permite usuários consumirem inputs de sistemas que padronizaram
em 7-Zip (Windows backup, Vault, repositórios LZMA-comprimidos). Write é mais complexo
(LZMA2 encoder + stream framing 7z) e fica para v3.2 se demanda houver.

**Entregue (escopo real):**

- `src/SevenZ.SevenZFile.pas` — `TSevenZFile` READ-only Win32 (Delphi D24..D37)
- `sdk/lzma2601/C/SevenZWrapper.c` — wrapper C minimalista oculta CSzArEx do Pascal
- `sdk/lzma2601/C/SevenZCombined.c` — combina 7zArcIn.c + 7zDec.c em 1 OBJ
  (mutual deps `SzAr_DecodeFolder` ↔ `SzGetNextFolderItem` inviáveis no linker
  single-pass Delphi com OBJs separados)
- 26 OBJs Win32 OMF + 26 .o Win64 ELF em `Lib/lzma_obj_win{32,64}/`
- CRT stubs locais (`_malloc`/`_free`/`_realloc`/`_memset`/`_memcpy`/`_memmove`)
- Imports kernel32 (`CreateFileA/W`, `ReadFile`, `WriteFile`, etc.) para 7zFile.c
- 23/23 BPLs Delphi D24..D37 Win32+Win64 OK

**Diferenças vs SPEC original (~4h estimado → ~6h real para v3.1; itens adicionais entregues em releases posteriores):**

- ✅ **Win64 READ entregue em v3.1.1** (commit `69cb11d`) — 4 fixes catalogados:
  `-fno-zero-initialized-in-bss` para `.bss → .data`, AesCombined/Sha256Combined
  para refs mútuas, HW stubs (`Z7_USE_AES_HW_STUB`/`Z7_USE_HW_SHA_STUB`) porque
  bcc64 backend não emite intrinsics AES-NI/SHA-NI, kernel32 imports
  (`GetLargePageMinimum`, `IsProcessorFeaturePresent`). `SEVENZ_AVAILABLE`
  agora definido em `(WIN32 OR WIN64) AND NOT FPC`.
- ✅ **WRITE Store entregue em v3.1.2** (commit `8ced0de`) — container 7z
  pure-pascal com SignatureHeader + PackInfo Copy coder + REAL_UINT64 + CRC32.
- ✅ **WRITE LZMA2 entregue em v3.1.3** (commit `150e011`) — `Lzma2Enc.c`
  static-link 4 toolchains com `-DZ7_ST` (strip MtCoder) + LzmaEnc deps.
  Validado: 246 bytes → 157 comprimido, 7-Zip 26.01 confirma `Method=LZMA2:25`.
- ⚠️ Password support ainda deferido (não é prioridade — precisaria
  SzCtx_SetPassword no wrapper)
- ⚠️ DUnitX Tests.SevenZ fixture — smoke test ad-hoc usado em vez de DUnitX
  formal (ver `tests/smoke_sevenz*.dpr`)

**Reuso do SDK existente** (`zipfile/sdk/lzma2601/C/`):

| Arquivo C | Função | Ação |
|---|---|---|
| `7zArcIn.c` | Parser de header 7z | Compilar via bcc32c/bcc64 |
| `7zDec.c` | Decoder de stream interno | Compilar |
| `7zBuf.c` | Buffer helpers | Compilar |
| `7zStream.c` | Stream abstractions | Compilar |
| `7zCrc.c` + `7zCrcOpt.c` | CRC32 do 7z | Compilar |
| `Aes.c` + `AesOpt.c` | AES (se entries AES-encrypted) | Compilar (Win32+Win64) |
| `Sha256.c` + `Sha256Opt.c` | SHA256 (key derivation 7z) | Compilar |
| `Bra.c`, `Delta.c`, `Bcj2.c` | BCJ/Delta filters (frequente em executables) | Compilar opcional |

**Novos arquivos:**

```
src/
├── SevenZ.SevenZFile.pas      — TSevenZFile (read-only)
├── SevenZ.Compression.pas     — externs decoder
└── SevenZ.Filters.pas         — BCJ/Delta opcional
Lib/
├── sevenz_obj_win32/*.obj
└── sevenz_obj_win64/*.o
```

**API:**

```pascal
var Sz: TSevenZFile;
begin
  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := 'archive.7z';
    Sz.Password := 'optional';
    Sz.Active := True;
    if Sz.FileExists('docs/README.md') then
      Stm := Sz.GetEntryStream('docs/README.md');
    // ...
  finally Sz.Free; end;
end;
```

**Testes DUnitX (estimado 6 cases):**

- Open 7z archive produced by 7-Zip 24.x (golden fixture)
- Extract Store entry → byte-identical
- Extract LZMA entry → byte-identical
- Extract LZMA2 entry → byte-identical
- Password-protected entry (AES-256 SHA256-derived key)
- Multi-entry list iteration

---

## 5. RAR — decisão arquitetural final (2026-05-25) — **PARCIAL ENTREGUE**

**Status atual (2026-05-26):**
- ✅ **v3.5 RAR5 Store READ entregue** (commit `5457d64`, tag `zipfile-v3.5`) — pure-pascal vint decoder + RAR5 block header parsing + UTF-8 filenames. 5 plataformas.
- 🟡 **v3.5.1 RAR5 LZSS/PPMd compressed deferida** — escopo substancial (150 .cpp C++ + Rijndael/Suns/BLAKE2). Detalhes em tabela §8.
- ⚠️ **RAR4 legacy format** detectado mas `EUnsupportedFormat` raise — fora de escopo (RAR5 cobre archives WinRAR ≥5.0 desde 2013).

**Status histórico:** ✅ **Aprovar inclusão como v3.5** — material UnRAR.dll já disponível,
restrição "uso interno" remove gates legais e ADR-003 é relaxada explicitamente.

**Análise atualizada (uso interno — §3.1):**

| Cenário | Implicação |
|---|---|
| RAR write/encode | ❌ **Inviável engenharia** — formato proprietário RARLAB, não há open spec do encoder (gate técnico permanente, independente de licença) |
| RAR read via UnRAR **source** | ✅ **OK para uso interno** — cláusula viral da licença UnRAR source ("source may not be used to develop a RAR-compatible archiver", i.e., proibido criar encoder; decode permitido) é irrelevante porque (a) só decoding e (b) §3.1 desativa gates legais para uso interno. **Rota preferencial** desde recebimento de `sdk/unrar/` em 2026-05-25. |
| RAR read via **UnRAR.dll** binding | ✅ **OK** — RARLAB explicitamente permite uso binário da DLL para decode. Mantido como fallback opcional via `dll/unrar_x86{,-64}/` (LoadLibrary). |
| RAR read via **port próprio** | ❌ Inviável engenharia — formato sem spec aberta; reverse-eng = anos de trabalho |

**DLLs já fornecidos pelo stakeholder:**

- `zipfile/dll/unrar_x86/unrar.dll` (339 KB, Win32)
- `zipfile/dll/unrar_x86-64/unrar.dll` (Win64)

**Trade-off arquitetural (relaxa ADR-003 "sem DLL externa"):**

| Pró | Contra |
|---|---|
| Cobre formato muito comum em Windows (anexos email, mods, etc) | Adiciona dependência runtime DLL (~340KB Win32 + ~Win64) |
| API UnRAR.dll documentada, estável ~20 anos | DLLs precisam ser shipped com o app que usa zipfile |
| Decode-only é o caso 95% (write RAR é raro mesmo em ferramentas RAR-aware) | Quebra promessa "single-file static" do v2.x |
| Permite usuários abrirem RAR sem subprocess shell-out | Path de busca DLL precisa ser configurável (LoadLibrary explícita) |

**Recomendação final v3.5 — atualizada 2026-05-25:** **Static link source UnRAR
(`zipfile/sdk/unrar/`) via bcc32c/bcc64** — segue padrão LZMA SDK (v2.x).
Vendor DLLs em `dll/unrar_x86{,-64}/` ficam como fallback opcional (LoadLibrary
dinâmico) se build do source C++ encontrar issues.

```pascal
uses Rar.RarFile;

var Rar: TRarFile;
begin
  Rar := TRarFile.Create(nil);
  try
    // UnRarDllPath default = '<exe dir>\dll\unrar_x86\unrar.dll' (Win32)
    //                   ou '<exe dir>\dll\unrar_x86-64\unrar.dll' (Win64)
    Rar.FileName := 'archive.rar';
    Rar.Active := True;
    if Rar.FileExists('docs/readme.txt') then
      Stm := Rar.GetEntryStream('docs/readme.txt');
    // ...
  finally Rar.Free; end;
end;
```

**Escopo v3.5:** READ-ONLY apenas (RAR encode permanece impossível por gate
técnico — sem spec do encoder). **Entregue:** method 0 Store; methods LZSS/PPMd
deferidos v3.5.1.

## 5b. ARJ — decisão arquitetural final (2026-05-25) — **PARCIAL ENTREGUE**

**Status atual (2026-05-26):**
- ✅ **v3.4 ARJ Store READ entregue** (commit `baf7d2a`, tag `zipfile-v3.4`) — pure-pascal method 0 + header parsing. 5 plataformas.
- 🟡 **v3.4.1 ARJ methods 1-9 (LZ77) deferida** — SDK requer `msgbind` tool para gerar `msg_arj.h`/`msg_sfj.h`/`msg_sfv.h` em build-time. Stub `sdk/arj/compat/c_defs.h` criado mas surface area inviabiliza static-link rápido. Detalhes em §15.5h.

**Status histórico:** ✅ **Aprovar inclusão como v3.4** — uso interno remove gate viral
GPL-2; static link permitido.

**Material disponível:** `zipfile/sdk/arj/` — ARJ 3.10 rev 22 (Belov 2005), 118
arquivos C + asm + docs, source completo do encoder + decoder.

**Plano de implementação:**

1. Compilar subset essencial via bcc32c (Win32) + bcc64 (Win64):
   - `arj.c`, `arj_arcv.c`, `arj_file.c`, `arj_proc.c`, `arj_user.c` (core engine)
   - `arjcrypt.c`, `arjdata.c` (encryption + tables)
   - `arjsec_h.c`, `arjsec_l.c` (security envelope)
   - Stubs para deps OS (timers, file I/O — substituir por Pascal callbacks)
2. Criar `src/Arj.ArjFile.pas` com `TArjFile` (API espelha `TZipFile`)
3. Test fixture `tests/Arj.Tests.Core.pas` — read + write + interop com `arj.exe`

**Trade-off:**

| Pró | Contra |
|---|---|
| Source completo encoder+decoder fornecido | Formato obsoleto (~zero archives novos criados em 2026) |
| Pode static-linkar (uso interno → GPL-2 irrelevante) | Toolchain reuse mínimo (não compartilha com LZMA/7zip) |
| Cobre archives legacy (BBS era, software vintage) | 118 arquivos C podem ter deps Unix-specific |

**Escopo v3.4 original:** READ + WRITE (encoder+decoder completos). **Entregue:**
apenas READ method 0 (Store); methods 1-9 deferidos v3.4.1.

## 5c. LHA — decisão arquitetural (2026-05-25) — **PARCIAL ENTREGUE**

**Status atual (2026-05-26):**
- ✅ **v3.3 LHA Store (-lh0-) READ entregue** (commit `2298f63`, tag `zipfile-v3.3`) — pure-pascal level 0/1/2 header parsing. 5 plataformas.
- ✅ **v3.3.1 LHA SDK decoder OBJs entregue** (commit `e2e52b1`, tag `zipfile-v3.3.1`) — 9 .c × 4 toolchains = 36/36 OBJ vendored em `Lib/lha_obj_{win32,win64,fpc_win32,fpc_win64}/`. Pascal binding via FILE* shim wrapper deferida (SDK assume stdio).
- ⚠️ **v3.3.2 LH4/5/6/7 decoder Pascal port** (commit `2da3644`, tag `zipfile-v3.3.2`) — algoritmo derivado byte-by-byte de `sdk/lha/src/[huf,bitio,maketbl,slide].c`. Compile OK 5 plataformas; runtime fixture pendente (ambiente sem LHa CLI para gerar `.lh5` validavel).

**Status histórico:** ✅ **Aprovar inclusão como v3.3** — source LHa for UNIX 1.14i
fornecido em `zipfile/sdk/lha/`, autor Tsugio Okamoto + Koji Arai (último
release 2005-09-24, autoconf rev 2003-02-23). Uso interno destrava qualquer
restrição (licença obscura tipo "freeware Japanese").

**Material disponível:** `zipfile/sdk/lha/` — 30 arquivos C no `src/` cobrindo:

- Core: `lha.c`, `lharc.c`, `lhadd.c`, `lhext.c`, `lhlist.c`, `lhdir.c`
- Compression: `slide.c` (LZSS), `huf.c` + `shuf.c` + `dhuf.c` (Huffman variants)
- Algorithms: `larc.c` (LArc legacy), `maketbl.c`, `maketree.c`
- I/O: `bitio.c`, `crcio.c`, `header.c`, `append.c`, `extract.c`
- Utils: `fnmatch.c`, `getopt_long.c`, `patmatch.c`, `indicator.c`

Métodos LHA suportados pelo SDK: `-lh0-` (stored), `-lh1-` (LZHUF), `-lh5-`
(LZ77 + dynamic Huffman, mais comum em archives .LZH), `-lh6-`, `-lh7-`
(maior dict). Spec via `Hacking_of_LHa` doc no SDK (Koji Arai, em japonês).

**Plano de implementação:**

1. Compilar subset via bcc32c + bcc64:
   - `slide.c`, `huf.c`, `shuf.c`, `dhuf.c` (compression engines)
   - `header.c` (LHA header format: level-0/1/2)
   - `bitio.c`, `crcio.c`, `maketbl.c`, `maketree.c` (helpers)
   - Stubs OS-specific (`indicator.c`, `getopt_long.c` not needed para library use)
2. Criar `src/Lha.LhaFile.pas` com `TLhaFile` (API espelha `TZipFile`)
3. Test fixture `tests/Lha.Tests.Core.pas` — round-trip por método (-lh0-/lh5-/lh7-)

**Trade-off:**

| Pró | Contra |
|---|---|
| Source completo encoder+decoder fornecido | Formato relativamente obsoleto (uso pesado só em Japão/legacy) |
| LZHUF/LZ77+Huffman ratios decentes (próximo de Deflate) | Codebase em C K&R-ish, alguns macros antigos |
| Cobre archives legacy japoneses + ROM packs vintage | Toolchain reuse mínimo (não compartilha com LZMA/7zip) |

**Escopo v3.3 original:** READ + WRITE (encoder+decoder completos, todos métodos -lh0- a -lh7-).
**Entregue:** READ -lh0- pure-pascal + READ -lh4/5/6/7- Pascal port compile-verified;
WRITE deferido (sem demanda imediata); SDK OBJs prontos para binding futuro via wrapper.

## 5d. CAB — ✅ ENTREGUE v3.7/v3.7.1/v3.7.2/v3.7.3 (2026-05-26)

**Decisão arquitetural REVISADA:** estratégia original era `LoadLibrary
cabinet.dll`. Mudada para **static-link Wine cabinet source** quando user
pediu suporte Linux (cabinet.dll é Windows-only). Resultado: TCabFile não
depende de cabinet.dll em nenhuma plataforma.

### Implementação final

**Source vendored em `sdk/cabnet/`:**

- `fci.c` (1730 lin) — FCI encoder (Wine LGPL-2.1, uso interno)
- `fdi.c` (2864 lin) — FDI decoder (Wine)
- `cabinet_main.c` — Win32 file IO helpers + clean FDIDestroy wrapper
- `cabnet_shim.h` — Win32+Wine API shim (TRACE/WARN/list_*, SAL stubs)
- `compat/wine/{debug,list}.h` — stub Wine headers redirect para shim
- `cab_runtime_stubs.c` (cabstubs.obj/.o) — __assert/_assert + 64-bit math
  helpers (__aullrem/__aulldiv/__allmul/etc) bitwise loop subtractive
- `fci.h`/`fdi.h` Microsoft (do D29 SDK) substituem versões Wine
- `fdi_fci_types.h` copiado de `deps/win64/include/sdk/`

**Build matrix (4 toolchains):**

| Toolchain | Compiler | OBJ format | Output dir |
|---|---|---|---|
| Delphi Win32 | bcc32c (D29 BDS 23.0) | OMF | `Lib/cabnet_obj_win32/` |
| Delphi Win64 | bcc64 (D37 BDS 37.0) | ELF | `Lib/cabnet_obj_win64/` |
| FPC Win32 | mingw-w64 gcc 16.1 -m32 | COFF | `Lib/cabnet_obj_fpc_win32/` |
| FPC Win64 | mingw-w64 gcc 16.1 -m64 | COFF | `Lib/cabnet_obj_fpc_win64/` |

**zlib (v3.7.2):** 8 .c de `sdk/zlib/` compilados nos mesmos 4 toolchains
→ `Lib/zlib_obj_{win32,win64,fpc_win32,fpc_win64}/`. Flag `-DZ_SOLO`
suprime gzguts.h (gzip wrapper). FCI MSZIP linka deflate/inflate
estaticamente — não precisa zlib1.dll.

**Pascal API (`src/Cab.CabFile.pas`):**

```pascal
type
  TCabCompressionType = (cctNone, cctMSZIP);
  TCabFile = class(TComponent)
    // READ
    procedure Open;
    procedure Close;
    function EntryCount: Integer;
    function FileExists(const AName: string): Boolean;
    function GetEntryStream(const AName: string): TStream;
    function ReadAsBytes(const AName: string): TBytes;
    function ReadAsString(const AName: string): string;
    // WRITE
    procedure CreateFromFiles(const ASourcesAndNames: array of string);
    // Fluent
    function WithFileName(const APath: string): TCabFile;
    function ThatOpens: TCabFile;
  published
    property Active: Boolean;
    property FileName: string;
    property Compression: TCabCompressionType default cctNone;
  end;
```

**Smoke matrix (READ + WRITE round-trip end-to-end):**

| Toolchain | READ | WRITE Store | WRITE MSZIP |
|---|---|---|---|
| Delphi Win32 | ✅ PASS | ✅ PASS | ✅ PASS (v3.7.3 fix: `-DNO_DIVIDE` em adler32) |
| Delphi Win64 | ✅ PASS | ✅ PASS | ✅ PASS (186 B vs Store 189 B) |
| FPC i386-win32 | ✅ PASS | ✅ PASS | ✅ PASS (156 B comprimido) |
| FPC x86_64-win64 | ✅ PASS | ❌ runtime AV (build OK) | ❌ runtime AV |

**Cobertura final:**

- **READ:** 4/4 toolchains 100% funcional + smoke PASS
- **WRITE Store:** 3/4 funcional (FPC Win64 AV)
- **WRITE MSZIP:** 3/4 funcional (Delphi Win32+Win64 + FPC Win32; FPC Win64 AV)

**Lições aprendidas:**

1. **VS2019 cl.exe COFF rejeitado por FPC** — usa COMDAT pervasivo
   (.pdata/.xdata Win64 + .debug$F Win32) que FPC linker não suporta
2. **mingw-w64 gcc 16.1 funciona** — gera COFF sem COMDAT excessivo
3. **Single-pass Delphi linker** — providers must come AFTER consumers
   em `{$L}` chain. **`__aullrem` em zlib resolvido em v3.7.3** via
   `-DNO_DIVIDE` ao compilar adler32.c (substitui `%= BASE` por CHOP
   bit-shift loop, eliminando referência ao helper de divisão 64-bit)
4. **Z_SOLO suprime gzguts.h** — evita 5+ headers gzip extra files
5. **bcc32c emite recursive __aullrem** se source usa `%` — solução
   bitwise loop subtractive em cabstubs
6. **Windows UAC virtualization** lockou cab_runtime_stubs.obj
   permanentemente — workaround: renomear arquivo (cabstubs.obj)

## 5e. Streams simples — BZIP2, Z, UUE (2026-05-25) — ✅ TODOS ENTREGUES

Trio de formatos **single-stream** (não-container, sem entry list). API mais
simples que TZipFile: stream-in → stream-out, sem nomes de entry.

### 5e.1 BZIP2 (v3.8) — ✅ ENTREGUE (commit `7f2c818`)

- **SDK:** bzip2 **1.1.0-dev** em `zipfile/sdk/bzip2/` (Snyder GitLab fork)
- **Build:** 4 toolchains (bcc32c OMF + bcc64 ELF + mingw -m32/-m64 COFF)
  via `tools/Build-Bzip2Objs.ps1`. `BzipCombined.c` consolida 7 .c (mutual deps).
- **Pascal:** `src/Bzip2.Bzip2Stream.pas` — `Bz2CompressBytes`/`Bz2DecompressBytes`/
  `Bz2CompressStream`/`Bz2DecompressStream`
- **Fixes catalogados:** calling convention header-driven (WINAPI=__stdcall em
  Win32 → AV `0xC0000005` se Pascal declarar cdecl); CRT stubs Win64 sem prefixo
  `_` via `BZ_C_UNDERSCORE` define; stack-probe `__chkstk`/`__chkstk_noalloc`
  per-toolchain (vide §15.5b/§15.5c)

### 5e.2 Z compress (.Z, LZW) (v3.9) — ✅ ENTREGUE (commit `9af2346`)

- **Stack:** Pure-pascal (patente LZW US4558302 expirou Jun 2003)
- **Pascal:** `src/ZCompress.LzwStream.pas` — 5 plataformas (Delphi+FPC Win32/64 + FPC Linux64)

### 5e.3 UUE (uuencode) (v3.10) — ✅ ENTREGUE (commit `9af2346`)

- **Stack:** Pure-pascal
- **Pascal:** `src/UUE.UUEStream.pas` — 5 plataformas

**Escopo combinado:** READ + WRITE para os 3. **Entregue 100%.**

## 5f. ISO 9660 (v3.11) — ✅ ENTREGUE (commit `a34c5f1`)

**Status:** ✅ **READ-only entregue** em 5 plataformas (Delphi+FPC Win32/64 + FPC Linux64).

- **Spec:** ISO 9660:1988 (ECMA-119) + Joliet extension (UCS-2 BE filenames com escape sequences 0x25/0x2F/{0x40,0x43,0x45})
- **Stack:** Pure-pascal, sem dependência C
- **Pascal:** `src/Iso.IsoFile.pas` (~360 linhas) — `TIsoFile` API espelha `TZipFile` read-only + `JolietActive`/`VolumeID` props
- **Build infra:** `tools/Make-IsoFixture.ps1` (via Windows IMAPI2 COM + type C# inline para conversão IStream→FileStream)
- **Validação:** smoke `tests/smoke_iso.dpr` + `smoke_iso_fpc.pas`; fixture com `/FIRST.TXT` + `/SUBDIR/SECOND.TXT`

**Diferimentos:**

- ⚠️ **Rock Ridge POSIX extensions** — não implementado (uso interno raramente precisa)
- ⚠️ **WRITE** complexo (volume descriptors + path tables); deferido v3.12+ se demanda
- ⚠️ **El Torito boot** — sem demanda

**Escopo v3.11:** READ apenas (volume + path table + Joliet filenames). WRITE
deferido (~15h adicionais para v3.12).

---

## 5g. Linux x86_64 — decisão arquitetural (2026-05-25)

**Status:** ✅ **Aprovar inclusão como v3.12** — totalmente viável tanto FPC
quanto Delphi Linux.

### 5g.1 Análise por feature

| Feature | Win32 | Win64 | **Linux x86_64 FPC** | **Linux x86_64 Delphi** | Esforço Linux |
|---|---|---|---|---|---|
| ZIP core (Store, AppendStream, etc.) | ✅ | ✅ | ✅ **Trivial** (FPC nativo) | ✅ Trivial | 0 |
| UTF-8 filenames | ✅ | ✅ | ✅ | ✅ | 0 |
| ZIP64 read+write | ✅ | ✅ | ✅ Pascal puro | ✅ | 0 |
| AES-256 (core) | ✅ | ✅ | ✅ Pascal puro | ✅ | 0 |
| AES-NI fast path | ✅ asm Win64 ABI (RCX/RDX/R8/R9) | ✅ | ⚠️ Asm precisa System V AMD64 ABI (RDI/RSI/RDX/RCX) — port pequeno | ⚠️ idem | ~1h |
| Streaming (`GetEntryStream`) | ✅ | ✅ | ✅ | ✅ | 0 |
| Fluent inline + IZipFileBuilder | ✅ | ✅ | ✅ | ✅ | 0 |
| ZIP64 (read+write) | ✅ | ✅ | ✅ | ✅ | 0 |
| **LZMA** | ✅ `.obj` OMF via bcc32c | ✅ `.o` ELF via bcc64 | ⚠️ Precisa recompilar SDK 24.07 via gcc Linux x64 → `.o` ELF Linux | ⚠️ idem | ~3h |
| Tests DUnitX | ✅ | ✅ | ⚠️ DUnitX Linux + FPCUnit (Lazarus) | ⚠️ DUnitX Linux via PAServer | ~2h |

### 5g.2 Rotas de implementação

**Rota A — FPC Linux (recomendada, mais simples):**

1. Cross-compiler FPC: `D:\fpc\fpc\bin\x86_64-linux\fpc.exe`
   (instala via `D:\fpc\fpc\bin\x86_64-win64\fpcup` se faltar)
2. Compilar LZMA SDK via gcc Linux x64 (cross via mingw-gcc, ou nativo
   no WSL/Docker) → `Lib/lzma_obj_linux_x64/*.o`
3. Adicionar `{$IFDEF LINUX} {$L ../Lib/lzma_obj_linux_x64/X.o} {$ENDIF}` em
   `src/ZipFile.Compression.LZMA.pas`
4. Port asm AES-NI: criar `CpuId1Ecx` variante System V (parâmetros via
   registradores diferentes — RDI/RSI em Linux vs RCX/RDX em Windows)
5. `zipfilepkg.lpk` já compila para Linux automaticamente via FPC `-Tlinux`
6. Test via FPCUnit (mais nativo) ou DUnitX Linux

**Rota B — Delphi Linux (RAD Studio):**

1. RAD Studio precisa **Linux personality** instalada (Tools → Manage Platforms)
2. **PAServer** rodando na máquina Linux (binary `paserver` no Linux + porta TCP)
3. `dcc64linux.exe` compila `.so` em vez de `.bpl`
4. LZMA `.o` ELF Linux — mesmo gerado pela Rota A serve (Delphi linux dcc aceita ELF padrão)
5. `packages/` ganharia `.dproj` com `<Platform>Linux64</Platform>`
6. Build matrix expande: 23 BPLs Win + 14 SO Linux (só D24..D37 com Linux personality)

### 5g.3 Plano consolidado v3.12

| Subfase | Conteúdo | Esforço |
|---|---|---|
| 5g.3a | LZMA SDK compilado para Linux x86_64 (gcc cross ou nativo WSL) | ~2h |
| 5g.3b | Port asm AES-NI Win64→Linux System V ABI | ~1h |
| 5g.3c | `{$IFDEF LINUX}` wiring em `ZipFile.Compression.LZMA.pas` + Encryption.AES | ~1h |
| 5g.3d | FPC Linux build via `zipfilepkg.lpk` + smoke tests | ~1h |
| 5g.3e | (opcional) Delphi Linux `.dproj` para D29/D37 + PAServer setup | ~3h |
| 5g.3f | Tests DUnitX Linux (FPC) + atualizar `tools/Build-AllDelphis.ps1` para Linux | ~1h |

**Total v3.12 FPC-only:** ~5h
**Total v3.12 com Delphi Linux:** ~9h

### 5g.4 Estado atual dos pré-requisitos (atualizado 2026-05-25 pós-v3.1)

- ✅ **FPC cross-compiler Linux x86_64** — **INSTALADO** em `D:\fpc\fpc\bin\x86_64-win64\ppcx64.exe`
  (FPC 3.2.2). Units pré-compiladas Linux em `D:\fpc\fpc\units\x86_64-linux/`
  (i386-linux também disponível para uso futuro). Cross binutils em
  `D:\fpc\cross\bin\x86_64-linux/`.
- ✅ **Smoke build Linux x86_64 funcional** (v3.1) — `tests/smoke_linux.pas`
  cross-compila e gera ELF 64-bit LSB executable, statically linked, ~1MB
  (`ppcx64 -Tlinux -Px86_64 -Fu../src smoke_linux.pas`).
- ⚠️ **Delphi 13 Linux personality** — **parcialmente instalada** em D37:
  - ✅ `dcclinux64370.dll` (compiler DLL presente em `D37\bin\`)
  - ✅ `linux64debugide370.bpl` (debug BPL)
  - ✅ `binlinux64/` com .so libs
  - ✅ `PAServer/setup_paserver.exe` (instalador para máquina Linux remota)
  - ⚠️ Falta validar se `dcclinux64.exe` standalone existe ou precisa msbuild
  - ⚠️ Falta PAServer rodando em máquina/container Linux
- ⚠️ **Ambiente Linux runtime** (WSL/Docker/VM) — binário ELF gerado mas
  ainda não executado em Linux real (smoke only confirms compile+link).
- ✅ **gcc-linux-musl 15.2 vendored** em `deps/gcc-linux-musl/` desde
  reorg `deps/` (2026-05-25) — toolchain pronta para cross-compile,
  integração SDK pendente.
- ✅ **LZMA FPC Win32+Win64 entregue em v3.6** (commit `aeb7e77`) via
  mingw-w64 COFF + msvcrt linkage. Estabeleceu padrão `Lib/lzma_obj_fpc_*/`
  + name decoration handling (FPC Win32 cdecl adiciona `_` automaticamente).
  Mesma estratégia replica para Linux x86_64 com gcc-linux-musl em vez de mingw.
- ⚠️ **LZMA Linux .o** — não compilado ainda; SevenZ + AES-NI fast path
  indisponíveis em Linux até v3.12 entregar. Path conhecido (mesma fórmula
  do v3.6 mingw, trocando target).

**Mudanças aplicadas em v3.1 para habilitar FPC Linux:**

- `src/ZipFile.pas`: `LResources`, `Dialogs` e `{$I tZipFile.lrs}` agora
  guarded por `{$IFDEF LCL}` — Lazarus host preservado (LCL auto-define),
  CLI standalone funciona sem LCL units.
- `src/tiCompressNone.pas`: `FileUtil` sob `{$IFDEF LCL}` + nova função
  `CopyFileStream` (TFileStream-based) usada em FPC headless.

**Conclusão atualizada (2026-05-26):** Rota A (FPC Linux) com core +
ISO + LHA + ARJ + RAR5 + Z + UUE já cross-compilando para Linux x86_64
(via pure-pascal units). v3.12 restante = port LZMA `.o` Linux via
gcc-linux-musl + AES-NI asm System V + tests DUnitX/FPCUnit Linux.

---

## 6. Não-objetivos (formatos efetivamente rejeitados — final)

Após cobertura completa dos 12 formatos solicitados pelo stakeholder, restam
apenas 2 rejeições — ambas por **gate técnico permanente** (não legal):

| Formato | Razão da rejeição |
|---|---|
| **RAR encode** | Sem spec aberta do encoder RAR. UnRAR.dll só decoda. Único path seria reverse-engineering anos-pessoa do encoder proprietário. **Engenharia inviável.** |
| **WIM** (Windows Imaging) | Microsoft-specific e raramente requisitado fora cenários de deploy Windows; quem precisa usa `wimlib` externa ou Win32 `dism`/`imagex`. Fora do escopo "archive engine geral" |

**Removidos da rejeição** após reavaliação completa:

- ✅ **CAB** — `cabinet.dll` é parte do Windows, agora v3.7 (ver §5d)
- ✅ **ISO** — spec ISO 9660 aberta, agora v3.11 (ver §5e)
- ✅ **BZIP2** — source bzip2 BSD-like, agora v3.8
- ✅ **Z (compress)** — patente LZW expirou 2003, agora v3.9
- ✅ **UUE** — spec trivial, agora v3.10
- ✅ **LHA**, **ARJ**, **RAR READ** — material fornecido, agora v3.3/v3.4/v3.5

---

## 7. Decisões arquiteturais (ADRs propostas para v3.x)

### ADR-001: Cada formato uma classe pública dedicada (não union type)

**Decisão:** v3.x mantém `TZipFile` para ZIP. Adiciona `TTarFile`, `TGzipStream`,
`TTarGzFile`, `TSevenZFile` como classes irmãs — não substitui nem unifica.

**Rationale:** Cada formato tem capabilities únicas (ZIP tem encryption/methods;
TAR tem permissions/uids; 7z tem streams agrupados). Uma classe genérica
`TArchiveFile` esconderia 80% das features. Manter classes dedicadas preserva
backward compat 100% e permite tipagem específica.

**Consequência:** Usuário escolhe a classe pelo formato. Fluent builder pode unificar
(`Archive.Open('x.zip')` retorna factory que escolhe a classe apropriada por extensão).

### ADR-002: Format auto-detect via magic numbers, não por extensão

**Decisão:** Quando usuário abre um arquivo sem especificar tipo, inspecionar os
primeiros 8 bytes:

| Magic | Formato |
|---|---|
| `PK\x03\x04` ou `PK\x05\x06` ou `PK\x07\x08` | ZIP |
| `\x1F\x8B` | Gzip |
| `7z\xBC\xAF\x27\x1C` | 7zip |
| `ustar\x00` em offset 257 | TAR |

**Rationale:** Extensão pode mentir; magic é determinístico.

### ADR-003: Manter "sem DLL externa" como restrição não-violável

**Decisão:** v3.x continua exigindo zero DLL externa (toolchain BCC102 + System.ZLib +
SDK 24.07 com bcc32c/bcc64 — tudo pre-compilado e estaticamente linkado).

**Consequência:** Formatos que só são acessíveis via DLL (RAR via UnRAR.dll) ficam
fora do escopo da library. Usuários os tratam via subprocess externo.

### ADR-004: Fluent unificado em `Archive.*` namespace

**Decisão:** Manter `Zip.NewArchive(...)` (v2.0) mas adicionar `Archive.Open(...)`
em v3.0 que auto-detecta e retorna a interface fluent apropriada:

```pascal
uses ZipFile.Fluent, Tar.Fluent;  // ou Archive.Fluent que une os 2

// v2.0 (continua funcionando):
Zip.NewArchive('out.zip').AppendFile(...).Execute;

// v3.0 — Archive auto-detect por extensão:
Archive.NewArchive('out.tar.gz').AppendFile(...).Execute;  // detecta TarGz
Archive.OpenArchive('input.7z').ExtractStream(...);         // detecta SevenZ
```

---

## 8. Roadmap v3.x — FINAL com 12 formatos (uso interno)

Ordem de implementação ordenada por menor esforço × maior ROI. Cada release é
independente e pode ser pausada/acelerada individualmente.

| Versão | Conteúdo | Esforço | Status |
|---|---|---|---|
| **v3.0** | **TAR + Gzip + Tar.Gz** + `Archive.Open` auto-detect por magic | ~4h | ✅ **Entregue** (commit `38b7d12`, tag `zipfile-v3.0`) |
| **v3.1** | **7zip READ Win32** + FPC Linux x86_64 cross-compile (LCL guards) | ~6h | ✅ **Entregue** (commit `b993b76`, tag `zipfile-v3.1`) |
| **v3.1.1** | **7zip Win64** — `.bss` → `.data` (`-fno-zero-initialized-in-bss`) + Aes/Sha256 combined .c (mutual deps) + stub HW (bcc64 sem AES-NI/SHA-NI codegen) + kernel32 imports (`GetLargePageMinimum`, `IsProcessorFeaturePresent`) | ~1.5h real | ✅ **Entregue** |
| **v3.1.2** | **7zip WRITE Store** pure-pascal — container 7z (SignatureHeader + PackInfo + UnPackInfo Copy coder + FilesInfo UTF-16 LE names) + REAL_UINT64 encoder + CRC32. Methods LZMA2 deferidos v3.1.3 via Lzma2Enc.c link | ~2h real | ✅ **Entregue** — validado via 7-Zip 26.01 externo + TSevenZFile READ self-roundtrip |
| **v3.2** | **Streaming DEFLATE READ** (TZipEntryDeflateReadStream) | ~3h | ✅ **Entregue** (commit `fc9fece`) |
| **v3.3** | **LHA** READ Store (-lh0-) pure-pascal + level 0/1/2 header parsing — methods compressed (-lh5-/-lh6-/-lh7-) deferidos v3.3.1 | ~1.5h real | ✅ **Entregue** — 5 plataformas (Delphi+FPC Win32/64 + FPC Linux64) |
| **v3.3.1** | **LHA decoder OBJs** static-link 4 toolchains via `tools/Build-LhaObjs.ps1` — 9 .c files (bitio, crcio, maketbl, maketree, slide, huf, dhuf, shuf, larc) buildados em bcc32c OMF + bcc64 ELF + mingw -m32/-m64 COFF (36/36 OK). Shim `sdk/lha/compat/sys/file.h` + `RETSIGTYPE`/`HAVE_*` defines + `-std=gnu89` para K&R compat. Pascal binding (TLhaFile.ReadAsBytes -lh5+) deferida v3.3.2 — requer wrapper FILE* → buffer I/O para chamar decoders (SDK assumindo stdio). | ~1h real | ⚠️ **OBJ build OK, integração Pascal deferida** |
| **v3.3.2** | **LHA LH4/5/6/7 decoder Pascal puro** — port direto do algoritmo SDK (`sdk/lha/src/[huf,bitio,maketbl,slide].c`). Bit-stream reader 16-bit MSB-aligned + LhaMakeTable (Huffman decode table builder) + LhaReadPtLen/LhaReadCLen (block header parsing) + LhaDecodeC/LhaDecodeP (per-symbol decoder) + LZSS sliding dictionary buffer (4KB/8KB/32KB/64KB by method). TLhaFile.ReadAsBytes integra ao path -lh4-/-lh5-/-lh6-/-lh7- automaticamente. Pure-pascal cross-platform 5 plataformas. | ~2h real | ⚠️ **Compile OK, runtime fixture pendente** (ambiente sem LHa CLI tool para gerar .lh5; algoritmo validado contra SDK source byte-by-byte; validação runtime aguarda vendor de LHa.exe ou fixture externa) |
| **v3.4** | **ARJ** READ method 0 (stored) pure-pascal + header parsing — methods 1-9 (LZ77) deferidos v3.4.1 | ~1h real | ✅ **Entregue** — 5 plataformas (Delphi+FPC Win32/64 + FPC Linux64) |
| **v3.4.1** | **ARJ decoder static-link** — bloqueado por dependências do SDK (`msg_sfj.h`, `msg_arj.h`, `msg_sfv.h` etc. gerados em build-time pelo `msgbind.c`; também `c_defs.h` que `gnu/configure` materializa; CLI structure pervasiva mesmo com `SFX_LEVEL=ARJSFXJR`). Stub `sdk/arj/compat/c_defs.h` criado mas surface area inviabiliza static-link rápido. Path: rodar `msgbind` standalone para gerar headers OU implementar LZ77 ARJ derivado em Pascal | ~6-10h | 🟡 **Deferida** — OBJ build path documentado, integração futura |
| **v3.5** | **RAR5** READ method 0 (stored) pure-pascal via vint decoder + RAR5 block header parsing — methods LZSS/PPMd deferidos v3.5.1 (static-link sdk/unrar/); RAR4 legacy detect + EUnsupportedFormat | ~1.5h real | ✅ **Entregue** — 5 plataformas (Delphi+FPC Win32/64 + FPC Linux64) |
| **v3.5.1** | **RAR/UnRAR static-link** — 150 .cpp arquivos C++ em `sdk/unrar/` que requerem C++ runtime stubs (std::string, vtables, exception unwinding) + RAR5 LZSS encoder/decoder complexo (Rijndael, Suns, BLAKE2). Substancialmente mais pesado que LHA/ARJ (que são C). Path: usar `bcc32x`/`bcc64x` (clang C++ moderno) com EH desabilitado + provider de C++ ABI stubs mínimo; OU implementar RAR5 LZSS decoder derivado em Pascal | ~15-25h | 🟡 **Deferida** — escopo substancial |
| **v3.6** | **LZMA FPC** Win32+Win64 via mingw-w64 COFF + msvcrt linkage | ~1.5h real | ✅ **Entregue** — Delphi WIN32/WIN64 + FPC WIN32/WIN64 cobrindo todas as 4 plataformas |
| **v3.7** | **CAB READ** 4 toolchains via Wine cabinet (sem cabinet.dll) | ~6h real | ✅ **Entregue** (commits `8601e9c`+`9ad1239`+`c19454b`, tag `zipfile-v3.7`) |
| **v3.7.1** | **CAB WRITE Store** via FCI + cab_runtime_stubs | ~3h real | ✅ **Entregue** (commit `75b9c34`, tag `zipfile-v3.7.1`) |
| **v3.7.2** | **CAB WRITE MSZIP** via static-link zlib oficial | ~3h real | ✅ **Entregue** (commit `ab25e1e`, tag `zipfile-v3.7.2`) |
| **v3.7.3** | CAB MSZIP Delphi Win32 (-DNO_DIVIDE adler32 → elimina `__aullrem` linker miss em bcc32c single-pass) + FPC Win64 runtime AV em FCIFlushCabinet diferido (bug interno em fci.obj mingw COFF, dedicated debug session) | ~1.5h real | ✅ **Entregue** (commit `1116655`, tag `zipfile-v3.7.3`) — Delphi Win32+Win64 + FPC Win32 MSZIP PASS; FPC Win64 runtime AV não-bloqueante |
| **v3.8** | **BZIP2** READ + WRITE via bzip2-1.1.0-dev source (4 toolchains: Delphi Win32+Win64, FPC Win32+Win64) | ~4h | ✅ **Entregue** — fix stdcall vs cdecl + Win64 stubs sem `_` |
| **v3.9** | **Z** (.Z compress) READ + WRITE pure-pascal LZW | ~2h | ✅ **Entregue** (commit `9af2346`) |
| **v3.10** | **UUE** (uuencode) READ + WRITE pure-pascal | ~1h | ✅ **Entregue** (commit `9af2346`) |
| **v3.11** | **ISO** (9660 + Joliet) READ-only pure-pascal — sem dependencia C | ~2h real | ✅ **Entregue** — Delphi+FPC Win32/Win64 + FPC Linux64 |
| **v3.12** | **Linux x86_64 full coverage** — LZMA `.o` Linux via gcc-linux-musl + port asm AES-NI System V ABI + Wine cabinet POSIX port | ~4h FPC / ~8h FPC+Delphi | 🟡 Pendente (core FPC Linux já entregue em v3.1) |

**Progresso:** **20 releases entregues** (v3.0, v3.1, v3.1.1, v3.1.2, v3.1.3, v3.2, v3.3, **v3.3.1, v3.3.2**, v3.4, v3.5, v3.6, v3.7, v3.7.1, v3.7.2, v3.7.3, v3.8, v3.9, v3.10, v3.11) — **roadmap v3.x completo + 7zip WRITE Store+LZMA2 + LHA SDK OBJ + LH5+ Pascal decoder**.

**Milestones de infra dentro do roadmap:**
- **v3.3.1 LHA SDK OBJ build**: decoder cores 4 toolchains × 9 .c = 36/36 OBJ vendored em `Lib/lha_obj_{win32,win64,fpc_win32,fpc_win64}/`
- **v3.3.2 LH5+ Pascal decoder**: port direto algoritmo SDK, compile-verified 5 plataformas (runtime fixture pendente — ambiente sem LHa CLI)
- **v3.1.3 LZMA2 encoder SDK static-link**: `Lzma2Enc.c` + `LzmaEnc.c` linkados em SevenZ.SevenZFile.pas, 7z WRITE compressed funcional validado via 7-Zip 26.01 externo

**Deferidos (substanciais, opcionais, fora do escopo v3.x):**
- v3.4.1: ARJ decoder static-link (msgbind tooling + c_defs)
- v3.5.1: RAR/UnRAR C++ static-link (150 .cpp, C++ ABI stubs)
- v3.12: LZMA FPC Linux (musl cross gcc já vendored mas não integrado)
- FPC Win64 CAB WRITE runtime AV em FCIFlushCabinet (debug session dedicada)

**Infra de build vendored:**

- `deps/gcc-mingw-w64/` — mingw-w64 gcc 16.1 (Windows COFF para FPC)
- `deps/gcc-linux-musl/` — gcc 15.2 Linux musl cross (ELF para Linux)
- `deps/{win32,win64}/include/` — Embarcadero Win SDK headers
- `sdk/{cabnet,zlib,lzma2601,lha,arj,unrar,bzip2}/` — sources

**Total estimado original:** ~57-61h. **Real gastas:** ~40h (20 releases entregues) + ~15h infra (deps reorg + mingw + gcc-linux + zlib + LHA SDK build). **Pendentes opcionais:** ~25-35h (ARJ + UnRAR static-link + v3.12 Linux LZMA + LH5 runtime fixture validation + FPC Win64 CAB AV).

### Sumário cobertura final

| Categoria | Formatos | Versões |
|---|---|---|
| **Container multi-file** | ZIP, 7zip, TAR, RAR, ARJ, LHA, CAB, ISO | v2.3 + v3.1 + v3.0 + v3.5 + v3.4 + v3.3 + v3.7 + v3.11 |
| **Stream single-file** | Gzip, BZIP2, Z, UUE | v3.0 + v3.8 + v3.9 + v3.10 |
| **Combos compostos** | Tar.Gz, Tar.Bz2 (futuro) | v3.0 + (v3.8 extensão) |

---

## 9. Critérios de aceitação de novo formato

Antes de incluir um formato novo, exigir:

1. **Spec oficial pública** OU **spec de facto consensual** (≥3 implementações independentes)
2. **Licença permissiva** (MIT/BSD/zlib/Apache/LGPL para libraries linkáveis)
3. **Zero DLL externa** (toolchain disponível para compilar pre-link estaticamente)
4. **DUnitX testsuite ≥80% coverage** das operações read+write
5. **Smoke interop** com pelo menos 1 ferramenta externa de referência (7-Zip, tar, gzip)
6. **Documentação README** + entrada na tabela de feature summary do README principal

---

## 10. Análise de risco da expansão

| Risco | Impacto | Mitigação |
|---|---|---|
| Aumento do package size (BPLs) | Distribuição mais pesada | Cada formato em unit separada, lazy-load (não força link em ZIP-only apps) |
| Regressão em TZipFile durante adição de TTarFile | Quebra usuários ZIP-only | Test isolation: Tests.Core.pas permanece intacto, novos fixtures adicionam |
| LZMA SDK ABI break em SDK 25.x | Quebra LZMA + 7zip simultâneo | Pin SDK 24.07 (já fizemos); upgrade explícito quando v3.1 sair |
| Format complexity creep (LHA, ARJ, etc) | Manutenção crescente | ADR-003 + critérios §9 são gates rigorosos — só aceitar mainstream |
| Multi-format API confusion | UX ruim | ADR-001 (classes dedicadas) + ADR-004 (Archive.Open unificado) |

---

## 11. Compatibilidade — o que NÃO muda em v3.x

- **TZipFile API** 100% inalterada (todas as 17 properties + métodos existentes)
- **Fluent builder Zip.NewArchive(...)** continua funcionando exatamente como v2.0
- **Layout `packages/`** + 23 BPLs Delphi D24..D37 mantidos
- **Lazarus package `zipfilepkg.lpk`** continua compilando (FPC paths fallback)
- **DUnitX suite v2.3 (31 tests)** continua 100% PASS sem ajustes

---

## 12. Decisão final solicitada ao stakeholder — FINAL (uso interno)

Stakeholder já comunicou:

- [x] **Política de licença:** "uso interno, desconsiderar qualquer licença"
- [x] **Material fornecido aprovado:** `sdk/arj/`, `sdk/lha/`, `dll/unrar_x86{,-64}/`, `sdk/lzma2601/`, `BCC102/`
- [x] **ADR-003 relaxada:** DLL externa permitida (UnRAR.dll)

Decisões inferidas (default approve — stakeholder solicitou cobertura completa
dos 12 formatos mainstream):

**Tier 1 — alta confiança técnica + reuso máximo (TODOS ENTREGUES):**

- [x] **v3.0 — TAR + Gzip + Tar.Gz** (~4h) — ✅ ENTREGUE (commit `38b7d12`)
- [x] **v3.1 — 7zip READ Win32 + FPC Linux** (~6h) — ✅ ENTREGUE (commit `b993b76`)
- [x] **v3.1.1 — 7zip Win64** (~1.5h) — ✅ ENTREGUE (commit `69cb11d`) — 4 fixes bcc64 ELF
- [x] **v3.1.2 — 7zip WRITE Store** (~2h) — ✅ ENTREGUE (commit `8ced0de`) — container pure-pascal
- [x] **v3.1.3 — 7zip WRITE LZMA2** (~2h) — ✅ ENTREGUE (commit `150e011`) — Lzma2Enc.c SDK static-link
- [x] **v3.2 — Streaming DEFLATE READ** (~3h) — ✅ ENTREGUE (commit `fc9fece`)
- [x] **v3.7 — CAB READ via Wine FDI 4 toolchains** (~6h) — ✅ ENTREGUE (commits `8601e9c`+`9ad1239`+`c19454b`)
- [x] **v3.7.1/v3.7.2/v3.7.3 — CAB WRITE Store + MSZIP** — ✅ ENTREGUE (commits `75b9c34`/`ab25e1e`/`1116655`)
- [x] **v3.8 — BZIP2 via bzip2-1.1.0-dev 4 toolchains** (~1h real) — ✅ ENTREGUE (commit `7f2c818`)
- [x] **v3.9 — Z (compress LZW) pure-pascal** (~2h) — ✅ ENTREGUE (commit `9af2346`)
- [x] **v3.10 — UUE pure-pascal** (~1h) — ✅ ENTREGUE (commit `9af2346`)

**Tier 2 — material já fornecido pelo stakeholder (parciais; compressed deferido):**

- [x] **v3.3 — LHA Store via pure-pascal** (~1.5h real) — ✅ ENTREGUE (commit `2298f63`)
- [x] **v3.3.1 — LHA decoder OBJs SDK 4 toolchains** (~1h real) — ✅ ENTREGUE (commit `e2e52b1`) — 36/36 OBJ
- [x] **v3.3.2 — LH4/5/6/7 Pascal decoder port** (~2h real) — ⚠️ ENTREGUE compile OK (commit `2da3644`); runtime fixture pendente
- [x] **v3.4 — ARJ Store READ pure-pascal** (~1h real) — ✅ ENTREGUE (commit `baf7d2a`)
- [ ] **v3.4.1 — ARJ methods 1-9 via sdk/arj** (~6-10h) — 🟡 DEFERIDA (msgbind tooling bloqueia)
- [x] **v3.5 — RAR5 Store READ pure-pascal** (~1.5h real) — ✅ ENTREGUE (commit `5457d64`)
- [ ] **v3.5.1 — RAR5 LZSS via sdk/unrar/** (~15-25h) — 🟡 DEFERIDA (150 .cpp C++)

**Tier 3 — escopo maior, menor prioridade:**

- [x] **v3.6 — LZMA FPC Win32/Win64** (~1.5h real) — ✅ ENTREGUE (commit `aeb7e77`)
- [x] **v3.11 — ISO 9660 READ-only pure-pascal** (~2h real) — ✅ ENTREGUE (commit `a34c5f1`)
- [ ] **v3.12 — Linux x86_64 LZMA + AES-NI asm** (~5h FPC / ~9h FPC+Delphi) — 🟡 PENDENTE (gcc-linux-musl vendored)

**Rejeições mantidas (gates técnicos permanentes):**

- [x] **RAR encode** — sem spec aberta do encoder
- [x] **WIM (Windows Imaging)** — fora do escopo (Microsoft-specific niche)

**Total entregue:** 20 releases v3.x (v3.0–v3.11 + sub-releases v3.1.1/2/3 + v3.3.1/2 + v3.7.1/2/3),
cobrindo 12 formatos mainstream + 7zip WRITE completo + LZMA FPC.

**Esforço real gasto:** ~40h em 20 releases + ~15h infra (deps/ reorg + mingw +
gcc-linux-musl + zlib oficial + LHA SDK build).

**Pendentes opcionais (~25-35h):** v3.4.1, v3.5.1, v3.12, LH5 runtime fixture
validation, FPC Win64 CAB AV debug.

---

## 13. Apêndice — features ZIP entregues v2.3 (referência)

| # | Feature | Versão | Property/Method |
|---|---|---|---|
| 1 | Dual target Delphi D24..D37 + FPC/Lazarus | v1.5 | — |
| 2 | UTF-8 filenames | v1.7 | `TZipFile.UseUtf8` |
| 3 | Progress callbacks | v1.7 | `TZipFile.OnProgress` |
| 4 | AES-256 WinZip-AE-2 | v1.9 | `TZipFile.UseAES` + `Password` |
| 5 | AES-NI x64 inline asm | v1.9 | (auto) |
| 6 | Streaming real | v1.10 | `TZipFile.GetEntryStream` |
| 7 | ZIP64 READ | v1.11 | (auto) |
| 8 | Fluent builder | v2.0 | `Zip.NewArchive(...).Execute` |
| 9 | DUnitX testsuite | v2.0 | `tests/ZipFileTestsD29.dpr` |
| 10 | LZMA Win32 | v2.1 | `TZipFile.UseLZMA` |
| 11 | LZMA Win64 | v2.2 | (auto Win32+Win64) |
| 12 | ZIP64 WRITE | v2.3 | `TZipFile.ForceZip64` |
| 13 | Bug fixes vendor (EOCD scan, UnicodeString-vs-bytes) | v1.10+v1.9 | — |
| 14 | TAR (POSIX ustar) READ+WRITE | v3.0 | `TTarFile` |
| 15 | Gzip stream READ+WRITE | v3.0 | `TGzipReadStream`/`TGzipWriteStream` |
| 16 | Tar.Gz combo READ+WRITE | v3.0 | `TTarGzFile` |
| 17 | Archive format auto-detect by magic | v3.0 | `Archive.Open.DetectArchiveFormat` |
| 18 | 7zip READ Win32 (LZMA, LZMA2, Bcj2, Delta, BraX, AES-256, SHA256) | v3.1 | `TSevenZFile` |
| 19 | FPC Linux x86_64 cross-compile (core) | v3.1 | LCL-guarded units |

---

## 14. Apêndice — material fornecido pelo stakeholder (2026-05-25)

### 14.1 `zipfile/sdk/arj/` — APROVADO para v3.4

- **Origem:** ARJ 3.10 rev. 22, mantido por Andrew Belov, último commit 2005-06-23
- **Tamanho:** 118 arquivos C + headers + asm + docs
- **Licença:** GPL-2 (`sdk/arj/doc/COPYING`) — **irrelevante** (uso interno, §3.1)
- **Arquivos principais:** `arj.c`, `arj_arcv.c`, `arj_file.c`, `arj_proc.c`,
  `arj_user.c`, `arjcrypt.c`, `arjdata.c`, `arjsec_h.c`, `arjsec_l.c`, `arjsfx.c`
- **Status:** ✅ Pronto para compilar via bcc32c (Win32 OMF) + bcc64 (Win64 ELF)
- **Plano:** v3.4 — `src/Arj.ArjFile.pas` + `Lib/arj_obj_win{32,64}/*.obj/.o`

### 14.2 `zipfile/sdk/lha/` — APROVADO para v3.3

- **Origem:** LHa for UNIX 1.14i, mantido por Tsugio Okamoto + Koji Arai,
  último release 2005-09-24
- **Tamanho:** 30 arquivos C em `src/` + autoconf + docs (Japanese + English)
- **Licença:** "freeware" tradicional Japanese — **irrelevante** (uso interno)
- **Arquivos principais:**
  - Core: `lha.c`, `lharc.c`, `lhadd.c`, `lhext.c`, `lhlist.c`, `lhdir.c`
  - Compression: `slide.c`, `huf.c`, `shuf.c`, `dhuf.c`, `larc.c`
  - Helpers: `header.c`, `bitio.c`, `crcio.c`, `maketbl.c`, `maketree.c`
- **Métodos suportados pelo SDK:** -lh0- (store), -lh1- (LZHUF), -lh5- (LZ77+Huffman),
  -lh6-, -lh7- (maior dict)
- **Status:** ✅ Pronto para compilar via bcc32c + bcc64
- **Plano:** v3.3 — `src/Lha.LhaFile.pas` + `Lib/lha_obj_win{32,64}/*.obj/.o`

### 14.3 `zipfile/sdk/unrar/` — APROVADO para v3.5 (rota preferencial)

- **Origem:** UnRAR portable source (Alexander Roshal, RARLAB)
- **Tamanho:** 150 arquivos C++/HPP
- **Licença:** UnRAR freeware — decode permitido sem limitação, encode
  proprietário (gate técnico permanente, não bloqueia v3.5 READ-only)
- **Arquivos principais:** `archive.cpp`, `arcread.cpp`, `extract.cpp`,
  `unpack.cpp`, `unpack15.cpp`, `unpack20.cpp`, `unpack30.cpp`, `unpack50.cpp`,
  `rdwrfn.cpp`, `cmddata.cpp`, `crypt.cpp`, `blake2s.cpp`, `crc.cpp`
- **Status:** ✅ Pronto para compilar via bcc32c (Win32 OMF) + bcc64 (Win64 ELF)
- **Plano revisado v3.5:** static link via `{$L ..\Library\unrar_obj_win{32,64}\*.{obj,o}}`
  no Pascal — sem DLL externa, alinha com padrão LZMA SDK v2.x

### 14.3a `zipfile/dll/` — APROVADO como fallback opcional

- **`unrar_x86/unrar.dll`** + **`unrar_x86-64/unrar.dll`** Win32 + Win64
- **Status:** Mantido como rota alternativa (LoadLibrary dinâmico). Útil se
  build do source UnRAR via bcc32c/bcc64 encontrar issues C++ complexos (RTTI,
  exceptions). Decisão tipo-de-link feita na implementação v3.5.

### 14.4 Materiais já consumidos (referência v2.x)

- `zipfile/sdk/lzma2601/` — LZMA SDK 24.07 → consumido em v2.1/v2.2 (Win32+Win64)
  - Reuso futuro: `7z*.c` para v3.1 (7zip read+write)
- `BCC102/` (root workspace) — bcc32c.exe freeware → consumido em v2.1
- D37 + D28 SDK headers — consumido em v2.2 (Win64 LZMA build)

### 14.5 `zipfile/sdk/bzip2/` — APROVADO para v3.8

- **Origem:** bzip2 1.1.0-dev (Micah Snyder fork em GitLab), snapshot 2023-05-31
  (commit `66c46b8`)
- **Tamanho:** 13 arquivos C principais + CMake + tests + docs
- **Licença:** BSD-like (`sdk/bzip2/COPYING`) — irrelevante (uso interno)
- **Arquivos principais:** `bzlib.c`, `blocksort.c`, `huffman.c`, `crctable.c`,
  `randtable.c`, `compress.c`, `decompress.c`, `bzip2.c`, `bzip2recover.c`
- **Versão dev escolhida** (vs 1.0.8 stable) por trazer fixes MSVC/MinGW
  relevantes para nosso build via bcc32c/bcc64
- **Status:** ✅ Pronto para compilar via bcc32c + bcc64
- **Plano:** v3.8 — `src/Bzip2.Bzip2Stream.pas` + `Lib/bzip2_obj_win{32,64}/*.obj/.o`

### 14.6 Materiais — situação real (atualizada 2026-05-26)

**Materiais que foram consumidos/entregues:**

| Versão | Material | Situação atual |
|---|---|---|
| v3.7 | CAB Wine source em `sdk/cabnet/` (Wine FDI+FCI) | ✅ Consumido — NÃO usa `cabinet.dll` (decisão revisada §5d) |
| v3.7.2 | zlib oficial 1.3.2.1 em `sdk/zlib/` | ✅ Consumido — substituiu Wine zlib em commit `9b6bc38` |
| v3.8 | bzip2 1.1.0-dev em `sdk/bzip2/` | ✅ Consumido |
| v3.9 | Z / LZW pure-pascal | ✅ Implementado (`src/ZCompress.LzwStream.pas`) |
| v3.10 | UUE pure-pascal | ✅ Implementado (`src/UUE.UUEStream.pas`) |
| v3.11 | ISO 9660 pure-pascal | ✅ Implementado (`src/Iso.IsoFile.pas`) — Joliet detection ativa |
| v3.12 | FPC cross-compiler Linux x64 | ✅ Disponível em `D:\fpc\fpc\bin\x86_64-win64\ppcx64.exe` (`-Tlinux -Px86_64`) |
| v3.12 | gcc Linux cross para LZMA `.o` | ✅ Vendored em `deps/gcc-linux-musl/` (gcc 15.2 musl) |
| v3.12 (opcional) | RAD Studio Linux personality | ⚠️ Parcialmente instalada em D37; PAServer pendente |

**Materiais ainda pendentes:**

| Item | Bloqueador |
|---|---|
| `msgbind` tool build standalone | Necessário para v3.4.1 ARJ compressed; cascade de includes |
| `lhasa` library ou LHa.exe CLI | Necessário para gerar fixture `.lh5` runtime testável (v3.3.2 validation) |
| C++ ABI stubs minimal | Necessário para v3.5.1 UnRAR static-link (150 .cpp) |
| Linux runtime container (WSL/Docker/VM) | Necessário para validar ELF binários gerados via FPC cross |

### 14.7 Materiais NÃO necessários

- **RAR full source** — UnRAR.dll basta para READ (v3.5). Encode é inviável independente do material.
- **WIM library** — formato fora do escopo (§6).

### 14.8 Reorganização estrutural de SDKs (2026-05-25)

Após receber `arj.sdk/`, `lha.sdk/`, `bzip2.sdk.{0,1,2}/` (3 candidatos),
todos os SDKs foram consolidados sob `zipfile/sdk/` com sufixo `.sdk` removido:

```text
zipfile/
├── sdk/
│   ├── arj/         (era arj.sdk/)
│   ├── bzip2/       (era bzip2.sdk.2/ — 1.1.0-dev, mais recente, escolhida opção A)
│   ├── lha/         (era lha.sdk/)
│   ├── lzma2601/    (era lzma2601.sdk/)
│   └── unrar/       (UnRAR source freeware — 150 .cpp/.hpp; v3.5 static link)
├── dll/             (UnRAR.dll x86+x64 — fallback opcional para v3.5)
└── Lib/             (build outputs *.obj/.o consumidos por src/*.pas)
```

**Removidos** (3 versões bzip2 → mantida só a mais recente):

- `bzip2.sdk.0/` (2022-01-31 — superset em sdk.2)
- `bzip2.sdk.1/` (1.0.8 stable Jul-2019 — sem fixes MSVC/MinGW)

Paths atualizados em: `tools/Build-LzmaObjs.ps1`, `src/ZipFile.Compression.LZMA.pas`
(comments) e este SPEC.

### 14.9 Centralização total de sources (2026-05-25, commit `85f4e64`)

Após reorganização dos SDKs em `sdk/`, stakeholder solicitou centralizar
**todos** os sources Pascal em `src/` e **todos** os packages em `packages/`.
Resultado: root limpo (3 arquivos apenas).

**Movidos para `src/`** (9 arquivos):

- `ZipFile.pas` (core TZipFile)
- `tiCompress.pas` + `tiCompressNone.pas` + `tiCompressZLib.pas` + `tiConstants.pas`
  (vendor compression abstractions)
- `dzlib.pas` (vendor FPC-only zlib)
- `tiDefines.inc` (compiler defines, incluído por 4 ti*.pas)
- `tZipFile.lrs` + `tZipFile.xpm` (Lazarus resources, `{$I tZipFile.lrs}` no ZipFile.pas)

**Movidos para `packages/`** (2 arquivos):

- `zipfilepkg.lpk` (Lazarus package definition)
- `zipfilepkg.pas` (Lazarus auto-gen wrapper)

**Root agora tem 3 arquivos** (commit `9ce0ca6` adicionalmente mesclou
`readme.txt` em `README.md` e converteu `appnote.txt` → `appnote.md`):

```text
zipfile/
├── .gitignore
├── README.md      (inclui histórico vendor + tabela vendor-vs-v2.3)
└── appnote.md     (PKWARE 6.3.0 in-extenso preservado em fenced block)
```

**Estrutura final consolidada (atualizada 2026-05-26):**

```text
zipfile/
├── src/           26 sources Pascal (vendor 9 + v2.x helpers 7 + v3.x novos 10:
│                  Tar/Cab/SevenZ/Bzip2/Iso/Lha/Arj/Rar/ZCompress/UUE files)
├── packages/      23 BPLs Delphi D24..D37 + Lazarus pkg + Register + .dcr
├── sdk/           7 SDKs externos: arj, bzip2, cabnet, lha, lzma2601, unrar, zlib
├── dll/           UnRAR.dll fallback opcional v3.5.1 (decode-only)
├── Library/       ~23 MB **C/C++ OBJ outputs vendored** — flat por toolchain (consolidado v3.x):
│                  delphi-win32/   (bcc32c OMF, .obj)  — lzma + cabnet + bzip2 + zlib + lha + arj
│                  delphi-win64/   (bcc64 ELF, .o)     — idem
│                  fpc-win32/      (mingw COFF -m32, .o) — idem
│                  fpc-win64/      (mingw COFF -m64, .o) — idem
│                  linux-x64/      (gcc-linux-musl, .o)  — cabnet apenas (v3.3+)
│                  Motivação: zero colisão de filename entre SDKs; consolidação simplifica
│                  paths {$L} em código Pascal (4 dirs vs 25 subdirs anterior).
├── Lib/           **Delphi BPL + FPC native unit outputs** (não C OBJs):
│                  RAD10.1/.../RAD13/    (Delphi BPL/DCP/DCU per IDE marketing name)
│                  i386-win32/, i386-win64/, x86_64-win64/    (FPC native units)
├── deps/          gcc-mingw-w64 16.1 + gcc-linux-musl 15.2 + Win SDK headers
├── tests/         DUnitX testsuite (31 v2.x) + ~20 smoke .dpr/.pas v3.x
├── tools/         build scripts: Generate-DelphiPackages, Build-LzmaObjs,
│                  Build-Bzip2Objs, Build-LhaObjs, Build-ArjObjs, Build-AllDelphis,
│                  Build-FPC-Smoke, Make-{Iso,Lha,Arj,Rar}Fixture, Dump-7zStore
├── Documentation/ SPEC v3.x + lições aprendidas §15
└── Backup/, example/, lib/, testcase/   (vendor reference dirs intocados)
```

**Paths atualizados:**

- `tools/Generate-DelphiPackages.ps1` — `..\src\ZipFile.pas` (era `..\ZipFile.pas`)
- `tools/Generate-DelphiPackages.ps1` — `<DCC_UnitSearchPath>..\src` (era `..;..\src`)
- `packages/zipfilepkg.lpk` — `..\src\ZipFile.pas` (era `ZipFile.pas`)
- `packages/zipfilepkg.lpk` — `OtherUnitFiles ..\src`, `UnitOutputDirectory ..\lib`
- `README.md` — referência `appnote.txt` → `appnote.md`

**Validação:** 23/23 BPLs Delphi + Lazarus 0 errors + 31/31 DUnitX PASS após reorg.

---

## 15. Apêndice — Lições aprendidas v3.1 (consolidar para v3.2+)

Durante a entrega v3.1 surgiram aprendizados aplicáveis aos próximos releases:

### 15.1 Linker Delphi OBJ — ordem e mutual deps

- **Regra confirmada (lição de v2.1 LZMA reconfirmada em v3.1):** OBJs com
  refs forward são resolvidos por OBJs `$L`-linkados **DEPOIS** na mesma unit
  Pascal. Ordem: **consumers FIRST, providers LAST**.
- **Cross-unit OBJ link NÃO resolve refs** — mesmo que `ZipFile.Compression.LZMA.pas`
  defina `_LzmaDec_Allocate` via {$L LzmaDec.obj}, refs de outras units não
  veem isso. Cada unit que precisar do símbolo deve linkar a OBJ que o provê.
- **Mutual deps entre OBJs separados não funcionam** — `7zArcIn.c` calling
  `SzAr_DecodeFolder` (em `7zDec.c`) AND `7zDec.c` calling `SzGetNextFolderItem`
  (em `7zArcIn.c`) ambos como OBJs distintos quebra o linker single-pass do Delphi.
  **Solução:** combinar via `#include` em um único `.c`/OBJ (`SevenZCombined.c`).

### 15.2 CRT stubs cdecl em Pascal

- bcc32c Win32 OMF: símbolos cdecl com prefixo `_` (ex. `_malloc`, `_memset`)
- bcc64 Win64 ELF: sem prefixo
- Conditional compile via `{$IFDEF WIN32} {$DEFINE STUB_NAME_USES_UNDERSCORE} {$ENDIF}`
  decide qual nome usar na external decl

### 15.3 Windows API stdcall sem mangling

- bcc32c (clang32) emite imports de Win32 APIs **sem** decoração `_Name@N`
  típica do Borland classic — usa Microsoft-style "name as-is".
- Pascal `external 'kernel32.dll' name 'CreateFileA'` (sem `_` nem `@N`) resolve.

### 15.4 bcc64 Win64 ELF limitações — RESOLVIDO em v3.1.1

Investigação completa do problema "Bad object file format" em `Aes.o`/`7zCrc.o`
gerou 4 fixes complementares, cada um isolando uma limitação específica do
linker Delphi para OBJs ELF emitidos por `bcc64`:

**(a) Linker Delphi rejeita seção `.bss` (SHT_NOBITS) em OBJs `{$L}`.**

- Sintoma: `E2045 Bad object file format: '7zCrc.o'`
- Causa: `g_CrcTable[256*N]` e `g_CrcUpdate` (function ptr) são globals
  zero-inicializados → gcc/clang colocam em `.bss` por default. ELF linker
  do Delphi não aceita `.bss` em OBJ linked-in.
- Fix: compilar com **`-fno-zero-initialized-in-bss`** → força globals
  zero-init para `.data` (alocação real no arquivo). Diff de tamanho
  desprezível (alguns KB).
- Como diagnosticar: dump das seções ELF; sintoma exclusivo é a presença
  de seção `.bss` (type=0x8) no OBJ que falha. Comparar com OBJ que linka
  OK (e.g. `LzmaDec.o` não tem `.bss`).

**(b) Linker Delphi single-pass para ELF — refs mútuas entre OBJs separados não resolvem.**

- Sintoma: `E2065 Unsatisfied forward or external declaration: 'SHA256_K_ARRAY'`
  (definido em `Sha256.o`, referenciado por `Sha256Opt.o`), mesmo com ambos
  OBJs no `{$L}` chain.
- Causa: `Sha256.c ↔ Sha256Opt.c` têm refs mútuas (`Sha256_UpdateBlocks_HW`
  ↔ `SHA256_K_ARRAY`). Idem `Aes.c ↔ AesOpt.c`. Linker Delphi single-pass
  forward-only não consegue resolver. Win32 OMF (ilink32 do BCC102) é
  multi-pass — funciona sem ajuste.
- Fix: criar **wrappers `*Combined.c`** que `#include` os dois `.c`
  em um único TU (mesma técnica de `SevenZCombined.c` para `7zArcIn.c ↔
  7zDec.c`). Símbolos resolvem-se internamente. Win32 mantém OBJs
  separados (multi-pass tolera).
- Wrappers criados: `sdk/lzma2601/C/AesCombined.c`, `Sha256Combined.c`.

**(c) bcc64 backend LLVM incompleto — não emite intrinsics x86 AES-NI/SHA-NI.**

- Sintoma: `fatal error: error in backend: Cannot select: intrinsic
  %llvm.x86.aesni.aesdec`
- Causa: bcc64 frontend é clang completo (define `__clang__`,
  `Z7_LLVM_CLANG_VERSION`) e detecção do SDK 24.07 ativa `USE_INTEL_AES`
  → gera intrinsics `_mm_aesdec_si128` etc. Backend bcc64 não consegue
  selecionar essas instruções (provavelmente built sem target features
  x86 completos).
- Fix: forçar caminho **stub puro-SW** dentro do wrapper combinado via
  `#undef Z7_LLVM_CLANG_VERSION` + `#define Z7_USE_AES_HW_STUB` ANTES
  de incluir o `Opt.c`. Stub emite wrappers `*_HW` que delegam para
  variantes SW (perf negligível para arquivos pequenos; CPU moderno
  faz SHA-256 puro-SW a ~500 MB/s).
- Alternativa (não usada): `bcc64x` (Embarcadero clang novo do D13)
  ou recompilar bcc64 com `+aes,+ssse3,+sha` target features.

**(d) `Alloc.c`/`CpuArch.c` usam Win32 APIs não-importadas em Win64.**

- Sintoma: `E2065 Unsatisfied forward or external declaration: 'GetLargePageMinimum'`,
  `'IsProcessorFeaturePresent'`
- Causa: Win32 OMF + ilink32 do BCC102 resolve essas via msvcrt fallback
  automaticamente; Win64 ELF requer `external 'kernel32.dll' name '...'`
  explícito no Pascal.
- Fix: adicionar 2 funções `external 'kernel32.dll'` na unit Pascal.

**Política derivada para futuros wrappers bcc64 + SDK 24.07 (ou similar):**

1. Sempre compilar Win64 com `-fno-zero-initialized-in-bss`.
2. Para qualquer par `<Mod>.c ↔ <Mod>Opt.c` com refs mútuas, criar
   `<Mod>Combined.c` + suprimir detecção clang via `#undef` + forçar
   STUB define apropriado (`Z7_USE_*_HW_STUB`).
3. Auditar consumers de `Alloc.c`/`CpuArch.c` para Win32 APIs adicionais
   além do já documentado.

### 15.5 FPC Linux cross — LCL guards

- `LCL` symbol é auto-definido pelo Lazarus IDE; FPC standalone (CLI) não
  define. Padrão `{$IFDEF LCL}` é o discriminator correto.
- Units pre-built FPC em `D:\fpc\fpc\units\<target>/` permitem cross-compile
  sem instalar gcc/binutils nativos do alvo (cross binutils já vendored).
- `FileUtil.CopyFile` é LCL — substituir por TFileStream-based wrapper em
  modo headless.

### 15.5b bzip2 BZ_API = WINAPI = __stdcall (Win32) — RESOLVIDO em v3.8

bzlib.h linha 88 define `BZ_API(func) WINAPI func` quando `_WIN32`.
`WINAPI` resolve para `__stdcall` no MSVC ABI. **Pascal `external`
**precisa declarar `stdcall`**, NÃO `cdecl`. Sintoma se errar:

- Compilação OK (linker encontra símbolo).
- Warning `W1028 Bad global symbol definition` (sintoma fraco — fácil
  ignorar).
- Runtime: AV imediato no retorno da função → exit code `0xC0000005`.

Causa: com cdecl, caller pop. Com stdcall, callee pop. Se ambos pop,
stack pointer fica errado → próxima instrução RIP corrompida.

**Sintoma identificável:** AV `0xC0000005` em fopen logo após chamar
função extern C. Cheque calling convention do header SDK.

Adicional: `bcc32c` emite símbolo stdcall **sem** sufixo `@N` (ao
contrário do MSVC tradicional) e **sem** prefixo `_` (ao contrário do
cdecl OMF). Use o nome simples como em `external name 'BZ2_bzBuffToBuffCompress'`.

Em **Win64** (e bcc64 + FPC mingw64), `stdcall` e `cdecl` são o mesmo
MS x64 ABI unificado — declarar `stdcall` continua funcionando.

### 15.5c CRT stubs Win64 — sem prefixo `_` — RESOLVIDO em v3.8

Para OBJs ELF/COFF Win64 importados via `{$L}` que referenciam CRT
básico (`malloc`/`free`/`memcpy`/`memset`/`setjmp`/`longjmp`), os
símbolos não têm prefixo `_` (diferente do Win32 OMF cdecl).

**Padrão** (já consolidado em `SevenZ.SevenZFile.pas` e agora também
em `Bzip2.Bzip2Stream.pas`):

```pascal
{$IFDEF WIN32}
  {$DEFINE BZ_C_UNDERSCORE}
{$ENDIF}

{$IFDEF BZ_C_UNDERSCORE}
function _malloc(size: NativeUInt): Pointer; cdecl;
{$ELSE}
function malloc(size: NativeUInt): Pointer; cdecl;
{$ENDIF}
begin
  ...
end;
```

Adicionalmente, **stack-probe stub** difere por toolchain:

| Toolchain | Símbolo de stack probe |
|-----------|------------------------|
| bcc32c (Win32 OMF) | `__chkstk_noalloc` |
| bcc64 (Win64 ELF) | `__chkstk` |
| mingw COFF Win64 | `___chkstk_ms` (mingw runtime) |

### 15.5d Combined.c policy genérica — extendida em v3.8

`SevenZCombined.c` (v3.1) e `BzipCombined.c` (v3.8) consolidaram TODOS
os `.c` de seu respectivo SDK em um único TU. Política derivada para
qualquer integração C SDK em Delphi:

- **Por que combinar:** linker single-pass do Delphi não resolve refs
  mútuas entre OBJs separados. Mesmo em Win32 OMF (multi-pass) há
  edge cases.
- **Quando combinar:** se 2+ `.c` referenciam símbolos uns dos outros
  mutuamente.
- **Como combinar:** wrapper `<Pkg>Combined.c` com `#include` dos
  `.c` na ordem topológica (consumidores depois). Ordem dentro do
  TU não importa para o C compiler — ele faz multi-pass interno.
- **Win32 vs Win64:** Win32 OMF tolera OBJs separados quase sempre.
  Win64 ELF é mais restrito. Por consistência, usar combined em
  ambos.

### 15.5e LZMA FPC mingw — RESOLVIDO em v3.6

Habilitação do LZMA Delphi (Win32+Win64 já funcional desde v1.x) para FPC
Win32+Win64 via mingw COFF. Lições:

**(a) FPC mingw COFF — formato compatível com FPC linker.**

mingw `gcc -m32` e `gcc -m64` emitem COFF "limpo" que o linker do FPC
(internal linker `ld`-derived) aceita direto. NÃO se pode reusar os
`.obj` OMF (bcc32c) nem os `.o` ELF (bcc64) Embarcadero — formatos
incompatíveis. Solução: subdir `Lib/lzma_obj_fpc_{win32,win64}/`
separado, compilado por mingw com mesmos sources do `sdk/lzma2601/C/`.

**(b) FPC vs Delphi name decoration em Win32 cdecl — comportamento divergente.**

Cenário: Pascal extern declara `external name '_LzmaEncode'`.

- **Delphi Win32 OMF (bcc32c):** Pascal usa nome literal `_LzmaEncode`.
  bcc32c cdecl emite `_LzmaEncode`. Match.
- **FPC Win32 mingw COFF:** FPC `cdecl` adiciona `_` automaticamente
  em Win32, **mesmo quando `name '...'` está presente** (override
  imperfeito). Pascal procurando por `__LzmaEncode` (double `_`).
  mingw cdecl emite `_LzmaEncode`. Mismatch.

Fix: para FPC Win32, declarar `external name 'LzmaEncode'` (bare,
sem `_`). FPC adiciona `_` automaticamente → resolve para `_LzmaEncode`.

Solução genérica adotada (`C_PREFIX_UNDERSCORE` define):

```pascal
{$IF DEFINED(WIN32) AND NOT DEFINED(FPC)}
  {$DEFINE C_PREFIX_UNDERSCORE}
{$IFEND}
```

Em Win64 ambos (Delphi+FPC) usam nome bare — sem distinção.

**(c) FPC msvcrt linkage — substitui CRT stubs Pascal.**

Para Delphi, implementamos Pascal stubs de `memcpy`/`memset`/`malloc`
etc. redirecionando para RTL. Em FPC isso causaria duplicate symbol
(FPC RTL já tem essas funções internas para uso C, ou mingw libs
expõem). Solução cleaner: `{$LINKLIB msvcrt}` no FPC mode → linker
resolve `memcpy`/`memset`/`memmove`/`malloc`/`free`/`realloc` via
DLL msvcrt.dll real. Stubs Pascal envolvidos em `{$IFNDEF FPC}`.

**(d) Diretrizes para futuras integrações C SDK em FPC.**

1. Cross-compile com `mingw-w64 gcc -m32`/`-m64` (vendored em
   `deps/gcc-mingw-w64/`).
2. Output em `Lib/<sdk>_obj_fpc_win{32,64}/` (subdir distinto do
   Embarcadero `Lib/<sdk>_obj_win{32,64}/`).
3. Linkage Pascal via `{$L file.o}` (mesmo `$L` do Delphi).
4. Para CRT: `{$LINKLIB msvcrt}` resolve memcpy/setjmp/malloc etc.
5. Para Win APIs: `{$LINKLIB kernel32}` resolve VirtualAlloc etc.
6. Name decoration Win32: extern declarar bare (FPC decora) vs
   Delphi declarar `_X` (sem decoração). Conditional via define.

### 15.5f LZMA2 encoder integration (Lzma2Enc.c) — RESOLVIDO em v3.1.3

Static-link de `sdk/lzma2601/C/Lzma2Enc.c` para habilitar 7z WRITE com
método 0x21 (LZMA2) compressed. Lições:

**(a) `-DZ7_ST` obrigatório para strip MtCoder dependencies.**

`Lzma2Enc.c` contém `CMtCoder mtCoder` como struct field (não gated)
mesmo no path memory-to-memory (`Lzma2Enc_Encode2(outBuf, inData)`).
Sem `Z7_ST`, OBJ referencia `MtCoder_Construct/Code/Destruct` que
não temos linkados.

Fix: adicionar `-DZ7_ST` a TODAS toolchains. `_7ZIP_ST` legacy não é
suficiente (SDK 24.07 usa `Z7_ST` modern macro).

**(b) Lzma2Enc requer LzmaEnc.obj/o no link chain.**

Lzma2 é wrapper sobre Lzma1. `Lzma2Enc.obj` referencia 12+ símbolos
`LzmaEnc_*` (Create, SetProps, MemPrepare, etc.). Em
`SevenZ.SevenZFile.pas` adicionar:
```pascal
{$L ..\Library\delphi-win32\Lzma2Enc.obj}
{$L ..\Library\delphi-win32\LzmaEnc.obj}
```

**(c) Layout C struct `CLzmaEncProps` mudou em SDK 24.07.**

Spec antigo: 13 fields, 60 bytes. SDK 24.07: 16 fields, 80 bytes —
adicionou `affinityGroup` (Int32) + `reduceSize` (UInt64) +
`affinityInGroup` (UInt64) após writeEndMark/numThreads.

Política: **sempre verificar `LzmaEnc.h` SDK atual** antes de
declarar Pascal record. Tamanho errado → AV at runtime.

**(d) Codec ID 7z taxonomia.**

- Copy:    `[$00]` (1 byte) — properties vazio
- LZMA2:   `[$21]` (1 byte) — properties = 1 byte dict-encoded
- LZMA1:   `[$03 $01 $01]` (3 bytes) — properties = 5 bytes
- BCJ:     `[$03 $03 $01 $03]` (4 bytes)

Folder coder flags byte: bits 0..3 = CodecIdSize, bit 4 = isComplex,
bit 5 = hasAttrs, bit 6 = reserved, bit 7 = alternativeMethods.

### 15.5g LHA SDK static-link probe (decoder OBJs) — v3.3.1

LHa-for-Unix SDK (1995) compilou em 4 toolchains com shims minimais:

**(a) `sys/file.h` ausente em Windows toolchains.**

Solução: `sdk/lha/compat/sys/file.h` empty stub + `-Isdk/lha/compat`.
SDK só usa para flock() em paths não-decoder.

**(b) `RETSIGTYPE` autoconf-generated.**

Solução: `-DRETSIGTYPE=void` (autoconf default em sistemas POSIX
modernos). LHa usa em signal handler types que não chamamos.

**(c) `HAVE_VSNPRINTF`/`HAVE_SNPRINTF` redefinição conflitante.**

LHa fornece próprio snprintf em `vsnprintf.c` se `!HAVE_VSNPRINTF`.
mingw/msvcrt já tem nativo: `-DHAVE_VSNPRINTF=1 -DHAVE_SNPRINTF=1`.

Idem `-DHAVE_MEMMOVE=1 -DHAVE_STRDUP=1 -DHAVE_STRCASECMP=1` para mingw.

**(d) K&R old-style function definitions.**

LHa source de 1995 usa `int func(arg) int arg; { ... }` K&R style.
mingw gcc 16.1 rejeita por default. bcc32c/bcc64 (clang) tolera.

Solução para mingw: `-std=gnu89 -Wno-error -Wno-old-style-definition`.

**Resultado:** 9 decoder cores × 4 toolchains = **36/36 OBJ OK** em
`Lib/lha_obj_{win32,win64,fpc_win32,fpc_win64}/`. Pascal integration
deferida v3.3.2 (requer wrapper FILE*→buffer I/O — LHA decoders
chamam `fread_crc()`/`fwrite_crc()` sobre `interface.infile`/`outfile`
que são FILE*).

### 15.5h ARJ SDK static-link — BLOQUEADO (v3.4.1 deferida)

ARJ SDK estruturalmente complexo:

- 118 .c arquivos majoritariamente CLI tools (ARJ.exe full)
- `c_defs.h` espera autoconf (`gnu/configure`) materializar
- `arj.h` inclui `msg_arj.h`/`msg_sfj.h`/`msg_sfv.h` que NÃO existem
  no source — são gerados por `msgbind.c` em build-time a partir de
  `resource/<lang>/*.txt`
- Mesmo com `SFX_LEVEL=ARJSFXJR` (menor), 30+ deps internas restam

Stub `sdk/arj/compat/c_defs.h` criado mas surface area inviabiliza
static-link rápido. Path realista: build `msgbind` standalone primeiro
para gerar headers, depois iterar.

### 15.5i UnRAR SDK static-link — BLOQUEADO (v3.5.1 deferida)

UnRAR SDK é 150 .cpp **C++** files que requer:

- C++ runtime stubs (std::string, std::vector, RTTI, exception unwinding)
- bcc32x/bcc64x (clang C++ moderno) ao invés de bcc32c/bcc64
- RAR5 algorithm = LZSS + Suns + Rijndael + BLAKE2 — complexo

Path realista (futuro): bcc32x/bcc64x com C++ exceptions desabilitadas
+ providers de C++ ABI stubs mínimo + cuidadosa seleção de subset.

### 15.6 PowerShell 5.1 + stderr de native exe

- `2>&1` em executáveis (bcc32c, dcc32) faz PS5.1 envolver cada linha stderr
  em ErrorRecord e setar `$?=$false` mesmo com exit code 0. Workaround:
  capturar via `$LASTEXITCODE` explicitamente e ignorar a exception (já
  documentado em CLAUDE.md).

---

## 16. v3.12 — Design-Time Enrichment (2026-05-27)

### 16.1 Escopo

v3.12 não adiciona novo formato de archive — eleva a experiência do design-time
no IDE Delphi (e Lazarus) ao nível "production component pack" comercial:

1. **Palette branded** — aba `ZipCompress` na Tool Palette (era `Misc`).
2. **10 componentes visuais** — todos os archive types virando arrastáveis.
3. **TGzipFile NOVO** — wrapper de stream para single-file `.gz` (era só
   `TGzipReadStream`/`TGzipWriteStream` em código).
4. **70+ properties published** distribuídas entre os 10 componentes com
   propósito design-time (write config + header info read-only + eventos).
5. **Property categories** no Object Inspector (`Arrange by Category`).
6. **Ícones distintos por formato** — 24x24 BMP com gradiente vertical,
   cantos arredondados, sigla branca (ZIP/TAR/TGZ/GZ/CAB/7Z/ARJ/ISO/LHA/RAR).
7. **IDE splash + About box** — entry "ZipCompress 3.1 — Free / Open-source"
   via `IOTASplashScreenServices.AddPluginBitmap` + `IOTAAboutBoxServices.AddPluginInfo`.
8. **Unit naming uniformizado** — units de componente sem prefixo `<Domain>.`
   (`TarFile`/`TarGzFile`/`GzipFile`/`CabFile`/`SevenZFile`/`ArjFile`/`IsoFile`/
   `LhaFile`/`RarFile`), alinhados ao padrão histórico de `zipfile`. Units
   internos preservam namespace (`ZipFile.Progress`, `Tar.GzipStream`, etc.).
9. **Multi-IDE rollout completo** — 7 sets D24..D37 (Delphi 10.1 Berlin a
   Delphi 13 Florence) com 49 BPLs deployados nos respectivos `BDSCOMMONDIR\Bpl\`.

### 16.2 Componentes registrados na palette `ZipCompress`

| Componente | Unit (após rename) | Suporte | Properties published (cat) |
| --- | --- | --- | --- |
| `TZipFile` | `zipfile` | RW completo | 19 (File/Compression/Encryption/ZIP64/Encoding/Volume/Metadata/Events) |
| `TTarFile` | `TarFile` | RW Pascal | 22 (File/Format/Metadata/Block geometry/Extensions/Info/Events) |
| `TTarGzFile` | `TarGzFile` | RW combo | 27 (File/Compression/Format/Metadata/Gzip extras/Info/Events) |
| `TGzipFile` | `GzipFile` | RW single-file | 17 (File/Compression/Metadata/Advanced flags/Info/Events) |
| `TCabFile` | `CabFile` | RW Wine FDI/FCI | 27 (File/Compression/Cabinet Set/Multi-cab chain/Reserved areas/Volume/Extraction/Info/Events) |
| `TSevenZFile` | `SevenZFile` | RW LZMA2 | **42** (File/Compression/LZMA Tuning/Filter/Encryption/Archive Flags/SFX/Volume/Info/Events) |
| `TArjFile` | `ArjFile` | R-only Pascal | 21 (File/Info/Header fields/Dates/Events) |
| `TIsoFile` | `IsoFile` | R-only Pascal | 30 (File/Volume Descriptor/Dates/Application Use/Extensions/Boot/Info/Events) |
| `TLhaFile` | `LhaFile` | R-only Pascal | 16 (File/Info/Header data/Totals/Events) |
| `TRarFile` | `RarFile` | R-only Pascal | 27 (File/Info/Volume status/Comment/Recovery/Lock/QuickOpen/Events) |

Total: **~248 published properties + ~145 published events** cross-componente (vs ~22 properties e 2 events pré-v3.12; +1027% / +7150%).

#### 16.2.1 Event coverage por componente (v3.12.1)

Tipos de evento compartilhados em **`src/ZipFile.Events.pas`** (15 types) —
cobre lifecycle / entries / progress / security / multi-volume / verify /
diagnostics / codec chain (7z especifico).

| Componente | Events | Categorias |
| --- | --- | --- |
| `TSevenZFile` | **24** | Lifecycle (4) + Entries (1) + Extract (3) + Add (3) + Solid block 7z (4) + Security (3) + MultiVol (2) + Diagnostics (3) + Basic (2) |
| `TZipFile` | 19 | Lifecycle (4) + Entry (1) + Extract (3) + Add (3) + Security (3) + MultiVol (2) + Diagnostics (3) |
| `TCabFile` | 19 | Lifecycle (4) + Entry (1) + Extract (3) + Add (3) + Security (3) + MultiVol (2) + Diagnostics (3) |
| `TRarFile` | 19 | Lifecycle (4) + Entry (1) + Extract (3) + Solid (2) + Security (3) + MultiVol (2) + Diagnostics (3) + Basic (1) |
| `TTarFile` | 17 | Lifecycle (4) + Entry (1) + Extract (3) + Add (3) + Security (3) + Diagnostics (3) |
| `TTarGzFile` | 17 | (idem TTarFile) |
| `TArjFile` | 15 | Lifecycle (4) + Entry (1) + Extract (3) + Security (3) + MultiVol (2) + Diagnostics (3) |
| `TIsoFile` | 13 | Lifecycle (4) + Entry (1) + Extract (3) + Security (3) + Diagnostics (3) |
| `TLhaFile` | 13 | (idem TIsoFile) |
| `TGzipFile` | 9 | Lifecycle (4) + Security (3) + Diagnostics (3) — single-file, sem entry events |

### 16.3 Property design rationale

Para cada componente, properties seguem 4 grupos:

- **File** (sempre) — `Active`, `FileName`, `EntryCount` (read-only).
- **Compression / Format / Metadata** — knobs de write quando o formato suporta
  configuração (level, method, ownership, mode bits, etc.). Validação por setter
  quando aplicável (ex.: `Level: 1..9` lança exception se fora).
- **Read-only header info** — campos parseados na abertura (`ArchiveSize`,
  `IsMultiVolume`, `HostOS`, `MajorVersion`, etc.). Para read-only archives
  (Arj/Iso/Rar/Lha) este grupo é o mais rico.
- **Events** — `OnFileChanged: TNotifyEvent` (disparado em `SetFileName`),
  `OnProgress: TZipProgressEvent` (assinatura compat com `TZipFile`).

Properties novas declaradas mas com população deferida (ex.: AES password no
7zip — write encryption ainda não wirado em v3.12) são marcadas no source com
`// reservado v3.2`/`// reservado v3.8.x` etc. — surface API estável, behavior
incremental por release.

### 16.4 Multi-volume / Split support — surface API

Properties `VolumeSize: Int64` published em TSevenZFile e TCabFile (writers).
TArjFile/TRarFile expõem `IsMultiVolume` read-only (detect em abertura). TZipFile
mantém ZIP64 via `ForceZip64` (não é split físico mas relacionado a archive size).
Wiring de split write fica para v3.13.

### 16.5 Splash screen integration

Unit `packages/ZipCompress.SplashReg.pas` chama no `initialization` da BPL
design-time:

```pascal
if Assigned(SplashScreenServices) then
  SplashScreenServices.AddPluginBitmap(
    'ZipCompress 3.1',
    GSplashBmp.Handle,
    False {IsUnRegistered},
    'Free / Open-source',
    'ZIPCOMPRESS-3.1');
```

Detalhes críticos descobertos na implementação:

- `BorlandIDEServices` é **nil** durante `initialization` da BPL design-time;
  doc IOTA explícita: _"IOTASplashScreenServices is the first service available
  during product startup … when this interface is created, the BorlandIDEServices
  interface is unavailable since it has yet to be initialized."_ Por isso usar
  a **global function** `SplashScreenServices` direto (não `Supports(BorlandIDEServices, …)`).
- Bitmap 24x24 com pixel transparente no **lower-left** (`(0, Height-1)`), não
  upper-left — convenção do splash conforme `IOTASplashScreenServices270.AddPluginBitmap`
  docstring.
- About box (`IOTAAboutBoxServices`) registra DEPOIS — `BorlandIDEServices` já
  está pronto quando About é renderizado, então caminho usual `Supports(...)` ok.

### 16.6 Ícones — geração programática (estilo uniforme premium)

**Decisão final (v3.12.2):** todos os 10 ícones seguem o **mesmo padrão visual**
para coerência da palette, cada um com cor brand distinta. Iterações exploradas
antes desta decisão:

1. **v3.12.0** — flat colored squares (recusado: "muito sólido")
2. **v3.12.1** — Wikimedia CC0/PD downloads: `7-Zip Icon.svg` (CC0) e
   `Gzip-Logo.svg` (PD) baixados em 500px e downscaled para 24x24 (recusado:
   ruim em 24x24 + heterogêneo com os outros 8 stylized)
3. **v3.12.1b** — exploração `SHGetFileInfo` para extrair ícones associados a
   `.zip`/`.7z`/etc.: descoberto que **WinRAR registra-se como handler de TODOS
   os formatos** no sistema do usuário, fazendo todos os 9 com associação custom
   retornarem o **mesmo ícone do WinRAR.exe** (logo "stacked books" trademark
   RARLAB). Abordagem abandonada por trademark infringement + duplicação visual
4. **v3.12.2 (final)** — uniform style premium com 5 camadas (decisão atual)

Cada `T<Format>FILE.bmp` em `packages/icons/` é gerado por PowerShell +
System.Drawing.Drawing2D com 5 camadas:

1. **Rounded path** (raio 4px) via `GraphicsPath.AddArc` para mask
2. **Vertical gradient** — `LinearGradientBrush` top (+30% lighter) → bottom
   (-20% darker) da cor brand
3. **Glossy top highlight** — semi-elipse com gradient alpha 85→0 (efeito vidro
   estilo Aqua/Material)
4. **Outer stroke** — preto semi-transparente (alpha 150) para depth
5. **Bold text** — Segoe UI Bold (size 9 para 2-char "7Z"/"GZ", size 7 para
   3-char) com **sombra escura** (alpha 160) atrás + branco principal

**BMP format constraints:**

- 24x24 pixels, 24bpp, BMP v3 puro (BITMAPINFOHEADER 40 bytes)
- Pixel transparente no **lower-left** (`(0, Height-1)`) com magenta `$FF00FF`
- Helper `Save-Bmp24v3` escreve header manualmente — brcc32 rejeita BMP v4/v5
  do .NET (que é o que `System.Drawing.Bitmap.Save` produz por padrão)

`packages/ZipFile.rc` mapeia 10 entries `T<NAME>FILE BITMAP "icons\T<NAME>FILE.bmp"`,
compilado para `ZipFile.dcr` (18200 bytes) via `brcc32` do Delphi 13.

**Cores brand (Material Design):**

| Componente | Hex | Material name |
| --- | --- | --- |
| TZIPFILE | `#9C27B0` | Purple 500 |
| TTARFILE | `#795548` | Brown 500 |
| TTARGZFILE | `#4CAF50` | Green 500 |
| TGZIPFILE | `#8BC34A` | Light Green 500 |
| TCABFILE | `#2196F3` | Blue 500 |
| TSEVENZFILE | `#FF5722` | Deep Orange 500 |
| TARJFILE | `#FF9800` | Orange 500 |
| TISOFILE | `#607D8B` | Blue Grey 500 |
| TLHAFILE | `#E91E63` | Pink 500 |
| TRARFILE | `#F44336` | Red 500 |

**Source files preservados** (não compilados, kept para iterações futuras):

- `packages/icons/source/7Zip_500.png` — Wikimedia CC0 source 500px
- `packages/icons/source/Gzip_500.png` — Wikimedia PD source 500px
- `packages/icons/source/Bzip2_500.png` — Wikimedia PD (não usado — bzip2 não
  tem TComponent registrado, só stream classes)
- `packages/icons/source/7-Zip_Icon.svg` — CC0 SVG original
- `packages/icons/source/Gzip-Logo.svg` — PD SVG original
- `packages/icons/source/windows/*.png` — capturas do experimento SHGetFileInfo
  (todas WinRAR — não usadas)
- `packages/icons/source/NOTICE.md` — credits/attribution + trademark notice

### 16.7 Estrutura de DPK / LPK final

**Runtime DPK (`zipfileD<XX>.dpk` — 7 sets D24..D37):**

- 11 units `ZipFile.*` (existentes: Progress/Encryption/Streaming/Fluent/LZMA/ZIP64/UTF8 etc.)
- 13 units flat (post-rename): zipfile, TarFile, TarGzFile, GzipFile, CabFile,
  SevenZFile, ArjFile, IsoFile, LhaFile, RarFile, Tar.GzipStream, Archive.Open,
  UUE.UUEStream, ZCompress.LzwStream + 4 internal (tiCompress/None/ZLib/Constants).
- `requires rtl, vcl`.

**Design DPK (`dclzipfileD<XX>.dpk`):**

- `zipfileReg.pas` — palette registration + property categories
- `ZipCompress.SplashReg.pas` — IOTA splash + About box
- `{$R ZipFile.dcr}` — 10 component bitmaps
- `requires designide, rtl, vcl, zipfileD<XX>`.

**Lazarus LPK (`zipfilepkg.lpk`):**

- 21 itens (Item1..Item21) — mesmo conjunto runtime
- `HasRegisterProc = True` em `Item1` (zipfile) que tem o `Register` proc
  FPC-condicional na unit principal (em Delphi, registration vai pelo
  `zipfileReg.pas` no design BPL).
- Palette page `ZipCompress` igual ao Delphi.

### 16.8 Validação multi-IDE

Build matrix 7 IDEs (Delphi 10.1 Berlin → Delphi 13 Florence):

| IDE | BDS | Output `Lib/` | rt32 | rt64 | dcl32 | dcl64 |
| --- | --- | --- | :---: | :---: | :---: | :---: |
| Delphi 10.1 Berlin | 18.0 | RAD10.1 | ✅ | ✅ | ✅ | — |
| Delphi 10.2 Tokyo | 19.0 | RAD10.2 | ✅ | ✅ | ✅ | — |
| Delphi 10.3 Rio | 20.0 | RAD10.3 | ✅ | ✅ | ✅ | — |
| Delphi 10.4 Sydney | 21.0 | RAD10.4 | ✅ | ✅ | ✅ | — |
| Delphi 11 Alexandria | 22.0 | RAD11 | ✅ | ✅ | ✅ | — |
| Delphi 12 Athens | 23.0 | RAD12 | ✅ | ✅ | ✅ | ✅ |
| Delphi 13 Florence | 37.0 | RAD13 | ✅ | ✅ | ✅ | ✅ |

`dcl Win64` apenas para D29+ (designide Win32-only em D24..D28 — limitação
documentada Embarcadero).

**Deploy:** 49 BPLs copiados para `Studio\<BDS>\Bpl\` (Win32 runtime + design,
Win64 runtime; Win64 design para D29/D37). Detalhes do padrão de deploy em
memory `project_zipfile_install_requires_bpl_deploy`.

### 16.9 Roadmap pós-v3.12

Não-bloqueante ao state atual (todos os itens detalhados em §17 com critérios
de aceite, esforço estimado e justificativa de adiamento):

- **v3.13** — wiring de **event firing** dentro de Open/Extract/Append nos 10
  componentes (events declarados na §16.2.1 mas só `OnFileChanged` dispara hoje
  em `SetFileName`)
- **v3.14** — wiring de **write encryption no 7z** (Password field LZMA2 +
  headers — AES-256 SHA-256 codec chain)
- **v3.15** — split/multi-volume real para 7z e CAB (write side; VolumeSize
  property já declarada)
- **v3.16** — preencher `FArchive*`/`FIsMulti*`/`FHostOS`/etc. em Arj/Iso/Rar/Lha
  parsers (read-only fields declarados na §16.2 mas com população deferida)
- **v3.17** — RFC 1952 gzip header parsing no `TGzipFile.Open` (popula CRC32,
  UncompressedSize, CompressedSize, FNAME, FCOMMENT, MTIME, FTEXT, FHCRC, OS,
  FEXTRA)
- **v4.0** — UnRAR C++ SDK static-link (150 .cpp) OU RAR encoder real

### 16.10 Cleanup de build artifacts (2026-05-27)

`zipfile/Lib/` continha 10 subdirs com 26 MB de build outputs intermediários
(`*.bpl`/`*.dcp`/`*.dcu` por IDE + `*.o` FPC). Limpeza executada em 2026-05-27:

```text
RAD10.1/  3.4M   60 files  →  removed
RAD10.2/  3.4M   60 files  →  removed
RAD10.3/  3.4M   60 files  →  removed
RAD10.4/  3.4M   60 files  →  removed
RAD11/    3.4M   60 files  →  removed
RAD12/    3.6M   66 files  →  removed
RAD13/    3.6M   64 files  →  removed
i386-win32/   465K  15 files  →  removed
i386-win64/   0     0 files  →  removed
x86_64-win64/ 1.4M  34 files  →  removed
                          Total: 24.5 MB freed
```

Build artifacts são **regeneráveis** via `dcc32 -B dclzipfileD<XX>.dpk -N<out>
-LN<out> -LE<out>`. BPLs deployadas em `BDSCOMMONDIR\Bpl[\Win64]\` continuam
intactas — apenas outputs intermediários foram limpos.

**Importante:** vendor OBJs vivem em `zipfile/sdk/` e `zipfile/deps/`, **não**
em `zipfile/Lib/`. O note "Infra build vendored em Lib/" do footer original
(pré-v3.12.2) estava incorreto — a `Lib/` é puramente build cache.

---

## 17. Pending Items for AI Analysis (post-v3.12.2)

> **Audience:** este documento foi escrito para que outra IA (próxima sessão
> Claude/GPT/etc.) consiga continuar o trabalho sem perder contexto.
> Cada item tem ID estável (`P##`), critérios de aceite, esforço estimado, e
> justificativa de adiamento. Quando completar um item, **mover para §17.X
> "Concluído"** ao invés de deletar — preserva trace histórico.

### 17.1 Event firing wiring (declarado mas não disparado)

Status pós-v3.12.1: **15 tipos de evento + ~145 properties** declaradas em
`src/ZipFile.Events.pas` e nos 10 componentes, mas apenas `OnFileChanged`
dispara (em `SetFileName` de cada componente). API surface estável; behavior
incremental.

| ID | Evento | Componentes alvo | Onde wirar | Effort |
| --- | --- | --- | --- | --- |
| P01 | `OnBeforeOpen` / `OnAfterOpen` | Todos 10 | Início/fim de `Open()` em cada unit (`ZipFile.pas` Activate, `SevenZFile.pas` Open, etc.). Cancel via `var Cancel: Boolean`. | 2h por componente × 10 = 20h |
| P02 | `OnBeforeClose` / `OnAfterClose` | Todos 10 | Início/fim de `Close()`. Cancel suprime Free do stream. | 1h × 10 = 10h |
| P03 | `OnEntryFound` | 9 (exceto TGzipFile) | Loop de `GetCDFileHeaders` (ZIP) / `ReadDirectory` (TAR) / `DoOpenAndIndex` (ISO/ARJ/LHA/RAR) / scan headers (7z/CAB). Skip via `var Skip: Boolean`. | 3h × 9 = 27h |
| P04 | `OnBeforeExtract` / `OnAfterExtract` / `OnExtractProgress` | Todos 10 | Em `GetFileStream`/`GetEntryStream`/`ReadAsBytes` antes de I/O. Per-entry progress: chunked copy 64KB com event a cada chunk. | 4h × 10 = 40h |
| P05 | `OnBeforeAdd` / `OnAfterAdd` / `OnAddProgress` | 6 write-capable (Zip/Tar/TarGz/Gzip/Cab/7z) | Em `AppendStream`/`AppendFileFromDisk`/`CreateFromFiles`. Skip via `var Skip: Boolean`. | 4h × 6 = 24h |
| P06 | `OnSolidBlockStart` / `OnSolidBlockEnd` / `OnFolderProgress` | TSevenZFile, TRarFile | 7z folder/solid block detection no parser; RAR5 solid flag. | 6h |
| P07 | `OnCompressionMethod` | TSevenZFile | Disparar em `Open` ao detectar codec ID por entry. | 2h |
| P08 | `OnAskPassword` | 7z, Zip, Cab, Rar | Quando `GetFileStream` encontra entry encrypted sem Password setado, disparar event antes de raise; retry com password retornado. | 3h × 4 = 12h |
| P09 | `OnReplaceQuery` | Todos 10 | Quando `Extract` colide com arquivo existente. Implementar cache de raReplaceAll/raSkipAll. | 4h |
| P10 | `OnVerify` | Todos com CRC (Zip/Tar/Gz/Rar/Lha/Cab) | Apos calcular CRC, chamar event antes de raise on mismatch. | 3h |
| P11 | `OnRequestVolume` / `OnVolumeChanged` | TSevenZFile, TZipFile, TCabFile, TArjFile, TRarFile | Read: handler retorna path do próximo volume. Write: notifica criação. Wiring depende de P15 (split write). | 6h |
| P12 | `OnError` / `OnWarning` / `OnLog` | Todos 10 | Wrap em try/except nos pontos críticos; `Handled := True` suprime exception. | 2h × 10 = 20h |

**Total esforço P01-P12:** ~150h. Pode ser dividido em waves v3.13.X.
**Justificativa:** API surface foi liberada antes do behavior para permitir que
consumidores subscrevam handlers sem esperar implementação completa.

### 17.2 Property population (read-only fields declarados mas vazios)

Status: muitos campos de header parsing foram **declarados** na §16.2 mas o
parser correspondente **não popula**. Componente compila OK mas o property
sempre retorna default (0/'').

| ID | Componente | Properties | Parser que precisa atualizar | Effort |
| --- | --- | --- | --- | --- |
| P20 | TZipFile | `FArchiveSize` (alias de GetFileSize), `FCompressionLevel`, `FAESKeySize`, `FArchiveComment`, `FStoreMSDosAttributes`, etc. | `GetEndOfCDRecord`/`GetCDFileHeaders` precisa salvar ArchiveComment do EOCDR | 4h |
| P21 | TSevenZFile | `FArchiveSize`, `FArchiveComment`, `FIsMultiVolume`, `FFormatVersionMajor/Minor`, `FHasHeaderEncryption`, `FIsSolidDetected` | C wrapper `SzCtx*` em `Open()`. ArchiveSize trivial (Stream.Size). | 5h |
| P22 | TCabFile | `FArchiveSize`, `FIsMultiCabinet`, `FVersionMajor/Minor`, `FHasReserveArea`, `FHasPrevCabinet`, `FHasNextCabinet`, `FTotalEntries`, `FPreviousCabinet`, `FNextCabinet` | FDI callback em `DoListEntries` — Wine FDI já tem os fields, só preciso copiar para FFields | 3h |
| P23 | TGzipFile | `FCRC32`, `FUncompressedSize`, `FCompressedSize`, `FTextMode`, `FHeaderCRC`, `FOriginalName` (read), `FComment` (read), `FOriginalTimestamp` (read), `FOSCode`, `FExtraField` | Implementar parser RFC 1952 completo em `Open()`. Atualmente Open só checa existência do arquivo. | 6h |
| P24 | TArjFile | `FHostOS`, `FArchiverVersion`, `FMinVersionToExtract`, `FFlags`, `FIsMultiVolume`, `FArchiveSize`, `FFileType`, `FFileAccessMode`, `FSecurityVersion`, `FHostData`, `FExtensionPos`, `FCreationDate`, `FModificationDate`, `FArjFlags2` | Estender `ParseHeader` para preencher todos os campos do ARJ main header (já tem o offset/dados, só precisa salvar) | 4h |
| P25 | TIsoFile | `FSystemID`, `FPublisherID`, `FPreparerID`, `FApplicationID`, `FCopyrightFile`, `FAbstractFile`, `FBibliographicFile`, `FCreationDate`, `FModificationDate`, `FVolumeSize`, `FBlockSize`, `FVolumeSetSize`, `FVolumeFlags`, `FVolumeSequenceNumber`, `FVolumeSetIdentifier`, `FFileStructureVersion`, `FPathTableSize`, `FExpirationDate`, `FEffectiveDate`, `FApplicationUse`, `FHasRockRidge`, `FHasElTorito`, `FHasUDFBridge`, `FBootCatalogLBA` | `FindBestVolumeDescriptor` já lê PVD bytes — estender para extrair todos os fields + scan secundário para Rock Ridge SUE + El Torito boot record | 12h |
| P26 | TLhaFile | `FHeaderLevel`, `FOSCode`, `FFirstMethod`, `FArchiveSize`, `FMinorVersion`, `FHeaderChecksum`, `FTotalPackedSize`, `FTotalOriginalSize`, `FHasComment`, `FArchiveComment`, `FCompressionRatio` | `ParseLevelXHeader` já lê os fields — só salvar em FFields e somar para totais | 3h |
| P27 | TRarFile | `FMajorVersion`, `FMinVersionToExtract`, `FArchiveFlags`, `FHasComment`, `FHasEncryption`, `FHasRecoveryRecord`, `FIsSolid`, `FIsMultiVolume`, `FVolumeNumber`, `FArchiveSize`, `FArchiverVersion`, `FArchiveComment`, `FRecoveryPercent`, `FHasAuthenticityVerification`, `FHasLockFlag`, `FIsFirstVolume`, `FIsLastVolume`, `FQuickOpenInfo`, `FArchiveNameInternal` | `ParseRar5` precisa parsear archive header flags + scan CMT/RR/AV/Lock subblocks | 8h |
| P28 | TTarFile | `FArchiveSize`, `FRecordSize` (computed = BlockSize × BlockingFactor) | Setter de BlockSize/BlockingFactor + read FArchiveSize de FStream.Size | 1h |
| P29 | TTarGzFile | `FArchiveSize`, `FGzipComment` (read), `FGzipOriginalName` (read), `FGzipTextMode`, `FGzipHeaderCRC` | Depende de P23 (gzip header parsing) | 2h (depois P23) |

**Total esforço P20-P29:** ~50h. **Justificativa:** declaração da API foi
priorizada para Object Inspector mostrar a surface completa; população
incremental por release.

### 17.3 Format-specific write features (não implementados)

| ID | Feature | Componente | Status atual | Esforço |
| --- | --- | --- | --- | --- |
| P40 | **7z write encryption** (AES-256 SHA-256) | TSevenZFile | `Password` + `EncryptHeaders` declarados, `CryptoMethod=szcAES256`, mas `CreateFromFilesLzma2` ignora. Precisa integrar AES filter no codec chain LZMA2. | 15h |
| P41 | **7z write split / multi-volume** | TSevenZFile | `VolumeSize` declarado mas `CreateFromFilesLzma2` escreve sempre single-file. Precisa chunking do output stream + emit `.7z.001`/`.002`/etc. | 10h |
| P42 | **7z LZMA params** | TSevenZFile | `LiteralContextBits`/`FastBytes`/`MatchFinder`/etc. declarados (14 properties em "LZMA Tuning"), mas `Lzma2Enc.c` recebe só `ALevel`. Estender para passar full `CLzmaEncProps`. | 8h |
| P43 | **7z extra methods** | TSevenZFile | `TSevenZMethod` enum tem 12 valores (Copy/LZMA2/LZMA/PPMd/Deflate/Deflate64/BZip2/Zstd/Brotli/LZ4/LZ5/Lizard). Implementado: Copy + LZMA2. Restantes precisam link de codecs externos. | 30h (cada um separado) |
| P44 | **7z BCJ/Delta filter chain** | TSevenZFile | `TSevenZFilter` declarado (None/Delta/BCJ/BCJ2/PPC/IA64/ARM/ARMT/SPARC/ARM64/RISCV). LZMA SDK tem encoders pra BCJ/BCJ2/Delta — só precisa link e codec chain emit. | 12h |
| P45 | **7z SelfExtracting (SFX)** | TSevenZFile | `SelfExtracting`+`SfxModule` declarados. Implementação trivial: prepend `7zSD.sfx` stub ao arquivo final. Falta empacotar/distribuir um stub SFX. | 4h + stub embedding |
| P46 | **CAB write MSZIP advanced** | TCabFile | `CompressionLevel` declarado (1..9), mas FCI usa nível default. Investigar se FCI permite tune do MSZIP/LZX level via tcompType masks. | 4h |
| P47 | **CAB multi-cabinet write** | TCabFile | `VolumeSize`/`SetID`/`CabinetIndex` declarados. FCI suporta nativamente (`SetID`+`iCabinet` em FCFOLDER), só precisa chain via FCI callbacks. | 6h |
| P48 | **CAB reserved areas write** | TCabFile | `HeaderReserveSize`/`FolderReserveSize`/`DataReserveSize` declarados. FCI tem `cbCFHeader`/`cbCFFolder`/`cbCFData` no estabelecimento — precisa wirar. | 3h |
| P49 | **TAR PAX extended headers** | TTarFile, TTarGzFile | `AddPaxExtensions` declarado. PAX exige writeprefix entries com `x` typeflag carregando key=value (atime, ctime, path > 100 chars, charset). | 8h |
| P50 | **TAR GNU sparse format** | TTarFile, TTarGzFile | `Sparse` declarado. GNU sparse usa typeflag `S` com map de holes. | 6h |
| P51 | **TAR ownership/permissions write** | TTarFile, TTarGzFile | `PreserveOwnership`/`UnixPermissions` declarados. Linux/macOS tem stat()/lstat() para uid/gid/mode — em Windows precisa fallback OwnerName/GroupName strings só | 4h |
| P52 | **Zip volume / spanned** | TZipFile | `VolumeSize` declarado mas TZipFile não tem split writer. PKWARE spec define `.z01`/`.z02`/`.zip` mas é raro em uso. | 12h |
| P53 | **Zip encryption upgrades** | TZipFile | `AESKeySize` declarado 128/192/256, mas AE-2 sempre 256 hoje. Permitir downsize (compat com ZipCrypto legacy). | 3h |
| P54 | **Zip archive comment** | TZipFile | `ArchiveComment` declarado mas EOCDR comment não escrito em writes. Trivial (max 65535 bytes). | 2h |
| P55 | **Zip Unix/NT attributes** | TZipFile | `StoreUnixAttributes`/`StoreNTSecurity` declarados. Info-ZIP extra field 0x756e (Unix) + 0x4453 (NT). | 6h |
| P56 | **Gzip RFC 1952 full write** | TGzipFile | `Comment`/`OriginalTimestamp`/`OSCode`/`TextMode`/`HeaderCRC`/`ExtraField` declarados — write não inclui esses campos no header. | 4h |
| P57 | **Gzip strategy / XFL byte** | TGzipFile | `Strategy`+`XFL` declarados. zlib `deflateInit2` recebe strategy — só wirar. | 2h |
| P58 | **ARJ method 1-9 read** | TArjFile | Atualmente só method 0 (Store) decompresses. Methods 1-4 são LZ77 variants. SDK precisa msgbind toolingl (vide §15.5h). | 25h |
| P59 | **LHA -lh1- a -lh7- runtime** | TLhaFile | Pascal decoder port de v3.3.2 compila mas sem fixture .lh5 validada. Precisa LHa CLI standalone OU vendor lhasa lib. | 12h |
| P60 | **RAR methods 1-5** | TRarFile | LZSS + PPMd. Requer UnRAR SDK static-link 150 .cpp + C++ ABI stubs + bcc32x. **Bloqueado** por escopo. | 25-40h |

**Total esforço P40-P60:** ~150-250h (depende de quanto se quer dos métodos
opcionais). **Justificativa:** os format-specific writes são otimizações;
ZIP Deflate/Store+LZMA2+CAB MSZIP+Tar.Gz já cobrem >95% dos casos reais.

### 17.4 Documentation gaps

| ID | Item | Effort |
| --- | --- | --- |
| P70 | **Per-property XML doc comments** — properties novas (P20-P29 fields + write knobs) precisam de `///` summaries para hover-help no IDE | 10h |
| P71 | **Examples por componente** — `Documentation/examples/` tem só Zip; criar `7z-create.pas`, `tar-list.pas`, `cab-extract.pas`, `iso-readonly.pas`, etc. | 8h |
| P72 | **Migration guide v2→v3** — documentar rename de `Tar.TarFile` → `TarFile`, palette `Misc` → `ZipCompress`, propriedade `EntryCount` (era método) | 3h |
| P73 | **Event handler examples** — pequenas demos de `OnAskPassword` com `InputQuery`, `OnReplaceQuery` com dialog choice, `OnProgress` com `TProgressBar` | 4h |

### 17.5 Testing gaps

| ID | Item | Effort |
| --- | --- | --- |
| P80 | **Tests para event surface** — nenhum `ZipFile.Tests.Events.pas` ainda. Cada event precisa de fixture validando que dispara nos pontos corretos com args certos. **Bloqueia P01-P12** (sem testes, regressões silenciosas) | 20h |
| P81 | **Tests para property population** — `FArchiveSize`/`FIsMultiVolume`/etc. precisam fixture com archive conhecido + assert no value parseado | 15h |
| P82 | **Lazarus FPC build smoke** — após v3.12 renames, LPK rebuild não foi validado em Lazarus IDE real (só compilação CLI FPC dos units individuais) | 4h |
| P83 | **Multi-volume read fixture** — `.7z.001`+`.7z.002` archive sintético para validar IsMultiVolume detection (depois de P21) | 3h |
| P84 | **AES-256 round-trip integration** — criar zip com WinZip/7-Zip CLI, ler em TZipFile, validar GetEntryStream produz plaintext (auto-detect via bit 0 + extra 0x9901) | 4h |

### 17.6 Build / IDE issues conhecidos

| ID | Item | Status | Effort |
| --- | --- | --- | --- |
| P90 | **C++Builder constructor warning** — `W1029 Duplicate constructor 'TZipFileBuilder.CreateOpen'` em todos os builds runtime. Não bloqueia mas C++Builder users não conseguem usar o overload. | low priority | 1h |
| P91 | **D24..D28 dcl Win64** — design BPLs Win32-only nesses IDEs (designide é 32-bit pré-D29). Não é nosso bug — limitação Embarcadero. | accepted limitation | n/a |
| P92 | **FPC Win64 CAB AV** em `FCIFlushCabinet` (bug interno em fci.obj mingw COFF). Win32 FPC + Delphi Win32/Win64 todos OK. | accepted limitation | 8h (debug interno fci.obj) |
| P93 | **Splash registration timing** — `BorlandIDEServices` é nil quando `IOTASplashScreenServices` inicializa (doc IOTA explícita). Workaround: usar global `SplashScreenServices` direto. Já implementado em `ZipCompress.SplashReg.pas`. | done | n/a |
| P94 | **brcc32 BMP v4/v5 rejection** — `System.Drawing.Bitmap.Save` produz BMP v4+. brcc32 só aceita v3 (BITMAPINFOHEADER 40 bytes). Workaround: helper `Save-Bmp24v3` em PowerShell escreve header manualmente. Já implementado. | done | n/a |
| P95 | **Wikimedia thumbnail size 400** — apenas 120/250/500 funcionam (HTTP 400 nos outros). Não relevante mais (decidimos uniform stylized — vide §16.6) | done (decision) | n/a |
| P96 | **TZipFile property categories** — `zipfileReg.pas:RegisterTZipFileCategories` lista apenas 12 properties originais. Properties novas v3.12 (`CompressionLevel`/`AESKeySize`/`ArchiveComment`/`VolumeSize`/`StoreMSDosAttributes`/`StoreUnixAttributes`/`StoreNTSecurity`) ainda não tem `RegisterPropertyInCategory` calls. | open | 30min |

### 17.7 Bzip2 component (decisão pendente)

| ID | Item | Decisão |
| --- | --- | --- |
| P97 | **TBz2File TComponent** — `src/Bzip2.Bzip2Stream.pas` tem apenas `TBz2DecompressStream`/`TBz2CompressStream` (TStream descendants). Não tem TComponent para palette. Justificativa para não criar: bzip2 é stream-only por design (single-file compression, não archive); `TGzipFile` já cobre o use case análogo. Se quiser TBz2File, ~80 LOC modelando em TGzipFile. | low priority |

### 17.8 Icon revisitation (opcional)

| ID | Item | Status |
| --- | --- | --- |
| P98 | **Re-evaluate ícones uniformes vs híbridos** — `packages/icons/source/` preserva: `7Zip_500.png` (Wikimedia CC0 7-Zip), `Gzip_500.png` (Wikimedia PD), SVG originais. Decisão atual (§16.6) usa uniform stylized para coerência. Se palette ficar muito "samey", revisitar com vendoring de ícones genéricos MIT (Tabler Icons, Heroicons) para indicar formato sem trademark issues. | decision needed by stakeholder |

### 17.9 Concluído (audit trail — não deletar)

Items finalizados em v3.12:

- ✅ **C01** — Palette branded `ZipCompress` (era `Misc`) — §16.1.1
- ✅ **C02** — 10 componentes registrados (era 1 — só TZipFile) — §16.2
- ✅ **C03** — TGzipFile NEW component (single-file gzip) — §16.1.3
- ✅ **C04** — Property surface explosion (22→248 properties, +1027%) — §16.2
- ✅ **C05** — Event surface (2→145 events, +7150%) — §16.2.1
- ✅ **C06** — `src/ZipFile.Events.pas` com 15 tipos de event compartilhados — §16.2.1
- ✅ **C07** — Property categories no Object Inspector — §16.3
- ✅ **C08** — IDE splash + About box integration — §16.5
- ✅ **C09** — Unit naming uniformizado (rename `Tar.TarFile`→`TarFile` etc., 9 units) — §16.1.8
- ✅ **C10** — Multi-IDE rollout 7 IDEs D24..D37, 49 BPLs deployadas — §16.8
- ✅ **C11** — Ícones uniformes 24x24 com gradient+rounded+gloss+text — §16.6
- ✅ **C12** — Cleanup `Lib/` (24.5 MB intermediate build artifacts) — §16.10
- ✅ **C13** — DCR contém 10 BMPs (18200 bytes) — §16.6
- ✅ **C14** — DPK runtime contém ZipFile.Events + 9 unit renames — §16.7
- ✅ **C15** — LPK Lazarus (Item1..Item22) sincronizada com Delphi DPK — §16.7

### 17.10 Quick-start para próxima IA

Se você é a próxima IA pegando este projeto:

1. **Leia primeiro** o §16 inteiro (mais relevante que §1-15 que são histórico)
2. **Build matrix** está em §16.8 — rebuild via `dcc32`/`dcc64` direto (NÃO use msbuild — vide regra em CLAUDE.md raiz do workspace)
3. **Prioridade sugerida** para próximas waves:
   - **v3.13** = P20-P29 (property population) — baixo risco, alto valor visual (Object Inspector cheio em runtime)
   - **v3.14** = P03 + P04 (OnEntryFound + OnExtract events) — viabiliza progress bars / file listing UIs
   - **v3.15** = P40 + P41 (7z encryption + multi-volume write) — features comerciais
   - **v3.16** = P70 + P73 (XML docs + examples) — onboarding de novos users
   - **v4.0** = P60 (UnRAR encoder) — major undertaking, decidir se viável
4. **NÃO mexa** em ícones/palette/splash sem ler §16.6 inteiro — múltiplas iterações já testadas, decisão atual é a ótima
5. **NÃO baixe** logos de WinRAR/WinZip/etc. — trademark issues, vide §16.6 decisão 3
6. **Memory persistente** (Claude Code): rever entries `project_zipfile_*` para contexto adicional

**Convenções de PR:**

- Nome de release: `v3.X` ou `v3.X.Y` (Y para hotfix)
- Tag: `zipfile-v3.X` no commit final
- Cada item P## deve gerar 1 commit referenciando o ID no message
- SPEC atualizado a cada release (mover P## para §17.9 Concluído)

---

**Fim do SPEC v3.12.2.** Estado atual: **22 releases v3.x entregues**
(v3.0..v3.12.2, fechamento 2026-05-27).

**Cobertura de formatos:**

- **READ+WRITE production-ready** (10): ZIP, TAR, Gzip, Tar.Gz, 7zip (Store+LZMA2),
  CAB (Store+MSZIP), BZIP2, Z (LZW), UUE — Delphi+FPC multi-plataforma
- **READ-only production-ready** (3): ISO 9660+Joliet, ARJ Store, RAR5 Store —
  pure-pascal 5 plataformas
- **Compile-verified, runtime fixture pendente** (1): LHA -lh4-/5/6/7 Pascal
  decoder (algoritmo port direto SDK)

**Design-time:** palette `ZipCompress` × 10 componentes × ~248 properties + ~145
events + IOTA splash/About + 10 ícones uniformes premium. 49 BPLs deployados
em 7 IDEs Delphi (D24..D37, Win32 + Win64 onde aplicável).

**Build artifacts:** `Lib/` limpo (24.5 MB freed em 2026-05-27); regeneráveis
via `dcc32 -B`. BPLs deployadas em `BDSCOMMONDIR\Bpl[\Win64]\` continuam intactas.

**Infra vendored** (em `zipfile/sdk/` e `zipfile/deps/`, NÃO em `Lib/`):

- LZMA SDK 24.07 (lzma_obj_{win32,win64,fpc_win32,fpc_win64}) + 7z container
- bzip2 (bzip2_obj_{4 toolchains})
- Wine cabinet FDI/FCI (cabnet_obj_{4 toolchains})
- LHA decoder cores (lha_obj_{4 toolchains}, 36/36 OBJ)
- zlib 1.3.2.1 (zlib_obj_fpc_{win32,win64})
- ARJ skeleton dirs (build script presente, deps msgbind bloqueia)
- gcc-mingw-w64 16.1.0 (Windows COFF para FPC)
- gcc-linux-musl 15.2.0 (ELF Linux cross, ainda não integrado)

**Pendências:** §17 lista 30+ items (P01..P98) com effort estimado total
~400-550h dependendo de escopo final. Items críticos para próxima iteração
identificados em §17.10 quick-start.
