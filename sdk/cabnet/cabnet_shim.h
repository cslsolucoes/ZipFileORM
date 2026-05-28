/* cabnet_shim.h
 *
 * Wine API shim minimo para Wine cabinet (fci.c + fdi.c) compilar com
 * toolchain Embarcadero (D29 bcc32c + headers Win SDK).
 *
 * Cobertura:
 *  - Macros Wine debug stubs (TRACE/WARN/FIXME/ERR no-ops)
 *  - Wine list.h equivalente (lista circular dupla)
 *
 * NAO redefine tipos Win32 — vem do <windef.h> Embarcadero SDK.
 */

#ifndef CABNET_SHIM_H
#define CABNET_SHIM_H

#include <stddef.h>

/* ===== Wine debug macros — stubs no-op ===== */
#define WINE_DEFAULT_DEBUG_CHANNEL(channel)
#define WINE_DECLARE_DEBUG_CHANNEL(channel)
#define TRACE(...)    ((void)0)
#define TRACE_(ch)    if (0) (void)0; else (void)0
#define WARN(...)     ((void)0)
#define WARN_(ch)     if (0) (void)0; else (void)0
#define FIXME(...)    ((void)0)
#define FIXME_(ch)    if (0) (void)0; else (void)0
#define ERR(...)      ((void)0)
#define ERR_(ch)      if (0) (void)0; else (void)0
#define TRACE_ON(ch)  0
#define WARN_ON(ch)   0
#define FIXME_ON(ch)  0
#define ERR_ON(ch)    0

#define wine_dbgstr_a(s)   ((s) ? (s) : "(null)")
#define wine_dbgstr_w(s)   ((s) ? "(wide)" : "(null)")
#define debugstr_a(s)      ((s) ? (s) : "(null)")
#define debugstr_w(s)      ((s) ? "(wide)" : "(null)")

#ifndef __WINE_ALLOC_SIZE
#define __WINE_ALLOC_SIZE(x)
#endif
#ifndef __WINE_DEALLOC
#define __WINE_DEALLOC(x)
#endif
#ifndef __WINE_MALLOC
#define __WINE_MALLOC
#endif
#ifndef DECLSPEC_HIDDEN
#define DECLSPEC_HIDDEN
#endif

/* Microsoft SAL annotations — gcc/clang nao reconhecem */
#ifndef __callback
#define __callback
#endif
#ifndef __in
#define __in
#endif
#ifndef __out
#define __out
#endif
#ifndef __inout
#define __inout
#endif
#ifndef __in_opt
#define __in_opt
#endif
#ifndef __out_opt
#define __out_opt
#endif
#ifndef __inout_opt
#define __inout_opt
#endif
#ifndef _In_
#define _In_
#endif
#ifndef _Out_
#define _Out_
#endif
#ifndef _Inout_
#define _Inout_
#endif

/* ===== Wine list.h equivalente minimo ===== */
struct list {
    struct list *next;
    struct list *prev;
};
#define LIST_INIT(name) { &(name), &(name) }
static __inline void list_init(struct list *list) {
    list->next = list->prev = list;
}
static __inline void list_add_head(struct list *list, struct list *elem) {
    elem->next = list->next;
    elem->prev = list;
    list->next->prev = elem;
    list->next = elem;
}
static __inline void list_add_tail(struct list *list, struct list *elem) {
    elem->next = list;
    elem->prev = list->prev;
    list->prev->next = elem;
    list->prev = elem;
}
static __inline void list_remove(struct list *elem) {
    elem->next->prev = elem->prev;
    elem->prev->next = elem->next;
}
static __inline struct list *list_head(const struct list *list) {
    return list->next == (struct list *)list ? NULL : list->next;
}
static __inline struct list *list_next(const struct list *list, const struct list *elem) {
    struct list *ret = elem->next;
    return ret == (struct list *)list ? NULL : ret;
}
static __inline int list_empty(const struct list *list) {
    return list->next == (struct list *)list;
}

#define LIST_ENTRY(elem, type, field) \
    ((type *)((char *)(elem) - (size_t)(&((type *)0)->field)))
#define LIST_FOR_EACH(cursor, list) \
    for ((cursor) = (list)->next; (cursor) != (list); (cursor) = (cursor)->next)
#define LIST_FOR_EACH_SAFE(cursor, cursor2, list) \
    for ((cursor) = (list)->next, (cursor2) = (cursor)->next; \
         (cursor) != (list); (cursor) = (cursor2), (cursor2) = (cursor)->next)
#define LIST_FOR_EACH_ENTRY(cursor, list, type, field) \
    for ((cursor) = LIST_ENTRY((list)->next, type, field); \
         &(cursor)->field != (list); \
         (cursor) = LIST_ENTRY((cursor)->field.next, type, field))
#define LIST_FOR_EACH_ENTRY_SAFE(cursor, cursor2, list, type, field) \
    for ((cursor) = LIST_ENTRY((list)->next, type, field), \
         (cursor2) = LIST_ENTRY((cursor)->field.next, type, field); \
         &(cursor)->field != (list); \
         (cursor) = (cursor2), \
         (cursor2) = LIST_ENTRY((cursor)->field.next, type, field))

static __inline void list_add_before(struct list *elem, struct list *to_add) {
    to_add->next = elem;
    to_add->prev = elem->prev;
    elem->prev->next = to_add;
    elem->prev = to_add;
}

#endif /* CABNET_SHIM_H */
