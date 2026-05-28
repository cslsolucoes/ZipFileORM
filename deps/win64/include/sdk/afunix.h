/*++

Copyright (c) Microsoft Corporation

Module Name:

    afunix.h

Abstract:

    This file contains the definitions for the AF_UNIX socket address family
    that can be used by both user-mode and kernel mode modules.

    BETA: The definitions in this header are subject to change.

--*/

#ifndef _AFUNIX_
#pragma option push -b -a8 -pc -A- -w-pun /*P_O_Push*/
#define _AFUNIX_

#pragma once

#define UNIX_PATH_MAX 108

typedef struct sockaddr_un
{
     ADDRESS_FAMILY sun_family;     /* AF_UNIX */
     char sun_path[UNIX_PATH_MAX];  /* pathname */
} SOCKADDR_UN, *PSOCKADDR_UN;


#pragma option pop /*P_O_Pop*/
#endif /* _AFUNIX_ */