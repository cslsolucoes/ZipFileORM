/*  utime.h

    Definitions for utime() function.

*/

/*
 *      C/C++ Run Time Library - Version 37.0
 *
 *      Copyright (c) 1991, 2026 by Embarcadero Technologies, Inc.
 *      All Rights Reserved.
 *
 */

/* $Revision: 38025 $ */

#ifndef __UTIME_H
#define __UTIME_H

#include <_stddef.h>
#include <sys\types.h>
#include <sys\utime.h>

#if !defined(RC_INVOKED)

#if defined(__STDC__)
#pragma warn -nak
#endif

#pragma pack(push, _CRT_PACKING)

#endif  /* !RC_INVOKED */

/* Structure passed to utime containing file times
 */
struct utimbuf
{
    _TIME_T  actime;         /* access time (used on NTFS) */
    _TIME_T  modtime;        /* modification time */
};

int _RTLENTRY _EXPFUNC utime(const char * __path,
                             const struct utimbuf *__times);

#if !defined(RC_INVOKED)

#pragma pack(pop)       /* restore default packing */

#if defined(__STDC__)
#pragma warn .nak
#endif

#endif  /* !RC_INVOKED */


#endif  /* __UTIME_H */
