(* zipfileReg.pas
   Delphi-only design-time Register unit for the ZipFile package.
   Used by dclZipFileORM<DXX>.dpk only. Loads component glyph via $R ZipFile.dcr.

   Registers the full multi-format archive component family of ZipFile v3.x on
   the Tool Palette page "ZipFileORM":

     Zip family:
       TZipFile      â€” Zip (AES-256, LZMA, ZIP64, UTF-8, Progress)
     Tar family (separados intencionalmente):
       TTarFile      â€” Tar puro (POSIX ustar)
       TTarGzFile    â€” Tar + Gzip combo (.tar.gz / .tgz)
     Gzip puro:
       TGzipFile     â€” single-file gzip (.log.gz, .sql.gz)
     Microsoft Cabinet:
       TCabFile      â€” .cab
     Outros formatos (read-only ou read+write):
       TSevenZFile   â€” 7zip (read-only Win32)
       TArjFile      â€” ARJ
       TIsoFile      â€” ISO 9660 / Joliet
       TLhaFile      â€” LHA / LZH
       TRarFile      â€” RAR (RAR4 + RAR5 detect)

   Plus property categories â€” Object Inspector agrupa por feature area. *)
unit zipfileReg;

interface

procedure Register;

implementation

uses
  Classes,
  DesignIntf,
  DesignEditors,
  ZipFile,
  TarFile,
  TarGzFile,
  GzipFile,
  CabFile,
  SevenZFile,
  ArjFile,
  IsoFile,
  LhaFile,
  RarFile;

// Resource ZipFileORM.dcr Ã© incluÃ­do pelo .dpk design-time (nÃ£o duplicar aqui).

const
  cPalettePage = 'ZipFileORM';

procedure RegisterTZipFileCategories;
begin
  // Encryption â€” AES-256 WinZip-AE-2 (v1.9+).
  RegisterPropertyInCategory('Encryption', TZipFile, 'UseAES');
  RegisterPropertyInCategory('Encryption', TZipFile, 'Password');

  // Compression â€” Deflate / Store / LZMA + recompression policy.
  RegisterPropertyInCategory('Compression', TZipFile, 'Compression');
  RegisterPropertyInCategory('Compression', TZipFile, 'ReCompression');
  RegisterPropertyInCategory('Compression', TZipFile, 'UseLZMA');

  // ZIP64 â€” large-archive support (>4 GiB or >65535 entries).
  RegisterPropertyInCategory('ZIP64', TZipFile, 'ForceZip64');

  // Encoding â€” UTF-8 filename flag (EFS bit 11).
  RegisterPropertyInCategory('Encoding', TZipFile, 'UseUtf8');

  // File â€” archive path / open state / size.
  RegisterPropertyInCategory('File', TZipFile, 'Active');
  RegisterPropertyInCategory('File', TZipFile, 'FileName');
  RegisterPropertyInCategory('File', TZipFile, 'FileSize');
end;

procedure RegisterArchiveComponentCategories;
begin
  // ---------- 7zip ----------
  RegisterPropertyInCategory('File',        TSevenZFile, 'Active');
  RegisterPropertyInCategory('File',        TSevenZFile, 'FileName');
  RegisterPropertyInCategory('Compression', TSevenZFile, 'CompressionMethod');
  RegisterPropertyInCategory('Compression', TSevenZFile, 'CompressionLevel');
  RegisterPropertyInCategory('Compression', TSevenZFile, 'MultiThreaded');
  RegisterPropertyInCategory('Compression', TSevenZFile, 'ThreadCount');
  RegisterPropertyInCategory('Compression', TSevenZFile, 'DictionarySize');
  RegisterPropertyInCategory('Compression', TSevenZFile, 'SolidArchive');
  RegisterPropertyInCategory('Compression', TSevenZFile, 'SolidBlockSize');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'Algorithm');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'FastBytes');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'MatchFinder');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'MatchCycles');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'LiteralContextBits');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'LiteralPosBits');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'PosBits');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'NumHashBytes');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'BlockSize');
  RegisterPropertyInCategory('LZMA Tuning', TSevenZFile, 'WriteEndMark');
  RegisterPropertyInCategory('Filter',      TSevenZFile, 'PreFilter');
  RegisterPropertyInCategory('Filter',      TSevenZFile, 'DeltaDistance');
  RegisterPropertyInCategory('Encryption',  TSevenZFile, 'Password');
  RegisterPropertyInCategory('Encryption',  TSevenZFile, 'CryptoMethod');
  RegisterPropertyInCategory('Encryption',  TSevenZFile, 'EncryptHeaders');
  RegisterPropertyInCategory('Archive Flags', TSevenZFile, 'HeaderCompression');
  RegisterPropertyInCategory('Archive Flags', TSevenZFile, 'SortByType');
  RegisterPropertyInCategory('Archive Flags', TSevenZFile, 'StoreLastModified');
  RegisterPropertyInCategory('Archive Flags', TSevenZFile, 'StoreCreationTime');
  RegisterPropertyInCategory('Archive Flags', TSevenZFile, 'StoreLastAccess');
  RegisterPropertyInCategory('Archive Flags', TSevenZFile, 'StoreNTSecurity');
  RegisterPropertyInCategory('Archive Flags', TSevenZFile, 'AnalysisLevel');
  RegisterPropertyInCategory('SFX',         TSevenZFile, 'SelfExtracting');
  RegisterPropertyInCategory('SFX',         TSevenZFile, 'SfxModule');
  RegisterPropertyInCategory('Volume',      TSevenZFile, 'VolumeSize');
  RegisterPropertyInCategory('Info',        TSevenZFile, 'EntryCount');
  RegisterPropertyInCategory('Info',        TSevenZFile, 'ArchiveSize');
  RegisterPropertyInCategory('Info',        TSevenZFile, 'ArchiveComment');
  RegisterPropertyInCategory('Info',        TSevenZFile, 'IsMultiVolume');
  RegisterPropertyInCategory('Info',        TSevenZFile, 'FormatVersionMajor');
  RegisterPropertyInCategory('Info',        TSevenZFile, 'FormatVersionMinor');
  RegisterPropertyInCategory('Info',        TSevenZFile, 'HasHeaderEncryption');
  RegisterPropertyInCategory('Info',        TSevenZFile, 'IsSolidDetected');

  // ---------- Tar ----------
  RegisterPropertyInCategory('File',        TTarFile, 'Active');
  RegisterPropertyInCategory('File',        TTarFile, 'FileName');
  RegisterPropertyInCategory('Format',      TTarFile, 'Format');
  RegisterPropertyInCategory('Metadata',    TTarFile, 'PreserveOwnership');
  RegisterPropertyInCategory('Metadata',    TTarFile, 'PreserveTimestamps');
  RegisterPropertyInCategory('Metadata',    TTarFile, 'DefaultMode');
  RegisterPropertyInCategory('Metadata',    TTarFile, 'DefaultUid');
  RegisterPropertyInCategory('Metadata',    TTarFile, 'DefaultGid');
  RegisterPropertyInCategory('Metadata',    TTarFile, 'OwnerName');
  RegisterPropertyInCategory('Metadata',    TTarFile, 'GroupName');
  RegisterPropertyInCategory('Info',        TTarFile, 'EntryCount');

  // ---------- Tar.gz ----------
  RegisterPropertyInCategory('File',        TTarGzFile, 'Active');
  RegisterPropertyInCategory('File',        TTarGzFile, 'FileName');
  RegisterPropertyInCategory('Compression', TTarGzFile, 'GzipLevel');
  RegisterPropertyInCategory('Compression', TTarGzFile, 'GzipComment');
  RegisterPropertyInCategory('Compression', TTarGzFile, 'GzipOriginalName');
  RegisterPropertyInCategory('Format',      TTarGzFile, 'Format');
  RegisterPropertyInCategory('Metadata',    TTarGzFile, 'PreserveOwnership');
  RegisterPropertyInCategory('Metadata',    TTarGzFile, 'PreserveTimestamps');
  RegisterPropertyInCategory('Metadata',    TTarGzFile, 'DefaultMode');
  RegisterPropertyInCategory('Metadata',    TTarGzFile, 'OwnerName');
  RegisterPropertyInCategory('Metadata',    TTarGzFile, 'GroupName');
  RegisterPropertyInCategory('Info',        TTarGzFile, 'EntryCount');

  // ---------- Gzip (single-file) ----------
  RegisterPropertyInCategory('File',        TGzipFile, 'Active');
  RegisterPropertyInCategory('File',        TGzipFile, 'FileName');
  RegisterPropertyInCategory('Compression', TGzipFile, 'Level');
  RegisterPropertyInCategory('Metadata',    TGzipFile, 'OriginalName');
  RegisterPropertyInCategory('Metadata',    TGzipFile, 'Comment');
  RegisterPropertyInCategory('Metadata',    TGzipFile, 'OriginalTimestamp');
  RegisterPropertyInCategory('Metadata',    TGzipFile, 'OSCode');
  RegisterPropertyInCategory('Info',        TGzipFile, 'CRC32');
  RegisterPropertyInCategory('Info',        TGzipFile, 'UncompressedSize');
  RegisterPropertyInCategory('Info',        TGzipFile, 'CompressedSize');

  // ---------- Microsoft Cabinet ----------
  RegisterPropertyInCategory('File',        TCabFile, 'Active');
  RegisterPropertyInCategory('File',        TCabFile, 'FileName');
  RegisterPropertyInCategory('Compression', TCabFile, 'Compression');
  RegisterPropertyInCategory('Compression', TCabFile, 'CompressionLevel');
  RegisterPropertyInCategory('Cabinet Set', TCabFile, 'SetID');
  RegisterPropertyInCategory('Cabinet Set', TCabFile, 'CabinetIndex');
  RegisterPropertyInCategory('Volume',      TCabFile, 'VolumeSize');
  RegisterPropertyInCategory('Cabinet Set', TCabFile, 'ReserveSize');
  RegisterPropertyInCategory('Extraction',  TCabFile, 'ExtractTarget');
  RegisterPropertyInCategory('Info',        TCabFile, 'EntryCount');
  RegisterPropertyInCategory('Info',        TCabFile, 'ArchiveSize');
  RegisterPropertyInCategory('Info',        TCabFile, 'IsMultiCabinet');

  // ---------- ARJ ----------
  RegisterPropertyInCategory('File',        TArjFile, 'Active');
  RegisterPropertyInCategory('File',        TArjFile, 'FileName');
  RegisterPropertyInCategory('Info',        TArjFile, 'EntryCount');
  RegisterPropertyInCategory('Info',        TArjFile, 'ArchiveName');
  RegisterPropertyInCategory('Info',        TArjFile, 'ArchiveComment');
  RegisterPropertyInCategory('Info',        TArjFile, 'HostOS');
  RegisterPropertyInCategory('Info',        TArjFile, 'ArchiverVersion');
  RegisterPropertyInCategory('Info',        TArjFile, 'MinVersionToExtract');
  RegisterPropertyInCategory('Info',        TArjFile, 'Flags');
  RegisterPropertyInCategory('Info',        TArjFile, 'IsMultiVolume');
  RegisterPropertyInCategory('Info',        TArjFile, 'ArchiveSize');

  // ---------- ISO 9660 / Joliet ----------
  RegisterPropertyInCategory('File',        TIsoFile, 'Active');
  RegisterPropertyInCategory('File',        TIsoFile, 'FileName');
  RegisterPropertyInCategory('Info',        TIsoFile, 'EntryCount');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'JolietActive');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'VolumeID');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'SystemID');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'PublisherID');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'PreparerID');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'ApplicationID');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'CopyrightFile');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'AbstractFile');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'BibliographicFile');
  RegisterPropertyInCategory('Dates',       TIsoFile, 'CreationDate');
  RegisterPropertyInCategory('Dates',       TIsoFile, 'ModificationDate');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'VolumeSize');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'BlockSize');
  RegisterPropertyInCategory('Volume Descriptor', TIsoFile, 'VolumeSetSize');
  RegisterPropertyInCategory('Info',        TIsoFile, 'ArchiveSize');

  // ---------- LHA / LZH ----------
  RegisterPropertyInCategory('File',        TLhaFile, 'Active');
  RegisterPropertyInCategory('File',        TLhaFile, 'FileName');
  RegisterPropertyInCategory('Info',        TLhaFile, 'EntryCount');
  RegisterPropertyInCategory('Info',        TLhaFile, 'HeaderLevel');
  RegisterPropertyInCategory('Info',        TLhaFile, 'OSCode');
  RegisterPropertyInCategory('Info',        TLhaFile, 'FirstMethod');
  RegisterPropertyInCategory('Info',        TLhaFile, 'ArchiveSize');

  // ---------- RAR ----------
  RegisterPropertyInCategory('File',        TRarFile, 'Active');
  RegisterPropertyInCategory('File',        TRarFile, 'FileName');
  RegisterPropertyInCategory('Info',        TRarFile, 'EntryCount');
  RegisterPropertyInCategory('Info',        TRarFile, 'IsRar5');
  RegisterPropertyInCategory('Info',        TRarFile, 'MajorVersion');
  RegisterPropertyInCategory('Info',        TRarFile, 'MinVersionToExtract');
  RegisterPropertyInCategory('Info',        TRarFile, 'ArchiveFlags');
  RegisterPropertyInCategory('Info',        TRarFile, 'HasComment');
  RegisterPropertyInCategory('Info',        TRarFile, 'HasEncryption');
  RegisterPropertyInCategory('Info',        TRarFile, 'HasRecoveryRecord');
  RegisterPropertyInCategory('Info',        TRarFile, 'IsSolid');
  RegisterPropertyInCategory('Info',        TRarFile, 'IsMultiVolume');
  RegisterPropertyInCategory('Info',        TRarFile, 'VolumeNumber');
  RegisterPropertyInCategory('Info',        TRarFile, 'ArchiveSize');
end;

procedure Register;
begin
  RegisterComponents(cPalettePage,
    [TZipFile,
     TTarFile,
     TTarGzFile,
     TGzipFile,
     TCabFile,
     TSevenZFile,
     TArjFile,
     TIsoFile,
     TLhaFile,
     TRarFile]);

  RegisterTZipFileCategories;
  RegisterArchiveComponentCategories;
end;

end.
