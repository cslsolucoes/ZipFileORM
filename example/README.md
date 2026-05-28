# ZipFileORM examples

Exemplos completos cobrindo TODOS os formatos suportados, com legacy API
(`TXxxFile` direta) **e** fluent builder API (`Xxx.NewArchive(...)`).

## Estrutura

```
example/
├── README.md                       (este arquivo)
├── 01_zip_example.dpr              ZIP — TZipFile + Zip.Fluent (todos params)
├── 02_tar_example.dpr              TAR / TarGz — TTarFile + Tar.Fluent
├── 03_sevenz_example.dpr           7zip — TSevenZFile + SevenZ.Fluent (Store+LZMA2)
├── 04_cab_example.dpr              CAB — TCabFile + Cab.Fluent (Store+MSZIP)
├── 05_bzip2_example.dpr            BZIP2 — funções + Bzip2.Fluent
├── 06_iso_example.dpr              ISO 9660+Joliet — TIsoFile (READ-only)
├── 07_lha_example.dpr              LHA — TLhaFile (READ -lh0- e -lh5-)
├── 08_arj_example.dpr              ARJ — TArjFile (READ method 0)
├── 09_rar_example.dpr              RAR5 — TRarFile (READ method 0)
├── 10_z_example.dpr                Z LZW — funções + ZCompress.Fluent
├── 11_uue_example.dpr              UUE — funções + UUE.Fluent
├── 12_archive_auto_example.dpr     Auto-detect via Archive.Open
├── Build-All-Examples.ps1          compila e roda todos
└── _legacy/                        vendor Lazarus GUI app (referência)
```

## Compilar e rodar

**Todos de uma vez:**

```powershell
.\Build-All-Examples.ps1
```

**Individual (Delphi Win32):**

```powershell
$bds = "C:\Program Files (x86)\Embarcadero\Studio\23.0"
& "$bds\bin\dcc32.exe" -Q -B -NSSystem;Winapi -U..\src 01_zip_example.dpr
.\01_zip_example.exe
```

**Individual (FPC):**

```powershell
& 'D:\fpc\fpc\bin\i386-win32\ppc386.exe' -TWin32 -Fu..\src 01_zip_example.dpr
```

## Padrão dos exemplos

Cada exemplo segue o mesmo template:

1. **Setup**: gera fixture inline (TBytes, arquivos temporários)
2. **Legacy API**: demonstra `TXxxFile` direto (Create, Active, Append, Read)
3. **Fluent API**: demonstra `Xxx.NewArchive(...).With*.Execute`
4. **Read-back**: valida round-trip
5. **Cleanup**: remove temporários

## Cobertura por formato

| Formato       | READ | WRITE        | Stream | Fluent | Plataformas        |
|---------------|------|--------------|--------|--------|--------------------|
| ZIP           | ✅   | ✅           | ✅     | ✅     | Delphi+FPC 5 plats |
| TAR           | ✅   | ✅           | ✅     | ✅     | 5 plats            |
| Gzip          | ✅   | ✅           | ✅     | ✅     | 5 plats            |
| TarGz         | ✅   | ✅           | ✅     | ✅     | 5 plats            |
| 7zip          | ✅   | ✅ Store+LZMA2 | -    | ✅     | Delphi Win32/64    |
| CAB           | ✅   | ✅ Store+MSZIP | -    | ✅     | 4 toolchains       |
| BZIP2         | ✅   | ✅           | ✅     | ✅     | 4 toolchains       |
| ISO 9660      | ✅   | -            | -      | -      | 5 plats            |
| LHA           | ✅   | -            | -      | -      | 5 plats            |
| ARJ           | ✅ method 0 | -      | -      | -      | 5 plats            |
| RAR5          | ✅ method 0 | -      | -      | -      | 5 plats            |
| Z (LZW)       | ✅   | ✅           | ✅     | ✅     | 5 plats            |
| UUE           | ✅   | ✅           | -      | ✅     | 5 plats            |

## Legacy reference

`_legacy/` contém o exemplo Lazarus GUI original (project1.lpi) preservado
como referência histórica do package vendor.
