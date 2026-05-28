/* c_defs.h — stub compat para build SDK static-link (Windows toolchains).
 *
 * O ARJ SDK original espera c_defs.h gerado por gnu/configure (autoconf).
 * Em build cross-platform Windows, fornecemos defaults sane:
 *  - COMPILER = generic
 *  - TARGET = DOS (smallest path)
 *  - SFX_LEVEL = ARJSFXJR (smallest, exclui CLI deps massivas)
 *
 * Este file eh para Build-ArjObjs.ps1 — adicionar `-I<path>/compat`.
 */
#ifndef C_DEFS_INCLUDED
#define C_DEFS_INCLUDED

/* Endianness — assume little-endian Windows */
#define ARJ_LITTLE_ENDIAN 1
#define ARJ_BIG_ENDIAN    0

/* If SFX_LEVEL not pre-set, default ARJSFXJR (smallest) */
#ifndef SFX_LEVEL
#define SFX_LEVEL 1
#endif

/* TARGET enum from environ.h. 1 = DOS (smallest config). */
#ifndef TARGET
#define TARGET 1
#endif

/* COMPILER enum from environ.h. Use generic value. */
#ifndef COMPILER
#define COMPILER 99
#endif

#endif /* C_DEFS_INCLUDED */
