---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — TarGzFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only do header gzip (OS, mtime, original size) | Alta | ~3h |
| P03 | Disparo de evento `OnEntryFound` | Media | ~3h |
| P04 | Disparo de evento `OnExtract` | Media | ~3h |
| P70 | Documentacao XML inline | Baixa | ~2h |

## Gaps especificos do split v4.1

- Nenhuma interface `ITarGzFile` publicada — consumidores dependem da classe concreta.
- `Tar.GzipStream.pas` nao esta em `Commons.*` — pode causar dependencia circular se `TarFile` tambem precisar e os modulos forem reorganizados.
- Sem `TarGzFile.Fluent.pas` proprio (pode ser que fluent nao tenha sido implementado para este componente — verificar).
- `TarGzFile.pas` com apenas 384 linhas: provavel que muita logica esteja delegada sem interface clara.

## Pendencias de testes

- Nenhum teste de arquivo `.tar.gz` gerado no Linux e extraido no Windows (line endings + permissoes).
- Nenhum teste de compressao nivel 1 vs nivel 9 (velocidade vs razao).
- Cobertura de streaming progressivo: ausente.
