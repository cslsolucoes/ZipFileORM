//
//    Copyright (C) Microsoft.  All rights reserved.
//
#ifndef   __USB100_H__
#pragma option push -b -a8 -pc -A- -w-pun /*P_O_Push*/
#define   __USB100_H__
#include <winapifamily.h>

#pragma region Desktop Family or OneCore Family
#if WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_DESKTOP | WINAPI_PARTITION_SYSTEM)


#include "usbspec.h"


#endif /* WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_DESKTOP | WINAPI_PARTITION_SYSTEM) */
#pragma endregion

#pragma option pop /*P_O_Pop*/
#endif   /* __USB100_H__ */
