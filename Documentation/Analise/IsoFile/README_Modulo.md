---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo IsoFile

## O que faz

Implementa `TIsoFile`, componente TComponent de leitura de imagens ISO 9660 com extensoes Joliet. Navega a estrutura de diretorios e extrai arquivos de imagens de CD/DVD sem montar o disco. E um dos quatro formatos read-only da biblioteca.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `IsoFile.pas` | 581 | Classe `TIsoFile` — parser ISO 9660 + Joliet |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (extracao) | Completo |
| ISO 9660 base | Sim |
| Extensoes Joliet (nomes longos Unicode) | Sim |
| Rock Ridge (metadados Unix) | Nao |
| Write (criacao de imagem) | Nao suportado |

## Propriedades especificas

`TIsoFile` expoe propriedades da categoria **Volume Descriptor**: `VolumeID`, `SystemID`, `PublisherID`, `VolumeSize`, `LogicalBlockSize`.

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Classe em ficheiro unico `IsoFile.pas`. Sem sub-modulos.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `IsoFile.pas` | `TIsoFile` + metodo fluente de abertura inline |
| `IsoFile.Interfaces.pas` | `IIsoFile` (read-only contract) |
| `IsoFile.Consts.pas` | Resourcestrings rsIso* + magic `CD001` + offsets PVD |
| `IsoFile.Types.pas` | `TIsoPVD` record, `TIsoDirectoryRecord` record, `TIsoVolumeDescriptorType` enum |
| `IsoFile.Exceptions.pas` | `EIsoFile`, `EIsoCorrupted`, `EIsoUnsupportedVolume` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §11, §17 — P20, P26*
