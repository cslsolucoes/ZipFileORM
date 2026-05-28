/* SevenZCombined.c
 *
 * Combina 7zArcIn.c + 7zDec.c em um único OBJ. Motivação: as duas units
 * têm dependências mútuas (7zArcIn chama SzAr_DecodeFolder definido em
 * 7zDec; 7zDec chama SzGetNextFolderItem/SzAr_GetFolderUnpackSize
 * definidos em 7zArcIn). O linker single-pass do Delphi não resolve
 * essas refs mútuas entre dois OBJs separados — colocando-as num único
 * compilation unit, os símbolos resolvem-se internamente.
 *
 * Compilado por Build-LzmaObjs.ps1 (substituindo 7zArcIn.c + 7zDec.c).
 */

#include "7zArcIn.c"
#include "7zDec.c"
