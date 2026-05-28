#!/bin/sh
# Author: Daniel Starke
# Date: 2025-10-25
# Notes:
# Built on Linux. Tested with Debian 12.10.0.
# Installed build dependencies:
# sudo apt install -y p7zip-full build-essential bison flex texinfo texlive texlive-plain-generic cmake licensecheck help2man gengetopt osslsigncode opensc pcscd
# Target distribution has the following directory structure:
# bin                   # user applications (e.g. i686-linux-musl-gcc)
# <arch>-linux-musl-gcc # target directory
#   include             # specific headers
#   lib                 # specific libraries
#   libexec             # target runtime libraries
# share                 # help files
#   license             # copyright and license overview

# directories
ROOT="$(pwd)"         # root directory
PREFIX='/mingw64-64'  # target directory
SRC="${ROOT}/src"     # source directory
BUILD="${ROOT}/build" # temporary build directory
HOST="${ROOT}/host"   # temporary cross-compiler root
LICENSE="${PREFIX}/share/license" # target license directory

# packet versions
ZLIB='zlib-1.3.1'                       # https://zlib.net/
GMP='gmp-6.3.0'                         # https://gmplib.org/
MPFR='mpfr-4.2.2'                       # https://www.mpfr.org/
MPC='mpc-1.2.1'                         # https://www.multiprecision.org/mpc/
ISL='isl-0.27'                          # https://libisl.sourceforge.io/ or https://gcc.gnu.org/pub/gcc/infrastructure/
CLOOG_ISL='cloog-0.21.1'                # https://github.com/periscop/cloog or http://www.bastoul.net/cloog/
BINUTILS='binutils-2.45'                # https://ftp.gnu.org/gnu/binutils/
MINGW='mingw-w64-v13.0.0'               # https://sourceforge.net/projects/mingw-w64/
GCC='gcc-15.2.0'                        # https://gcc.gnu.org/
LINUX='linux-4.19.325'                  # https://cdn.kernel.org/pub/linux/kernel/
MUSL='musl-1.2.5'                       # https://musl.libc.org/
# optional extras (comment out if unneeded)
ZSTD='zstd-1.5.7'                       # https://github.com/facebook/zstd/releases
SEVENZIP='7z2501-src'                   # https://www.7-zip.org/download.html
#SIGN=''                                 # path to script which accepts a single file as argument for code signing

# build configuration
# possible architectures: i686, x86_64, aarch64
: ${GCC_ARCH:=x86_64}
GCC_LANGS='c,c++,lto'
GCC_HOST_CONFIG='--with-arch=core2 --with-tune=generic --enable-threads=posix --disable-nls --disable-libstdcxx-verbose --disable-libstdcxx-pch --enable-clocale=generic --enable-static --disable-shared --enable-libatomic --enable-fully-dynamic-string --enable-lto --enable-plugins --enable-libgomp --with-dwarf2 --disable-win32-registry --enable-version-specific-runtime-libs --disable-multilib --enable-checking=release'
GCC_TARGET_CONFIG='--with-tune=generic --enable-threads=posix --disable-nls --disable-libstdcxx-verbose --disable-libstdcxx-pch --disable-libsanitizer --enable-clocale=generic --enable-static  --enable-shared=libstdc++ --enable-libatomic --enable-fully-dynamic-string --enable-lto --enable-plugins --enable-libgomp --with-dwarf2 --enable-mingw-wildcard=platform --disable-win32-registry --enable-version-specific-runtime-libs --disable-multilib --enable-checking=release'
MCRTDLL='ucrt' # default: msvcrt-os
# adapted from linux/scripts/subarch.include
LINUX_ARCH=$(echo "${GCC_ARCH}" | sed -e 's/i.86/x86/' -e 's/x86_64/x86/' \
                                      -e 's/sun4u/sparc64/' \
                                      -e 's/arm.*/arm/' -e 's/sa110/arm/' \
                                      -e 's/s390x/s390/' -e 's/parisc64/parisc/' \
                                      -e 's/ppc.*/powerpc/' -e 's/mips.*/mips/' \
                                      -e 's/sh[234].*/sh/' -e 's/aarch64.*/arm64/' \
                                      -e 's/riscv.*/riscv/')
THREADS=$(nproc)
LOG="${ROOT}/build-linux-musl.log"

export LANG='C'
export LC_ALL='C'
export CFLAGS='-std=gnu17 -O2 -fPIC -mtune=generic -fno-ident -fomit-frame-pointer -fno-strict-aliasing -Wno-maybe-uninitialized'
export CXXFLAGS='-O2 -fPIC -mtune=generic -fno-ident -fomit-frame-pointer -fno-strict-aliasing -Wno-maybe-uninitialized'
export LDFLAGS='-static-libgcc -s -Wl,-no-undefined' # no debug symbols

case "${LINUX_ARCH}" in
'x86')
	GCC_TARGET_CONFIG="--with-arch=core2 ${GCC_TARGET_CONFIG}"
	TARGET_TRIPLET="${GCC_ARCH}-linux-musl"
	;;
'arm64')
	GCC_TARGET_CONFIG="--with-arch=armv8-a ${GCC_TARGET_CONFIG}"
	TARGET_TRIPLET="${GCC_ARCH}-linux-musl"
	;;
esac

SO_ARCH="$(echo "${GCC_ARCH}" | sed 's/^x86_64$/x64/g')"

# commands
alias rcp='cp'
cp --help | grep -q reflink && alias rcp='cp --reflink=auto'

STEP_START=${START:-1} # set START to skip until given step number
STEP_I=1
STEP_N="$(grep -h "^\\(if \\)\\?step ['\"]" "${0}" | wc -l)"
step() {
	echo "\e[1mStep ${STEP_I}/${STEP_N}: ${*}\e[0m"
	STEP_I=$((STEP_I + 1))
	if [ "$STEP_I" -le "$STEP_START" ]; then
		echo 'Skipped.'
		return 1
	fi
	return 0
}

error() {
	echo "\e[1;31mError: ${*}\e[0m" >&2
	exit 1
}

download() {
	FILE="$1"
	URL="$(echo "$2" | sed "s/@FILE@/$1/g")"
	test -f "${SRC}/${FILE}" || wget --progress=bar:force:noscroll -O "${SRC}/${FILE}" "${URL}" >>"${LOG}" 2>&1 || error "Failed to download ${FILE} from ${URL}."
}

verify() {
	INPUT="$(basename "$1")"
	cd "${SRC}" || error "Unknown directory ${SRC}."
	echo "Verifying SHA256 of ${SRC}/${INPUT}." >>"${LOG}" 2>&1
	cat <<"_EOF" | grep -e "^[0-9a-f]\{64\}  ${INPUT}\$" | sha256sum --check --status >>"${LOG}" 2>&1 || error "Failed to verify ${INPUT}."
ed087f83ee789c1ea5f39c464c55a5c9d4008deb0efe900814f2df262b82c36e  7z2501-src.tar.xz
c50c0e7f9cb188980e2cc97e4537626b1672441815587f1eab69d2a1bfbef5d2  binutils-2.45.tar.xz
d370cf9990d2be24bfb24750e355bac26110051248cabf2add61f9b3867fb1d7  cloog-0.21.1.tar.gz
a6e21868ead545cf87f0c01f84276e4b5281d672098591c1c896241f09363478  gcc-11.5.0.tar.xz
71cd373d0f04615e66c5b5b14d49c1a4c1a08efa7b30625cd240b11bab4062b3  gcc-12.5.0.tar.xz
9c4ce6dbb040568fdc545588ac03c5cbc95a8dbf0c7aa490170843afb59ca8f5  gcc-13.4.0.tar.xz
e0dc77297625631ac8e50fa92fffefe899a4eb702592da5c32ef04e2293aca3a  gcc-14.3.0.tar.xz
e2b09ec21660f01fecffb715e0120265216943f038d0e48a9868713e54f06cea  gcc-15.1.0.tar.xz
438fd996826b0c82485a29da03a72d71d6e3541a83ec702df4271f6fe025d24e  gcc-15.2.0.tar.xz
a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898  gmp-6.3.0.tar.xz
6d8babb59e7b672e8cb7870e874f3f7b813b6e00e6af3f8b04f7579965643d5c  isl-0.27.tar.xz
607bed7de5cda31a443df4c8a78dbe5e8a9ad31afde2a4d28fe99ab4730e8de1  linux-4.19.325.tar.xz
ba8876404cbf250d4b40c80b4be335b1fbf92e69a161ce4af8a5c628903d31cc  mingw-w64-v13.0.0.zip
17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459  mpc-1.2.1.tar.gz
b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01  mpfr-4.2.2.tar.xz
a9a118bbe84d8764da0ea0d28b3ab3fae8477fc7e4085d90102b8596fc7c75e4  musl-1.2.5.tar.gz
9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23  zlib-1.3.1.tar.gz
eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3  zstd-1.5.7.tar.gz
_EOF
}

extract() {
	INPUT="$1"
	cd "${SRC}" || error "Unknown directory ${SRC}."
	if [ "x${INPUT}" != "x${INPUT%.tar.gz}" ]; then
		test ! -d "${INPUT%.tar.gz}" && (tar xzf "${INPUT}" || error "Failed to extract ${INPUT}.")
	elif [ "x${INPUT}" != "x${INPUT%.tar.bz2}" ]; then
		test ! -d "${INPUT%.tar.bz2}" && (tar xjf "${INPUT}" || error "Failed to extract ${INPUT}.")
	elif [ "x${INPUT}" != "x${INPUT%.tar.xz}" ]; then
		test ! -d "${INPUT%.tar.xz}" && (tar xJf "${INPUT}" || error "Failed to extract ${INPUT}.")
	elif [ "x${INPUT}" != "x${INPUT%.zip}" ]; then
		test ! -d "${INPUT%.zip}" && (unzip "${INPUT}" >/dev/null || error "Failed to extract ${INPUT}.")
	else
		error "Unknown file extension in ${INPUT}. Extraction failed."
	fi
}

# check MCRTDLL value
case "${MCRTDLL}" in
	crtdll*|msvcrt10*|msvcrt20*|msvcrt40*|msvcr40*|msvcr70*|msvcr71*|msvcr80*|msvcr90*|msvcr100*|msvcr110*|msvcr120*|msvcrt-os*|msvcrtd*|ucrt*)
		;;
	*)
		error "Invalid value for MCRTDLL: ${MCRTDLL}."
		;;
esac

# create source directory
mkdir -p "${SRC}" || error "Failed to create ${SRC}."

# create log file
if [ "${STEP_START}" -eq 1 ]; then
	: >"${LOG}"
else
	: >>"${LOG}"
fi

if step 'download sources'; then
	LINUX_RELEASE_TAG=$(echo "${LINUX}" | awk 'BEGIN { FS="[-.]" } { print "v" $2 ".x" }')
	download "${ZLIB}.tar.gz" "https://zlib.net/@FILE@"
	download "${GMP}.tar.xz" "https://gmplib.org/download/gmp/@FILE@"
	download "${MPFR}.tar.xz" "https://www.mpfr.org/${MPFR}/@FILE@"
	download "${MPC}.tar.gz" "https://www.multiprecision.org/downloads/@FILE@"
	download "${ISL}.tar.xz" "https://libisl.sourceforge.io/@FILE@"
	download "${CLOOG_ISL}.tar.gz" "https://github.com/periscop/cloog/releases/download/${CLOOG_ISL}/@FILE@"
	download "${BINUTILS}.tar.xz" "https://ftp.gnu.org/gnu/binutils/@FILE@"
	download "${MINGW}.zip" "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/@FILE@/download"
	download "${GCC}.tar.xz" "https://ftp.fu-berlin.de/unix/languages/gcc/releases/${GCC}/@FILE@"
	download "${MUSL}.tar.gz" "https://musl.libc.org/releases/@FILE@"
	download "${LINUX}.tar.xz" "https://cdn.kernel.org/pub/linux/kernel/${LINUX_RELEASE_TAG}/@FILE@"
	[ "x${ZSTD}" != 'x' ] && download "${ZSTD}.tar.gz" "https://github.com/facebook/zstd/releases/download/v${ZSTD#zstd-}/@FILE@"
	[ "x${SEVENZIP}" != 'x' ] && download "${SEVENZIP}.tar.xz" "https://www.7-zip.org/a/@FILE@"
fi

if step 'verify sources'; then
	verify "${SRC}/${ZLIB}".*
	verify "${SRC}/${GMP}".*
	verify "${SRC}/${MPFR}".*
	verify "${SRC}/${MPC}".*
	verify "${SRC}/${ISL}".*
	verify "${SRC}/${CLOOG_ISL}".*
	verify "${SRC}/${BINUTILS}".*
	verify "${SRC}/${MINGW}".*
	verify "${SRC}/${GCC}".*
	verify "${SRC}/${MUSL}".*
	verify "${SRC}/${LINUX}".*
	[ "x${ZSTD}" != 'x' ] && verify "${SRC}/${ZSTD}".*
	[ "x${SEVENZIP}" != 'x' ] && verify "${SRC}/${SEVENZIP}".*
fi

if step 'prepare sources'; then
	extract "${SRC}/${ZLIB}".*
	extract "${SRC}/${GMP}".*
	extract "${SRC}/${MPFR}".*
	extract "${SRC}/${MPC}".*
	extract "${SRC}/${ISL}".*
	extract "${SRC}/${CLOOG_ISL}".*
	extract "${SRC}/${BINUTILS}".*
	extract "${SRC}/${MINGW}".*
	extract "${SRC}/${GCC}".*
	extract "${SRC}/${MUSL}".*
	extract "${SRC}/${LINUX}".*
	[ "x${ZSTD}" != 'x' ] && extract "${SRC}/${ZSTD}".*
	[ "x${SEVENZIP}" != 'x' ] && test ! -d "${SRC}/${SEVENZIP}.tar.xz" && (mkdir -p "${SRC}/${SEVENZIP}" && tar -xJf "${SRC}/${SEVENZIP}.tar.xz" -C ${SRC}/${SEVENZIP} || error "Failed to extract ${SRC}/${SEVENZIP}.tar.xz.")
fi

if step 'remove previous build'; then
	test ! -d "${PREFIX}" || rm -rf "${PREFIX}/"* || error "Failed to delete ${PREFIX}."
	test ! -d "${BUILD}" || rm -rf "${BUILD}" || error "Failed to delete ${BUILD}."
	test ! -d "${HOST}" || rm -rf "${HOST}" || error "Failed to delete ${HOST}."
fi

if step 'prepare output directories'; then
	mkdir -p "${PREFIX}" || error "Failed to create ${PREFIX}."
	mkdir -p "${BUILD}" || error "Failed to create ${BUILD}."
	for t in x86_64-w64-mingw32 "${TARGET_TRIPLET}"; do
		for d in 'include' 'lib/bfd-plugins'; do
			mkdir -p "${HOST}/${t}/${d}" || error "Failed to create ${HOST}/${t}/${d}."
		done
	done
	for d in 'include' 'lib/bfd-plugins' 'libexec'; do
		mkdir -p "${PREFIX}/${TARGET_TRIPLET}/${d}" || error "Failed to create ${PREFIX}/${TARGET_TRIPLET}/${d}."
	done
fi

if step "patch ${MUSL} source"; then
	rm -rf "${BUILD}/musl-src"
	rcp -r "${SRC}/${MUSL}" "${BUILD}/musl-src" || error "Failed to copy musl source to ${BUILD}/musl-src."
	cd "${BUILD}/musl-src"
	# apply CVE-2025-26519 patches
	patch -p1 <<'_PATCH' >>"${LOG}" 2>&1 || error "Failed to patch ${BUILD}/musl-src."
diff -uar musl-1.2.5-org/src/locale/iconv.c musl-1.2.5/src/locale/iconv.c
--- musl-1.2.5-org/src/locale/iconv.c	2024-03-01 03:07:33.000000000 +0100
+++ musl-1.2.5/src/locale/iconv.c	2025-09-29 21:44:45.905956041 +0200
@@ -495,7 +495,7 @@
 			if (c >= 93 || d >= 94) {
 				c += (0xa1-0x81);
 				d += 0xa1;
-				if (c >= 93 || c>=0xc6-0x81 && d>0x52)
+				if (c > 0xc6-0x81 || c==0xc6-0x81 && d>0x52)
 					goto ilseq;
 				if (d-'A'<26) d = d-'A';
 				else if (d-'a'<26) d = d-'a'+26;
@@ -538,6 +538,10 @@
 				if (*outb < k) goto toobig;
 				memcpy(*out, tmp, k);
 			} else k = wctomb_utf8(*out, c);
+			/* This failure condition should be unreachable, but
+			 * is included to prevent decoder bugs from translating
+			 * into advancement outside the output buffer range. */
+			if (k>4) goto ilseq;
 			*out += k;
 			*outb -= k;
 			break;
_PATCH
	# ported https://github.com/rcombs/musl/commit/740155e21f7057a33e75a9ed4cb6fbf07f75d2a7.patch
	sed "/#define LDSO_FILENAME/c \\+#define LDSO_FILENAME \"libc-${SO_ARCH}.so\"" <<'_PATCH' | patch -p1 >>"${LOG}" 2>&1 || error "Failed to patch ${BUILD}/musl-src."
diff -uarN musl-1.2.5-org/crt/dcrt1.c musl-1.2.5/crt/dcrt1.c
--- musl-1.2.5-org/crt/dcrt1.c	1970-01-01 01:00:00.000000000 +0100
+++ musl-1.2.5/crt/dcrt1.c	2025-10-24 19:08:46.196453712 +0200
@@ -0,0 +1,402 @@
+#define SYSCALL_NO_TLS 1
+
+#include <elf.h>
+#include <errno.h>
+#include <fcntl.h>
+#include <features.h>
+#include <libgen.h>
+#include <sys/mman.h>
+#include <string.h>
+#include <unistd.h>
+#include "atomic.h"
+#include "dynlink.h"
+#include "syscall.h"
+
+extern weak hidden const size_t _DYNAMIC[];
+
+int main();
+weak void _init();
+weak void _fini();
+weak _Noreturn int __libc_start_main(int (*)(), int, char **,
+	void (*)(), void(*)(), void(*)());
+
+#define START "_start"
+#define _dlstart_c _start_c
+#define DL_DNI
+#include "../ldso/dlstart.c"
+
+#ifndef PAGESIZE
+#ifdef PAGE_SIZE
+#undef PAGE_SIZE // We don't want to use libc.page_size here
+#endif
+static size_t page_size;
+#define PAGE_SIZE page_size
+#endif
+
+#ifdef SYS_mmap2
+#define crt_mmap(start, len, prot, flags, fd, off) (void*)__syscall(SYS_mmap2, start, len, prot, flags, fd, off/SYSCALL_MMAP2_UNIT)
+#else
+#define crt_mmap(start, len, prot, flags, fd, off) (void*)__syscall(SYS_mmap, start, len, prot, flags, fd, off)
+#endif
+
+#define crt_munmap(ptr, len) __syscall(SYS_munmap, ptr, len)
+
+static inline int crt_mprotect(void *addr, size_t len, int prot)
+{
+	size_t start, end;
+	start = (size_t)addr & -PAGE_SIZE;
+	end = (size_t)((char *)addr + len + PAGE_SIZE-1) & -PAGE_SIZE;
+	return __syscall(SYS_mprotect, start, end-start, prot);
+}
+
+#define crt_read(fd, buf, size) __syscall(SYS_read, fd, buf, size)
+#define crt_pread(fd, buf, size, ofs) __syscall(SYS_pread, fd, buf, size, __SYSCALL_LL_PRW(ofs))
+
+#define map_failed(val) ((unsigned long)val > -4096UL)
+
+#ifdef SYS_readlink
+#define crt_readlink(path, buf, bufsize) __syscall(SYS_readlink, path, buf, bufsize)
+#else
+#define crt_readlink(path, buf, bufsize) __syscall(SYS_readlinkat, AT_FDCWD, path, buf, bufsize)
+#endif
+
+#ifdef SYS_access
+#define crt_access(filename, amode) __syscall(SYS_access, filename, amode)
+#else
+#define crt_access(filename, amode) __syscall(SYS_faccessat, AT_FDCWD, filename, amode, 0)
+#endif
+
+static void *crt_memcpy(void *restrict dest, const void *restrict src, size_t n)
+{
+	unsigned char *d = dest;
+	const unsigned char *s = src;
+	for (; n; n--) *d++ = *s++;
+	return dest;
+}
+
+static void *crt_memset(void *dest, int c, size_t n)
+{
+	unsigned char *s = dest;
+	for (; n; n--, s++) *s = c;
+	return dest;
+}
+
+static size_t crt_strlen(const char *s)
+{
+	const char *a = s;
+	for (; *s; s++);
+	return s-a;
+}
+
+static char *crt_strchrnul(const char *s, int c)
+{
+	c = (unsigned char)c;
+	if (!c) return (char *)s + crt_strlen(s);
+	for (; *s && *(unsigned char *)s != c; s++);
+	return (char *)s;
+}
+
+static int crt_strncmp(const char *_l, const char *_r, size_t n)
+{
+	const unsigned char *l=(void *)_l, *r=(void *)_r;
+	if (!n--) return 0;
+	for (; *l && *r && n && *l == *r ; l++, r++, n--);
+	return *l - *r;
+}
+
+static char *crt_getenv(const char *name, char **environ)
+{
+	size_t l = crt_strchrnul(name, '=') - name;
+	if (l && !name[l] && environ)
+		for (char **e = environ; *e; e++)
+			if (!crt_strncmp(name, *e, l) && l[*e] == '=')
+				return *e + l+1;
+	return 0;
+}
+
+static inline void *map_library(int fd)
+{
+	size_t addr_min=SIZE_MAX, addr_max=0;
+	size_t this_min, this_max;
+	off_t off_start = 0;
+	Ehdr eh;
+	Phdr *ph, *ph0;
+	unsigned prot = 0;
+	unsigned char *map=MAP_FAILED;
+	size_t i;
+
+	ssize_t l = crt_read(fd, &eh, sizeof eh);
+	if (l<0) goto error;
+	if (l<sizeof eh || (eh.e_type != ET_DYN && eh.e_type != ET_EXEC))
+		goto error;
+	for (i = 0; i < eh.e_phnum; i++, ph=(void *)((char *)ph+eh.e_phentsize)) {
+		Phdr phbuf;
+		ph = &phbuf;
+		l = crt_pread(fd, ph, sizeof *ph, eh.e_phoff + eh.e_phentsize * i);
+		if (l < sizeof *ph) goto error;
+		if (ph->p_type != PT_LOAD) continue;
+		if (ph->p_vaddr < addr_min) {
+			addr_min = ph->p_vaddr;
+			off_start = ph->p_offset;
+			prot = (((ph->p_flags&PF_R) ? PROT_READ : 0) |
+				((ph->p_flags&PF_W) ? PROT_WRITE: 0) |
+				((ph->p_flags&PF_X) ? PROT_EXEC : 0));
+		}
+		if (ph->p_vaddr + ph->p_memsz > addr_max) {
+			addr_max = ph->p_vaddr + ph->p_memsz;
+		}
+	}
+
+	/* We rely on the header being mapped as readable later */
+	if (addr_min != 0 || off_start != 0 || addr_max == 0 || !(prot & PROT_READ))
+		goto error;
+
+	addr_max += PAGE_SIZE-1;
+	addr_max &= -PAGE_SIZE;
+
+	/* The first time, we map too much, possibly even more than
+	 * the length of the file. This is okay because we will not
+	 * use the invalid part; we just need to reserve the right
+	 * amount of virtual address space to map over later. */
+	map = crt_mmap(0, addr_max, prot, MAP_PRIVATE, fd, off_start);
+	if (map_failed(map)) goto error;
+
+	ph0 = (void*)(map + eh.e_phoff);
+
+	for (ph=ph0, i=eh.e_phnum; i; i--, ph=(void *)((char *)ph+eh.e_phentsize)) {
+		if (ph->p_type != PT_LOAD) continue;
+		this_min = ph->p_vaddr & -PAGE_SIZE;
+		this_max = ph->p_vaddr+ph->p_memsz+PAGE_SIZE-1 & -PAGE_SIZE;
+		off_start = ph->p_offset & -PAGE_SIZE;
+		prot = (((ph->p_flags&PF_R) ? PROT_READ : 0) |
+			((ph->p_flags&PF_W) ? PROT_WRITE: 0) |
+			((ph->p_flags&PF_X) ? PROT_EXEC : 0));
+		/* Reuse the existing mapping for the lowest-address LOAD */
+		if ((ph->p_vaddr & -PAGE_SIZE) != addr_min)
+			if (map_failed(crt_mmap(map+this_min, this_max-this_min, prot, MAP_PRIVATE|MAP_FIXED, fd, off_start)))
+				goto error;
+		if (ph->p_memsz > ph->p_filesz && (ph->p_flags&PF_W)) {
+			size_t brk = (size_t)map+ph->p_vaddr+ph->p_filesz;
+			size_t pgbrk = brk+PAGE_SIZE-1 & -PAGE_SIZE;
+			crt_memset((void *)brk, 0, pgbrk-brk & PAGE_SIZE-1);
+			if (pgbrk-(size_t)map < this_max && map_failed(crt_mmap((void *)pgbrk, (size_t)map+this_max-pgbrk, prot, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0)))
+				goto error;
+		}
+	}
+	return map;
+error:
+	for(;;) a_crash();
+	return 0;
+}
+
+static void decode_vec(const size_t *v, size_t *a, size_t cnt)
+{
+	size_t i;
+	for (i=0; i<cnt; i++) a[i] = 0;
+	for (; v[0]; v+=2) if (v[0]-1<cnt-1) {
+		a[0] |= 1UL<<v[0];
+		a[v[0]] = v[1];
+	}
+}
+
+static void get_rpath(const char **runpath, const size_t *dyn, unsigned char *base)
+{
+	/* DT_STRTAB is pre-relocated for us by dlstart */
+	const char *strings = (char*)base + dyn[DT_STRTAB];
+
+	*runpath = NULL;
+
+	if (dyn[0] & (1 << DT_RPATH))
+		*runpath = strings + dyn[DT_RPATH];
+	if (dyn[0] & (1 << DT_RUNPATH))
+		*runpath = strings + dyn[DT_RUNPATH];
+}
+
+static size_t find_linker(char *outbuf, size_t bufsize, const char *this_path, size_t thisl, const size_t *dyn, unsigned char *base, char **environ, int secure)
+{
+	const char *paths[2]; // envpath, rpath/runpath
+	size_t i;
+
+	// In the suid/secure case, skip everything and use the fixed path
+	if (secure)
+		goto default_path;
+
+	// Strip filename
+	if (thisl)
+		thisl--;
+	while (thisl > 1 && this_path[thisl] == '/')
+		thisl--;
+	while (thisl > 0 && this_path[thisl] != '/')
+		thisl--;
+
+	const char *envpath = crt_getenv("LD_LOADER_PATH", environ);
+	if (envpath) {
+		size_t envlen = crt_strlen(envpath);
+		if (envlen < bufsize) {
+			crt_memcpy(outbuf, envpath, envlen + 1);
+			return envlen + 1;
+		}
+	}
+
+	get_rpath(&paths[1], dyn, base);
+
+	paths[0] = crt_getenv("LD_LIBRARY_PATH", environ);
+
+	for (i = 0; i < 2; i++) {
+		const char *p = paths[i];
+		char *o = outbuf;
+		if (!p)
+			continue;
+		for (;;) {
+			if (!crt_strncmp(p, "$ORIGIN", 7) ||
+					!crt_strncmp(p, "${ORIGIN}", 9)) {
+				if (o + thisl + 1 < outbuf + bufsize) {
+					crt_memcpy(o, this_path, thisl);
+					o += thisl;
+				} else {
+					o = outbuf + bufsize - 1;
+				}
+				p += (p[1] == '{' ? 9 : 7);
+			} else if (*p == ':' || !*p) {
+#define LDSO_FILENAME "ld-musl-" LDSO_ARCH ".so.1"
+				if (o + sizeof(LDSO_FILENAME) + 1 < outbuf + bufsize) {
+					*o++ = '/';
+					crt_memcpy(o, LDSO_FILENAME, sizeof(LDSO_FILENAME));
+					if (!crt_access(outbuf, R_OK | X_OK))
+						return (o + sizeof(LDSO_FILENAME)) - outbuf;
+				}
+				if (!*p)
+					break;
+				o = outbuf;
+				p++;
+			} else {
+				if (o < outbuf + bufsize)
+					*o++ = *p;
+				p++;
+			}
+		}
+	}
+
+	default_path:
+	// Didn't find a usable loader anywhere (or in secure mode), so try the default
+	crt_memcpy(outbuf, LDSO_PATHNAME, sizeof(LDSO_PATHNAME));
+	return sizeof(LDSO_PATHNAME);
+}
+
+hidden _Noreturn void __dls2(unsigned char *base, size_t *p)
+{
+	int argc = p[0];
+	char **argv = (void *)(p+1);
+	int fd;
+	int secure;
+	Ehdr *loader_hdr;
+	Phdr *new_hdr;
+	void *entry;
+	char this_path[PATH_MAX];
+	size_t thisl;
+	char linker_path[PATH_MAX];
+	size_t linker_len;
+	size_t i;
+	size_t aux[AUX_CNT];
+	size_t *auxv;
+	size_t dyn[DYN_CNT];
+	char **environ = argv + argc + 1;
+
+	// We're already finished here; just run main.
+	if (__libc_start_main)
+		__libc_start_main(main, argc, argv, _init, _fini, 0);
+
+	/* Find aux vector just past environ[] and use it to initialize
+	* global data that may be needed before we can make syscalls. */
+	for (i = argc + 1; argv[i]; i++);
+	auxv = (void *)(argv + i + 1);
+	decode_vec(auxv, aux, AUX_CNT);
+	secure = ((aux[0] & 0x7800) != 0x7800 || aux[AT_UID] != aux[AT_EUID]
+		|| aux[AT_GID] != aux[AT_EGID] || aux[AT_SECURE]);
+
+#ifndef PAGESIZE
+	page_size = aux[AT_PAGESZ];
+#endif
+
+	decode_vec(_DYNAMIC, dyn, DYN_CNT);
+
+	thisl = crt_readlink("/proc/self/exe", this_path, sizeof this_path);
+	linker_len = find_linker(linker_path, sizeof linker_path, this_path, thisl, dyn, base, environ, secure);
+
+	fd = __sys_open2(, linker_path, O_RDONLY);
+	if (fd < 0) {
+		crt_put("Error: Failed to load dynamic linker: ");
+		crt_put(linker_path ? linker_path : "<unknown>");
+		crt_put("\n");
+		goto error;
+	}
+
+	loader_hdr = map_library(fd);
+	if (!loader_hdr)
+		goto error;
+
+	__syscall(SYS_close, fd);
+
+	// Copy the program headers into an anonymous mapping
+	new_hdr = crt_mmap(0, (aux[AT_PHENT] * (aux[AT_PHNUM] + 2) + linker_len + PAGE_SIZE - 1) & -PAGE_SIZE, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
+	if (map_failed(new_hdr))
+		goto error;
+
+	// Point it back at the original kernel-provided base
+	new_hdr->p_type = PT_PHDR;
+	new_hdr->p_vaddr = (size_t)new_hdr - (size_t)base;
+
+	((Phdr*)((char*)new_hdr + aux[AT_PHENT]))->p_type = PT_INTERP;
+	((Phdr*)((char*)new_hdr + aux[AT_PHENT]))->p_vaddr = new_hdr->p_vaddr + aux[AT_PHENT] * (aux[AT_PHNUM] + 2);
+
+	crt_memcpy((char*)new_hdr + aux[AT_PHENT] * (aux[AT_PHNUM] + 2), linker_path, linker_len);
+
+	for (i = 0; i < aux[AT_PHNUM]; i++) {
+		Phdr *hdr = (void*)((char*)aux[AT_PHDR] + aux[AT_PHENT] * i);
+		Phdr *dst = (void*)((char*)new_hdr + aux[AT_PHENT] * (i + 2));
+		if (hdr->p_type == PT_PHDR || hdr->p_type == PT_INTERP) {
+			// Can't have a duplicate
+			dst->p_type = PT_NULL;
+		} else {
+			crt_memcpy(dst, hdr, aux[AT_PHENT]);
+		}
+	}
+
+	if (crt_mprotect(new_hdr, aux[AT_PHENT] * (aux[AT_PHNUM] + 2) + linker_len, PROT_READ))
+		goto error;
+
+	for (i=0; auxv[i]; i+=2) {
+		if (auxv[i] == AT_BASE)
+			auxv[i + 1] = (size_t)loader_hdr;
+		if (auxv[i] == AT_PHDR)
+			auxv[i + 1] = (size_t)new_hdr;
+		if (auxv[i] == AT_PHNUM)
+			auxv[i + 1] += 2;
+	}
+
+	entry = (char*)loader_hdr + loader_hdr->e_entry;
+
+	/* Undo the relocations performed by dlstart */
+
+	if (NEED_MIPS_GOT_RELOCS) {
+		const size_t *dynv = _DYNAMIC;
+		size_t local_cnt = 0;
+		size_t *got = (void *)(base + dyn[DT_PLTGOT]);
+		for (i=0; dynv[i]; i+=2) if (dynv[i]==DT_MIPS_LOCAL_GOTNO)
+			local_cnt = dynv[i+1];
+		for (i=0; i<local_cnt; i++) got[i] -= (size_t)base;
+	}
+
+	size_t *rel = (void *)((size_t)base+dyn[DT_REL]);
+	size_t rel_size = dyn[DT_RELSZ];
+	for (; rel_size; rel+=2, rel_size-=2*sizeof(size_t)) {
+		if (!IS_RELATIVE(rel[1], 0)) continue;
+		size_t *rel_addr = (void *)((size_t)base + rel[0]);
+		*rel_addr -= (size_t)base;
+	}
+
+	CRTJMP(entry, argv - 1);
+
+error:
+	for(;;) a_crash();
+}
diff -uarN musl-1.2.5-org/ldso/dlstart.c musl-1.2.5/ldso/dlstart.c
--- musl-1.2.5-org/ldso/dlstart.c	2024-03-01 03:07:33.000000000 +0100
+++ musl-1.2.5/ldso/dlstart.c	2025-10-24 19:08:01.570281842 +0200
@@ -1,6 +1,10 @@
 #include <stddef.h>
 #include "dynlink.h"
 #include "libc.h"
+#ifdef DL_DNI
+static size_t crt_strlen(const char *s);
+#define crt_put(str) __syscall(SYS_write, 1, str, crt_strlen(str))
+#endif
 
 #ifndef START
 #define START "_dlstart"
@@ -21,7 +25,7 @@
 hidden void _dlstart_c(size_t *sp, size_t *dynv)
 {
 	size_t i, aux[AUX_CNT], dyn[DYN_CNT];
-	size_t *rel, rel_size, base;
+	size_t *rel, rel_size, base, loader_phdr;
 
 	int argc = *sp;
 	char **argv = (void *)(sp+1);
@@ -41,6 +45,13 @@
 		 * space and moving the extra fdpic arguments to the stack
 		 * vector where they are easily accessible from C. */
 		segs = ((struct fdpic_loadmap *)(sp[-1] ? sp[-1] : sp[-2]))->segs;
+		if (aux[AT_BASE]) {
+			Ehdr *eh = (void*)aux[AT_BASE];
+			for (i = 0; eh->e_phoff - segs[i].p_vaddr >= segs[i].p_memsz; i++);
+			loader_phdr = (eh->e_phoff - segs[i].p_vaddr + segs[i].addr);
+		} else {
+			loader_phdr = aux[AT_PHDR];
+		}
 	} else {
 		/* If dynv is null, the entry point was started from loader
 		 * that is not fdpic-aware. We can assume normal fixed-
@@ -55,6 +66,7 @@
 		segs[0].p_memsz = -1;
 		Ehdr *eh = (void *)base;
 		Phdr *ph = (void *)(base + eh->e_phoff);
+		loader_phdr = (size_t)ph;
 		size_t phnum = eh->e_phnum;
 		size_t phent = eh->e_phentsize;
 		while (phnum-- && ph->p_type != PT_DYNAMIC)
@@ -69,13 +81,48 @@
 
 #if DL_FDPIC
 	for (i=0; i<DYN_CNT; i++) {
-		if (i==DT_RELASZ || i==DT_RELSZ) continue;
+		if (i==DT_RELASZ || i==DT_RELSZ || i==DT_RPATH || i==DT_RUNPATH) continue;
 		if (!dyn[i]) continue;
 		for (j=0; dyn[i]-segs[j].p_vaddr >= segs[j].p_memsz; j++);
 		dyn[i] += segs[j].addr - segs[j].p_vaddr;
 	}
 	base = 0;
+#else
+	/* If the dynamic linker is invoked as a command, its load
+	 * address is not available in the aux vector. Instead, compute
+	 * the load address as the difference between &_DYNAMIC and the
+	 * virtual address in the PT_DYNAMIC program header. */
+	base = aux[AT_BASE];
+	if (!base) {
+		size_t phnum = aux[AT_PHNUM];
+		size_t phentsize = aux[AT_PHENT];
+		Phdr *ph = (void *)aux[AT_PHDR];
+		for (i=phnum; i--; ph = (void *)((char *)ph + phentsize)) {
+			if (ph->p_type == PT_DYNAMIC) {
+				base = (size_t)dynv - ph->p_vaddr;
+				break;
+			}
+		}
+	}
+#ifdef DL_DNI
+	if (!base) {
+		crt_put("Error: Executable is not position independent. Recompile with -fPIC -pie.\n");
+		for(;;) a_crash();
+	}
+#endif
+	loader_phdr = base + ((Ehdr*)base)->e_phoff;
+#endif
+
+#ifdef DL_DNI
+	/* If AT_PHDR doesn't match the PHDR in AT_BASE, then we've been loaded as a
+	 * dynamic executable and ld.so has already been run, either by the kernel,
+	 * or by dcrt. This means relocs are already finished (and doing them again
+	 * would break DT_RELs), so we can just skip to the stage-2 jump. */
+	if (aux[AT_PHDR] != loader_phdr)
+		goto skip_relocs;
+#endif
 
+#if DL_FDPIC
 	const Sym *syms = (void *)dyn[DT_SYMTAB];
 
 	rel = (void *)dyn[DT_RELA];
@@ -97,23 +144,6 @@
 		}
 	}
 #else
-	/* If the dynamic linker is invoked as a command, its load
-	 * address is not available in the aux vector. Instead, compute
-	 * the load address as the difference between &_DYNAMIC and the
-	 * virtual address in the PT_DYNAMIC program header. */
-	base = aux[AT_BASE];
-	if (!base) {
-		size_t phnum = aux[AT_PHNUM];
-		size_t phentsize = aux[AT_PHENT];
-		Phdr *ph = (void *)aux[AT_PHDR];
-		for (i=phnum; i--; ph = (void *)((char *)ph + phentsize)) {
-			if (ph->p_type == PT_DYNAMIC) {
-				base = (size_t)dynv - ph->p_vaddr;
-				break;
-			}
-		}
-	}
-
 	/* MIPS uses an ugly packed form for GOT relocations. Since we
 	 * can't make function calls yet and the code is tiny anyway,
 	 * it's simply inlined here. */
@@ -157,6 +187,9 @@
 	}
 #endif
 
+#ifdef DL_DNI
+skip_relocs:
+#endif
 	stage2_func dls2;
 	GETFUNCSYM(&dls2, __dls2, base+dyn[DT_PLTGOT]);
 	dls2((void *)base, sp);
diff -uarN musl-1.2.5-org/Makefile musl-1.2.5/Makefile
--- musl-1.2.5-org/Makefile	2024-03-01 03:07:33.000000000 +0100
+++ musl-1.2.5/Makefile	2025-10-24 19:00:02.491038267 +0200
@@ -107,13 +107,15 @@
 
 obj/src/internal/version.o obj/src/internal/version.lo: obj/src/internal/version.h
 
-obj/crt/rcrt1.o obj/ldso/dlstart.lo obj/ldso/dynlink.lo: $(srcdir)/src/internal/dynlink.h $(srcdir)/arch/$(ARCH)/reloc.h
+obj/crt/rcrt1.o obj/crt/dcrt1.o obj/ldso/dlstart.lo obj/ldso/dynlink.lo: $(srcdir)/src/internal/dynlink.h $(srcdir)/arch/$(ARCH)/reloc.h
 
-obj/crt/crt1.o obj/crt/scrt1.o obj/crt/rcrt1.o obj/ldso/dlstart.lo: $(srcdir)/arch/$(ARCH)/crt_arch.h
+obj/crt/crt1.o obj/crt/scrt1.o obj/crt/rcrt1.o obj/crt/dcrt1.o obj/ldso/dlstart.lo: $(srcdir)/arch/$(ARCH)/crt_arch.h
 
-obj/crt/rcrt1.o: $(srcdir)/ldso/dlstart.c
+obj/crt/rcrt1.o obj/crt/dcrt1.o: $(srcdir)/ldso/dlstart.c
 
-obj/crt/Scrt1.o obj/crt/rcrt1.o: CFLAGS_ALL += -fPIC
+obj/crt/Scrt1.o obj/crt/rcrt1.o obj/crt/dcrt1.o: CFLAGS_ALL += -fPIC
+
+obj/crt/dcrt1.o: CFLAGS_ALL += -DLDSO_PATHNAME=\"$(LDSO_PATHNAME)\"
 
 OPTIMIZE_SRCS = $(wildcard $(OPTIMIZE_GLOBS:%=$(srcdir)/src/%))
 $(OPTIMIZE_SRCS:$(srcdir)/%.c=obj/%.o) $(OPTIMIZE_SRCS:$(srcdir)/%.c=obj/%.lo): CFLAGS += -O3
diff -uarN musl-1.2.5-org/tools/ld.musl-clang.in musl-1.2.5/tools/ld.musl-clang.in
--- musl-1.2.5-org/tools/ld.musl-clang.in	2024-03-01 03:07:33.000000000 +0100
+++ musl-1.2.5/tools/ld.musl-clang.in	2025-10-24 19:00:02.491038267 +0200
@@ -7,6 +7,18 @@
 userlinkdir=
 userlink=
 
+Scrt="$libc_lib/Scrt1.o"
+dynamic_linker_args="-dynamic-linker \"$ldso\""
+
+for x ; do
+    case "$x" in
+        -l-dni)
+            dynamic_linker_args="-no-dynamic-linker"
+            Scrt="$libc_lib/dcrt1.o"
+            ;;
+    esac
+done
+
 for x ; do
     test "$cleared" || set -- ; cleared=1
 
@@ -42,10 +54,13 @@
             ;;
         -sysroot=*|--sysroot=*)
             ;;
+        $libc_lib/Scrt1.o)
+            set -- "$@" $Scrt
+            ;;
         *)
             set -- "$@" "$x"
             ;;
     esac
 done
 
-exec $($cc -print-prog-name=ld) -nostdlib "$@" -lc -dynamic-linker "$ldso"
+exec $($cc -print-prog-name=ld) -nostdlib "$@" -lc "$dynamic_linker_args"
diff -uarN musl-1.2.5-org/tools/musl-clang.in musl-1.2.5/tools/musl-clang.in
--- musl-1.2.5-org/tools/musl-clang.in	2024-03-01 03:07:33.000000000 +0100
+++ musl-1.2.5/tools/musl-clang.in	2025-10-24 19:00:02.491038267 +0200
@@ -5,14 +5,21 @@
 libc_lib="@LIBDIR@"
 thisdir="`cd "$(dirname "$0")"; pwd`"
 
+cleared=
+
 # prevent clang from running the linker (and erroring) on no input.
 sflags=
 eflags=
+dniflags=
 for x ; do
+    test "$cleared" || set -- ; cleared=1
+
     case "$x" in
+        --dni) dniflags=-l-dni; continue ;;
         -l*) input=1 ;;
         *) input= ;;
     esac
+    set -- "$@" "$x"
     if test "$input" ; then
         sflags="-l-user-start"
         eflags="-l-user-end"
@@ -29,6 +36,7 @@
     -isystem "$libc_inc" \
     -L-user-start \
     $sflags \
+    $dniflags \
     "$@" \
     $eflags \
     -L"$libc_lib" \
diff -uarN musl-1.2.5-org/tools/musl-gcc.specs.sh musl-1.2.5/tools/musl-gcc.specs.sh
--- musl-1.2.5-org/tools/musl-gcc.specs.sh	2024-03-01 03:07:33.000000000 +0100
+++ musl-1.2.5/tools/musl-gcc.specs.sh	2025-10-24 19:00:02.491038267 +0200
@@ -17,13 +17,13 @@
 libgcc.a%s %:if-exists(libgcc_eh.a%s)
 
 *startfile:
-%{!shared: $libdir/Scrt1.o} $libdir/crti.o crtbeginS.o%s
+%{!shared: %{-dni:$libdir/dcrt1.o;:$libdir/Scrt1.o}} $libdir/crti.o crtbeginS.o%s
 
 *endfile:
 crtendS.o%s $libdir/crtn.o
 
 *link:
--dynamic-linker $ldso -nostdlib %{shared:-shared} %{static:-static} %{rdynamic:-export-dynamic}
+%{-dni:-no-dynamic-linker;:--dynamic-linker $ldso} -nostdlib %{shared:-shared} %{static:-static} %{rdynamic:-export-dynamic}
 
 *esp_link:
 
_PATCH
	sed -i 's/-shared/& -Wl,-soname,libc-'"${SO_ARCH}"'.so/g' 'Makefile' || error "Failed to patch soname in ${BUILD}/musl-src/Makefile.h."
fi

if step "patch ${GCC} source"; then
	rm -rf "${BUILD}/gcc-src"
	rcp -r "${SRC}/${GCC}" "${BUILD}/gcc-src" || error "Failed to copy GCC source to ${BUILD}/gcc-src."
	cd "${BUILD}/gcc-src"
	# use dynamic linker hack unless '-fsys-dyn-linker' was given
	sed -i 's/Scrt1.o%s/%{fsys-dyn-linker|static:Scrt1.o%s;:dcrt1.o%s}/g' 'gcc/config/gnu-user.h' || error "Failed to patch startfile in ${BUILD}/gcc-src/gcc/config/gnu-user.h."
	sed -i 's/:crt1.o%s/:%{fsys-dyn-linker|static:crt1.o%s;:dcrt1.o%s}/g' 'gcc/config/gnu-user.h' || error "Failed to patch startfile in ${BUILD}/gcc-src/gcc/config/gnu-user.h."
	sed -i 's/-cc:" LINUX_SPEC/& " %{!static:%{!fno-pic:%{!fno-PIC:%{!fpic:%{!fPIC: -fPIC}}}}} "/g' 'gcc/config/linux-android.h' || error "Failed to patch -fPIC in ${BUILD}/gcc-src/gcc/config/linux-android.h."
	sed -i 's/GNU_USER_TARGET_LINK_GCC_C_SEQUENCE_SPEC$/& " %{!shared:%{!static:%{!static-pie:%{!fsys-dyn-linker:-pie -no-dynamic-linker -rpath=$ORIGIN -z origin}}}}"/g' 'gcc/config/gnu-user.h' || error "Failed to patch rpath in ${BUILD}/gcc-src/gcc/config/gnu-user.h."
	sed -i '/^posix$/i \fsys-dyn-linker\nTarget RejectNegative\nUse system dynamic linker from absolute path instead of bundled one from relative path.\n' 'gcc/config/gnu-user.opt' || error "Failed to patch cmd-line options in ${BUILD}/gcc-src/gcc/config/gnu-user.opt."
	# use architecture specific libstdc++.dll suffix
	cd "${BUILD}/gcc-src/libstdc++-v3"
	sed -i "/uclinuxfdpiceabi/,/;;/{s/library_names_spec=.*/library_names_spec='\${libname}\${shared_ext}'/g;s/soname_spec=.*/soname_spec='\${libname}\`echo \${major} | \$SED -e 's\/[.]\/-\/g'\`-${SO_ARCH}\${shared_ext}'/g}" 'configure' || error "Failed to patch ${BUILD}/gcc-src/libstdc++-v3/configure."
fi

# build host libraries

if step "build cross compiler - ${ZLIB}"; then
	mkdir -p "${BUILD}/cross-zlib" || error "Failed to create ${BUILD}/cross-zlib."
	cd "${BUILD}/cross-zlib"
	"${SRC}/${ZLIB}/configure" --static "--prefix=${HOST}/host" >>"${LOG}" 2>&1 || error "Failed to configure ${ZLIB}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${ZLIB}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${ZLIB}."
fi

if step "build cross compiler - ${GMP}"; then
	mkdir -p "${BUILD}/cross-gmp" || error "Failed to create ${BUILD}/cross-gmp."
	cd "${BUILD}/cross-gmp"
	"${SRC}/${GMP}/configure" --enable-shared --disable-static --disable-cxx "--prefix=${HOST}/host" >>"${LOG}" 2>&1 || error "Failed to configure ${GMP}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${GMP}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${GMP}."
fi

if step "build cross compiler - ${MPFR}"; then
	mkdir -p "${BUILD}/cross-mpfr" || error "Failed to create ${BUILD}/cross-mpfr."
	cd "${BUILD}/cross-mpfr"
	"${SRC}/${MPFR}/configure" --enable-shared --disable-static "--with-gmp=${HOST}/host" "--prefix=${HOST}/host" >>"${LOG}" 2>&1 || error "Failed to configure ${MPFR}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MPFR}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${MPFR}."
fi

if step "build cross compiler - ${MPC}"; then
	mkdir -p "${BUILD}/cross-mpc" || error "Failed to create ${BUILD}/cross-mpc."
	cd "${BUILD}/cross-mpc"
	"${SRC}/${MPC}/configure" --enable-shared --disable-static "--with-gmp=${HOST}/host" "--with-mpfr=${HOST}/host" "--prefix=${HOST}/host" >>"${LOG}" 2>&1 || error "Failed to configure ${MPC}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MPC}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${MPC}."
fi

if step "build cross compiler - ${ISL}"; then
	mkdir -p "${BUILD}/cross-isl" || error "Failed to create ${BUILD}/cross-isl."
	cd "${BUILD}/cross-isl"
	"${SRC}/${ISL}/configure" --enable-shared --disable-static --enable-portable-binary "--with-gmp-prefix=${HOST}/host" "--prefix=${HOST}/host" >>"${LOG}" 2>&1 || error "Failed to configure ${ISL}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${ISL}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${ISL}."
fi

if step "build cross compiler - ${CLOOG_ISL}"; then
	mkdir -p "${BUILD}/cross-cloog" || error "Failed to create ${BUILD}/cross-cloog."
	cd "${BUILD}/cross-cloog"
	"${SRC}/${CLOOG_ISL}/configure" --enable-shared --disable-static --enable-portable-binary --with-osl=no "--with-gmp-prefix=${HOST}/host" "--with-isl-prefix=${HOST}/host" "--prefix=${HOST}/host" >>"${LOG}" 2>&1 || error "Failed to configure ${CLOOG_ISL}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${CLOOG_ISL}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${CLOOG_ISL}."
fi

# prepare build cross compiler

if step "build cross compiler - ${BINUTILS} mingw"; then
	mkdir -p "${BUILD}/cross-binutils-mingw" || error "Failed to create ${BUILD}/cross-binutils-mingw."
	cd "${BUILD}/cross-binutils-mingw"
	"${SRC}/${BINUTILS}/configure" --target=x86_64-w64-mingw32 --enable-lto --enable-plugins --disable-nls "--with-system-zlib=${HOST}/host" "--prefix=${HOST}" "--with-sysroot=${HOST}" "--libdir=${HOST}/x86_64-w64-mingw32/lib" >>"${LOG}" 2>&1 || error "Failed to configure ${BINUTILS} mingw."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${BINUTILS} mingw."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${BINUTILS} mingw."
fi

if step "build cross compiler - ${MINGW} - C headers"; then
	mkdir -p "${BUILD}/cross-mingw-headers" || error "Failed to create ${BUILD}/cross-mingw-headers."
	cd "${BUILD}/cross-mingw-headers"
	"${SRC}/${MINGW}/mingw-w64-headers/configure" --host=x86_64-w64-mingw32 "--with-default-msvcrt=${MCRTDLL}" --enable-sdk=all "--prefix=${HOST}/x86_64-w64-mingw32" "--with-sysroot=${HOST}/x86_64-w64-mingw32" >>"${LOG}" 2>&1 || error "Failed to configure ${MINGW} - C headers."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MINGW} - C headers."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${MINGW} - C headers."
fi

if step "build cross compiler - ${GCC} mingw"; then
	mkdir -p "${BUILD}/cross-gcc-mingw" || error "Failed to create ${BUILD}/cross-gcc-mingw."
	cd "${BUILD}/cross-gcc-mingw"
	"${SRC}/${GCC}/configure" --target=x86_64-w64-mingw32 "--enable-languages=c,c++" $GCC_HOST_CONFIG "--with-gmp=${HOST}/host" "--with-mpfr=${HOST}/host" "--with-mpc=${HOST}/host" "--with-isl=${HOST}/host" "--with-cloog=${HOST}/host" "--with-system-zlib=${HOST}/host" "LDFLAGS=-Wl,-rpath,${HOST}/host/lib" "--prefix=${HOST}" "--with-sysroot=${HOST}/x86_64-w64-mingw32" "--libdir=${HOST}/x86_64-w64-mingw32/lib" "--libexecdir=${HOST}/x86_64-w64-mingw32/lib" "--with-native-system-header-dir=/include" >>"${LOG}" 2>&1 || error "Failed to configure ${GCC} mingw."
	make -j $THREADS all-gcc >>"${LOG}" 2>&1 || error "Failed to build ${GCC} mingw."
	make install-gcc >>"${LOG}" 2>&1 || error "Failed to install ${GCC} mingw."
fi

# prepare target cross compiler

if step "build cross compiler - ${BINUTILS} linux"; then
	mkdir -p "${BUILD}/cross-binutils-linux" || error "Failed to create ${BUILD}/cross-binutils-linux."
	cd "${BUILD}/cross-binutils-linux"
	"${SRC}/${BINUTILS}/configure" --target=${TARGET_TRIPLET} --enable-lto --enable-plugins --disable-nls "--with-system-zlib=${HOST}/host" "--prefix=${HOST}" "--with-sysroot=${HOST}" "--libdir=${HOST}/${TARGET_TRIPLET}/lib" >>"${LOG}" 2>&1 || error "Failed to configure ${BINUTILS} linux."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${BINUTILS} linux."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${BINUTILS} linux."
fi

if step "build cross compiler - ${LINUX} - C headers"; then
	rm -rf "${BUILD}/cross-linux-headers"
	rcp -r "${SRC}/${LINUX}" "${BUILD}/cross-linux-headers" || error "Failed to copy Linux headers to ${BUILD}/cross-linux-headers."
	cd "${BUILD}/cross-linux-headers"
	make "ARCH=${LINUX_ARCH}" "INSTALL_HDR_PATH=${HOST}/${TARGET_TRIPLET}/" headers_install >>"${LOG}" 2>&1 || error "Failed to install ${LINUX} - C headers."
fi

if step "build cross compiler - ${GCC} linux"; then
(
	export CFLAGS_FOR_TARGET="${CFLAGS}"
	export CXXFLAGS_FOR_TARGET="${CXXFLAGS}"
	mkdir -p "${BUILD}/cross-gcc-linux" || error "Failed to create ${BUILD}/cross-gcc-linux."
	cd "${BUILD}/cross-gcc-linux"
	"../gcc-src/configure" --target=${TARGET_TRIPLET} "--enable-languages=c,c++" $GCC_TARGET_CONFIG "--with-gmp=${HOST}/host" "--with-mpfr=${HOST}/host" "--with-mpc=${HOST}/host" "--with-isl=${HOST}/host" "--with-cloog=${HOST}/host" "--with-system-zlib=${HOST}/host" "LDFLAGS=-Wl,-rpath,${HOST}/host/lib" "--prefix=${HOST}" "--with-sysroot=${HOST}/${TARGET_TRIPLET}" "--libdir=${HOST}/${TARGET_TRIPLET}/lib" "--libexecdir=${HOST}/${TARGET_TRIPLET}/lib" "--with-native-system-header-dir=/include" >>"${LOG}" 2>&1 || error "Failed to configure ${GCC} linux."
	make -j $THREADS all-gcc >>"${LOG}" 2>&1 || error "Failed to build ${GCC} linux."
	make install-gcc >>"${LOG}" 2>&1 || error "Failed to install ${GCC} linux."
) || exit 1
fi

# setup cross environment for host compilers
export PATH="${HOST}/bin:${PATH}"

# finalize build cross compiler

if step "build cross compiler - ${MINGW} - C runtime"; then
	mkdir -p "${BUILD}/cross-mingw-crt" || error "Failed to create ${BUILD}/cross-mingw-crt."
	cd "${BUILD}/cross-mingw-crt"
	"${SRC}/${MINGW}/mingw-w64-crt/configure" --host=x86_64-w64-mingw32 "--with-default-msvcrt=${MCRTDLL}" --disable-lib32 --enable-lib64 --disable-dependency-tracking "--prefix=${HOST}/x86_64-w64-mingw32" "--with-sysroot=${HOST}/x86_64-w64-mingw32" >>"${LOG}" 2>&1 || error "Failed to configure ${MINGW} - C runtime."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MINGW} - C runtime."
	make install "lib64dir=${HOST}/x86_64-w64-mingw32/lib" >>"${LOG}" 2>&1 || error "Failed to install ${MINGW} - C runtime."
fi

if step "build cross compiler - ${MINGW} - pthreads - 64-bit"; then
	mkdir -p "${BUILD}/cross-mingw-pthread-64" || error "Failed to create ${BUILD}/cross-mingw-pthread-64."
	cd "${BUILD}/cross-mingw-pthread-64"
	"${SRC}/${MINGW}/mingw-w64-libraries/winpthreads/configure" --build=x86_64-w64-mingw32 --host=x86_64-w64-mingw32 --disable-shared --disable-dependency-tracking "AR=x86_64-w64-mingw32-gcc-ar" "--prefix=${HOST}/x86_64-w64-mingw32" "--with-sysroot=${HOST}/x86_64-w64-mingw32" >>"${LOG}" 2>&1 || error "Failed to configure ${MINGW} - pthreads - 64-bit."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MINGW} - pthreads - 64-bit."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${MINGW} - pthreads - 64-bit."
	# fix static build
	find "${HOST}/x86_64-w64-mingw32" -type f -name "pthread.h" -exec sed -i 's/ DLL_EXPORT/ WINPTHREAD_DLL_EXPORT/g' '{}' ';'
fi

if step "build cross compiler - finalize ${GCC} mingw"; then
	mkdir -p "${BUILD}/cross-final-gcc-mingw" || error "Failed to create ${BUILD}/cross-final-gcc-mingw."
	cd "${BUILD}/cross-final-gcc-mingw"
	"${SRC}/${GCC}/configure" --target=x86_64-w64-mingw32 --disable-bootstrap "--enable-languages=${GCC_LANGS}" $GCC_HOST_CONFIG --disable-cloog-version-check --enable-cloog-backend=isl "--with-gmp=${HOST}/host" "--with-mpfr=${HOST}/host" "--with-mpc=${HOST}/host" "--with-isl=${HOST}/host" "--with-cloog=${HOST}/host" "--with-system-zlib=${HOST}/host" "LDFLAGS=-Wl,-rpath,${HOST}/host/lib" "--prefix=${HOST}" "--with-sysroot=${HOST}/x86_64-w64-mingw32" "--libdir=${HOST}/x86_64-w64-mingw32/lib" "--libexecdir=${HOST}/x86_64-w64-mingw32/lib" "--with-native-system-header-dir=/include" >>"${LOG}" 2>&1 || error "Failed to configure ${GCC} mingw."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${GCC} mingw."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${GCC} mingw."
fi

if step 'build cross compiler - fix lto plugin mingw'; then
	ln -s "${HOST}/x86_64-w64-mingw32/lib/gcc/x86_64-w64-mingw32/${GCC#gcc-}/liblto_plugin.so" "${HOST}/x86_64-w64-mingw32/lib/bfd-plugins/liblto_plugin.so" || error "Failed to create link ${HOST}/x86_64-w64-mingw32/lib/bfd-plugins/liblto_plugin.so."
fi

# finalize target cross compiler

if step "build cross compiler - ${MUSL} - C runtime"; then
	mkdir -p "${BUILD}/cross-linux-crt" || error "Failed to create ${BUILD}/cross-linux-crt."
	cd "${BUILD}/cross-linux-crt"
	"${BUILD}/musl-src/configure" --host=${TARGET_TRIPLET} --enable-static --disable-shared "--prefix=${HOST}/${TARGET_TRIPLET}" >>"${LOG}" 2>&1 || error "Failed to configure ${MUSL} - C runtime."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MUSL} - C runtime."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${MUSL} - C runtime."
fi

if step "build cross compiler - finalize ${GCC} linux"; then
(
	export CFLAGS_FOR_TARGET="${CFLAGS}"
	export CXXFLAGS_FOR_TARGET="${CXXFLAGS}"
	mkdir -p "${BUILD}/cross-final-gcc-linux" || error "Failed to create ${BUILD}/cross-final-gcc-linux."
	cd "${BUILD}/cross-final-gcc-linux"
	"../gcc-src/configure" --target=${TARGET_TRIPLET} --disable-bootstrap "--enable-languages=${GCC_LANGS}" $GCC_TARGET_CONFIG --disable-cloog-version-check --enable-cloog-backend=isl "--with-gmp=${HOST}/host" "--with-mpfr=${HOST}/host" "--with-mpc=${HOST}/host" "--with-isl=${HOST}/host" "--with-cloog=${HOST}/host" "--with-system-zlib=${HOST}/host" "LDFLAGS=-Wl,-rpath,${HOST}/host/lib" "--prefix=${HOST}" "--with-sysroot=${HOST}/${TARGET_TRIPLET}" "--libdir=${HOST}/${TARGET_TRIPLET}/lib" "--libexecdir=${HOST}/${TARGET_TRIPLET}/lib" "--with-native-system-header-dir=/include" >>"${LOG}" 2>&1 || error "Failed to configure ${GCC} linux."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${GCC} linux."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${GCC} linux."
) || exit 1
fi

if step 'build cross compiler - fix lto plugin linux'; then
	ln -s "${HOST}/${TARGET_TRIPLET}/lib/gcc/${TARGET_TRIPLET}/${GCC#gcc-}/liblto_plugin.so" "${HOST}/${TARGET_TRIPLET}/lib/bfd-plugins/liblto_plugin.so" || error "Failed to create link ${HOST}/${TARGET_TRIPLET}/lib/bfd-plugins/liblto_plugin.so."
fi

if step "build cross compiler - ${MUSL} - shared C runtime"; then
	mkdir -p "${BUILD}/cross-linux-crt-shared" || error "Failed to create ${BUILD}/cross-linux-crt-shared."
	cd "${BUILD}/cross-linux-crt-shared"
	"${BUILD}/musl-src/configure" --host=${TARGET_TRIPLET} --enable-static --enable-shared "--prefix=${HOST}/${TARGET_TRIPLET}" >>"${LOG}" 2>&1 || error "Failed to configure ${MUSL} - C runtime shared."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MUSL} - C runtime shared."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${MUSL} - C runtime shared."
fi

# build final toolchain

if step "build ${ZLIB:-zlib}"; then
	rm -rf "${BUILD}/zlib"
	rcp -r "${SRC}/${ZLIB}" "${BUILD}/zlib" || error "Failed to copy zlib source to ${BUILD}/zlib."
	cd "${BUILD}/zlib"
	make -j $THREADS -f win32/Makefile.gcc PREFIX=x86_64-w64-mingw32- AR=x86_64-w64-mingw32-gcc-ar "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" >>"${LOG}" 2>&1 || error "Failed to build ${ZLIB}."
	make -j $THREADS -f win32/Makefile.gcc install PREFIX=x86_64-w64-mingw32- AR=x86_64-w64-mingw32-gcc-ar "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" "prefix=${HOST}/x86_64-w64-mingw32" "BINARY_PATH=${HOST}/x86_64-w64-mingw32/bin" "INCLUDE_PATH=${HOST}/x86_64-w64-mingw32/include" "LIBRARY_PATH=${HOST}/x86_64-w64-mingw32/lib" >>"${LOG}" 2>&1 || error "Failed to build ${ZLIB}."
fi

if step "build ${ZSTD:-zstd}"; then
	if [ "x${ZSTD}" != 'x' ]; then
		rm -rf "${BUILD}/zstd"
		rcp -r "${SRC}/${ZSTD}" "${BUILD}/zstd" || error "Failed to copy zstd source to ${BUILD}/zstd."
		cd "${BUILD}/zstd"
		make -j $THREADS -C lib lib-release TARGET_SYSTEM=Windows_NT CC=x86_64-w64-mingw32-gcc WINDRES=x86_64-w64-mingw32-windres AR=x86_64-w64-mingw32-ar "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" >>"${LOG}" 2>&1 || error "Failed to build ${ZSTD}."
		make -j $THREADS -C lib install-static install-includes TARGET_SYSTEM=Windows_NT CC=x86_64-w64-mingw32-gcc WINDRES=x86_64-w64-mingw32-windres AR=x86_64-w64-mingw32-ar "CFLAGS=${CFLAGS}" "LDFLAGS=${LDFLAGS}" "prefix=${HOST}/x86_64-w64-mingw32" >>"${LOG}" 2>&1 || error "Failed to build ${ZSTD}."
		sed -i '/Dependencies/a \#define ZSTD_STATIC_LINKING_ONLY' "${HOST}/x86_64-w64-mingw32/include/zstd.h"
		WITH_ZSTD='--with-zstd'
		ZIP_OPT='zstd'
	else
		WITH_ZSTD=''
		ZIP_OPT='zlib'
		echo 'Skipped. Not configured.'
	fi
fi

if step "build ${GMP:-gmp}"; then
	mkdir -p "${BUILD}/gmp" || error "Failed to create ${BUILD}/gmp."
	cd "${BUILD}/gmp"
	CPPFLAGS="-fexceptions" "${SRC}/${GMP}/configure" --host=x86_64-w64-mingw32 --enable-static --disable-shared --disable-cxx "--prefix=${HOST}/x86_64-w64-mingw32" >>"${LOG}" 2>&1 || error "Failed to configure ${GMP}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${GMP}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${GMP}."
fi

if step "build ${MPFR:-mpfr}"; then
	mkdir -p "${BUILD}/mpfr" || error "Failed to create ${BUILD}/mpfr."
	cd "${BUILD}/mpfr"
	"${SRC}/${MPFR}/configure" --host=x86_64-w64-mingw32 --enable-static --disable-shared "--with-gmp=${HOST}/x86_64-w64-mingw32" "--prefix=${HOST}/x86_64-w64-mingw32" >>"${LOG}" 2>&1 || error "Failed to configure ${MPFR}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MPFR}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${MPFR}."
fi

if step "build ${MPC:-mpc}"; then
	mkdir -p "${BUILD}/mpc" || error "Failed to create ${BUILD}/mpc."
	cd "${BUILD}/mpc"
	"${SRC}/${MPC}/configure" --host=x86_64-w64-mingw32 --enable-static --disable-shared "--with-gmp=${HOST}/x86_64-w64-mingw32" "--with-mpfr=${HOST}/x86_64-w64-mingw32" "--prefix=${HOST}/x86_64-w64-mingw32" >>"${LOG}" 2>&1 || error "Failed to configure ${MPC}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MPC}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${MPC}."
fi

if step "build ${ISL:-isl}"; then
	mkdir -p "${BUILD}/isl" || error "Failed to create ${BUILD}/isl."
	cd "${BUILD}/isl"
	"${SRC}/${ISL}/configure" --host=x86_64-w64-mingw32 --enable-static --disable-shared --enable-portable-binary "--with-gmp-prefix=${HOST}/x86_64-w64-mingw32" "--prefix=${HOST}/x86_64-w64-mingw32" >>"${LOG}" 2>&1 || error "Failed to configure ${ISL}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${ISL}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${ISL}."
fi

if step "build ${CLOOG_ISL:-cloog-isl}"; then
	mkdir -p "${BUILD}/cloog" || error "Failed to create ${BUILD}/cloog."
	cd "${BUILD}/cloog"
	"${SRC}/${CLOOG_ISL}/configure" --host=x86_64-w64-mingw32 --enable-static --disable-shared --enable-portable-binary --with-osl=no "--with-gmp-prefix=${HOST}/x86_64-w64-mingw32" "--with-isl-prefix=${HOST}/x86_64-w64-mingw32" "--prefix=${HOST}/x86_64-w64-mingw32" >>"${LOG}" 2>&1 || error "Failed to configure ${CLOOG_ISL}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${CLOOG_ISL}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${CLOOG_ISL}."
fi

if step "build ${BINUTILS:-binutils}"; then
	mkdir -p "${BUILD}/binutils" || error "Failed to create ${BUILD}/binutils."
	cd "${BUILD}/binutils"
	"${SRC}/${BINUTILS}/configure" --host=x86_64-w64-mingw32 --target=${TARGET_TRIPLET} --enable-lto --enable-plugins --disable-nls "--with-system-zlib=${HOST}/x86_64-w64-mingw32" "--with-sysroot=${PREFIX}/${TARGET_TRIPLET}" "--prefix=${PREFIX}" "--libdir=${PREFIX}/${TARGET_TRIPLET}/lib" >>"${LOG}" 2>&1 || error "Failed to configure ${BINUTILS}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${BINUTILS}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${BINUTILS}."
fi

if step "build ${LINUX} - C headers"; then
	rm -rf "${BUILD}/linux-headers"
	rcp -r "${SRC}/${LINUX}" "${BUILD}/linux-headers" || error "Failed to copy Linux headers to ${BUILD}/linux-headers."
	cd "${BUILD}/linux-headers"
	make "ARCH=${LINUX_ARCH}" "INSTALL_HDR_PATH=${PREFIX}/${TARGET_TRIPLET}/" headers_install >>"${LOG}" 2>&1 || error "Failed to install ${LINUX} - C headers."
fi

if step "build ${MUSL} - C runtime"; then
	mkdir -p "${BUILD}/linux-crt" || error "Failed to create ${BUILD}/linux-crt."
	cd "${BUILD}/linux-crt"
	"${BUILD}/musl-src/configure" --host=${TARGET_TRIPLET} --enable-static --enable-shared "--prefix=${PREFIX}/${TARGET_TRIPLET}" >>"${LOG}" 2>&1 || error "Failed to configure ${MUSL} - C runtime."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${MUSL} - C runtime."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${MUSL} - C runtime."
fi

if step "build final ${GCC}"; then
(
	export CFLAGS_FOR_TARGET="${CFLAGS}"
	export CXXFLAGS_FOR_TARGET="${CXXFLAGS}"
	mkdir -p "${BUILD}/gcc" || error "Failed to create ${BUILD}/gcc."
	cd "${BUILD}/gcc"
	"../gcc-src/configure" --host=x86_64-w64-mingw32 --target=${TARGET_TRIPLET} --disable-bootstrap "--enable-languages=${GCC_LANGS}" $GCC_TARGET_CONFIG "--enable-default-compressed-debug-sections-algorithm=${ZIP_OPT}" --disable-cloog-version-check --enable-cloog-backend=isl "--with-gmp=${HOST}/x86_64-w64-mingw32" "--with-mpfr=${HOST}/x86_64-w64-mingw32" "--with-mpc=${HOST}/x86_64-w64-mingw32" "--with-isl=${HOST}/x86_64-w64-mingw32" "--with-cloog=${HOST}/x86_64-w64-mingw32" "--with-system-zlib=${HOST}/x86_64-w64-mingw32" "${WITH_ZSTD}" "--prefix=${PREFIX}" "--libdir=${PREFIX}/${TARGET_TRIPLET}/lib" "--libexecdir=${PREFIX}/${TARGET_TRIPLET}/lib" "--with-native-system-header-dir=/${TARGET_TRIPLET}/include" >>"${LOG}" 2>&1 || error "Failed to configure ${GCC}."
	make -j $THREADS >>"${LOG}" 2>&1 || error "Failed to build ${GCC}."
	make install >>"${LOG}" 2>&1 || error "Failed to install ${GCC}."
) || exit 1
fi

if step "final adjustments for ${GCC}"; then
	# correct LTO plugin paths
	rm -f "${PREFIX}/bin/liblto_plugin.dll" "${PREFIX}/${TARGET_TRIPLET}/lib/bfd-plugins/liblto_plugin.dll"
	cd "${PREFIX}/bin" && ln -s "../${TARGET_TRIPLET}/lib/gcc/${TARGET_TRIPLET}/${GCC#gcc-}/liblto_plugin.dll" "liblto_plugin.dll" || error "Failed to create link ${PREFIX}/${TARGET_TRIPLET}/lib/bfd-plugins/liblto_plugin.dll."
	cd "${PREFIX}/${TARGET_TRIPLET}/lib/bfd-plugins/" && ln -s "../../../${TARGET_TRIPLET}/lib/gcc/${TARGET_TRIPLET}/${GCC#gcc-}/liblto_plugin.dll" "liblto_plugin.dll" || error "Failed to create link ${PREFIX}/${TARGET_TRIPLET}/lib/bfd-plugins/liblto_plugin.dll."
	rmdir "${PREFIX}/include" 2>/dev/null # delete if empty
	cd "${PREFIX}/${TARGET_TRIPLET}/libexec"
	cp "../lib/libc.so" "libc-${SO_ARCH}.so" || error "Failed to copy ${PREFIX}/${TARGET_TRIPLET}/lib/libc.so."
	eval "TARGET_LIBSTDCPP_SONAME=$(grep dlname= "../lib/gcc/${TARGET_TRIPLET}/${GCC#gcc-}/libstdc++.la" | sed 's/dlname=//g')"
	cp -L "../lib/gcc/${TARGET_TRIPLET}/${GCC#gcc-}/libstdc++.so" "${TARGET_LIBSTDCPP_SONAME}" || error "Failed to copy ${PREFIX}/${TARGET_TRIPLET}/lib/gcc/${TARGET_TRIPLET}/${GCC#gcc-}/libstdc++.so."
fi

if step "build Windows SFX installer using ${SEVENZIP}"; then
	if [ "x${SEVENZIP}" != 'x' ]; then
		rm -rf "${BUILD}/7zip"
		rcp -r "${SRC}/${SEVENZIP}" "${BUILD}/7zip" || error "Failed to copy 7-Zip source to ${BUILD}/7zip."
		cd "${BUILD}/7zip"
		sed -i '/7-Zip GUI/a \  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">\n    <security>\n      <requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3">\n        <requestedExecutionLevel level="requireAdministrator" uiAccess="false"/>\n      </requestedPrivileges>\n    </security>\n  </trustInfo>' 'CPP/7zip/UI/GUI/7zG.exe.manifest' || error "Failed to patch admin rights in ${BUILD}/7zip/CPP/7zip/UI/GUI/7zG.exe.manifest."
		cat <<"_PATCH" | sed 's/$/\r/' | patch -p1 --binary >>"${LOG}" 2>&1 || error "Failed to apply patches to ${BUILD}/7zip."
diff -uar 7z2501-src-org/CPP/7zip/UI/GUI/ExtractGUI.cpp 7z2501-src/CPP/7zip/UI/GUI/ExtractGUI.cpp
--- 7z2501-src-org/CPP/7zip/UI/GUI/ExtractGUI.cpp	2023-12-11 12:00:00.000000000 +0100
+++ 7z2501-src/CPP/7zip/UI/GUI/ExtractGUI.cpp	2025-10-19 00:27:56.647774926 +0200
@@ -36,6 +36,8 @@
 
 static const wchar_t * const kIncorrectOutDir = L"Incorrect output directory path";
 
+bool EnableCaseSensitivity(const wchar_t * path, const wchar_t ** err);
+
 #ifndef Z7_SFX
 
 static void AddValuePair(UString &s, UINT resourceID, UInt64 value, bool addColon = true)
@@ -253,6 +255,13 @@
       return E_FAIL;
     }
     NName::NormalizeDirPathPrefix(options.OutputDir);
+    const wchar_t * err = NULL;
+    if (!EnableCaseSensitivity(fs2us(options.OutputDir), &err))
+    {
+      ShowErrorMessage(err);
+      messageWasDisplayed = true;
+      return E_FAIL;
+    }
     
     /*
     if (!CreateComplexDirectory(options.OutputDir))
_PATCH
		cd "${BUILD}/7zip/CPP/7zip/Bundles/SFXWin"
		sed -e 's/^!//g' -e '/\(Aes\|Crc\|LzmaDec\|Sha256\|7zip\)\.mak/d' -e '/^include/s/"//g' -e 's/^IFDEF/ifdef/g' -e 's/^ELSE/else/g' -e 's/^ENDIF/endif/g' -e 's|$O\\|$O/|g' -e 's/\.obj/.o/g' -e 's/CFLAGS = $(CFLAGS)/LOCAL_FLAGS = /g' -e '/ifdef UNDER_CE/,/endif/d' makefile > makefile.gcc || error "Failed to create ${BUILD}/7zip/CPP/7zip/Bundles/SFXWin/makefile.gcc."
		cat <<"_PATCH" >SetCase.cpp || error "Failed to create ${BUILD}/7zip/CPP/7zip/Bundles/SFXWin/SetCase.cpp."
#include <windows.h>
#include <winternl.h>

#define FileCaseSensitiveInformation 71

#ifndef STATUS_DIRECTORY_NOT_EMPTY
#define STATUS_DIRECTORY_NOT_EMPTY 0xC0000101
#endif /* STATUS_DIRECTORY_NOT_EMPTY */

enum CASE_SENSITIVITY_FLAGS {
	CaseInsensitiveDirectory = 0x00000000,
	CaseSensitiveDirectory   = 0x00000001
};

typedef NTSTATUS (NTAPI *NtSetInformationFilePtr)(HANDLE, PIO_STATUS_BLOCK, PVOID, ULONG, FILE_INFORMATION_CLASS);

bool EnableCaseSensitivity(const wchar_t * path, const wchar_t ** err) {
	CreateDirectoryW(path, nullptr);
	const HANDLE hFile = CreateFileW(path, FILE_WRITE_ATTRIBUTES, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, nullptr);
	if (hFile == INVALID_HANDLE_VALUE) {
		if ( err ) {
			*err = L"Failed to make output directory path case-sensitive. No permission.";
		}
		return false;
	}
	const HMODULE ntdll = LoadLibraryW(L"ntdll.dll");
	if ( ! ntdll ) {
		CloseHandle(hFile);
		if ( err ) {
			*err = L"Failed to load ntdll.dll.";
		}
		return false;
	}
	const NtSetInformationFilePtr NtSetInformationFile = reinterpret_cast<NtSetInformationFilePtr>(
		reinterpret_cast<void *>(GetProcAddress(ntdll, "NtSetInformationFile"))
	);
	if ( ! NtSetInformationFile ) {
		CloseHandle(hFile);
		FreeLibrary(ntdll);
		if ( err ) {
			*err = L"Failed to get address of NtSetInformationFile.";
		}
		return false;
	}
	IO_STATUS_BLOCK iosb = {};
	FILE_CASE_SENSITIVE_INFORMATION caseSensitive = { CaseSensitiveDirectory };
	const NTSTATUS status = NtSetInformationFile(hFile, &iosb, &caseSensitive, sizeof(caseSensitive), FILE_INFORMATION_CLASS(FileCaseSensitiveInformation));
	CloseHandle(hFile);
	FreeLibrary(ntdll);
	if (DWORD(status) == STATUS_DIRECTORY_NOT_EMPTY) {
		if ( err ) {
			*err = L"Failed to make output directory path case-sensitive. Not empty.";
		}
		return false;
	} else if (DWORD(status) == STATUS_INVALID_PARAMETER) {
		if ( err ) {
			*err = L"Target partition does not support case-sensitive paths. Select an NTFS partition.";
		}
		return false;
	} else if ( ! (NT_SUCCESS(status)) ) {
		if ( err ) {
			*err = L"Failed to make output directory path case-sensitive. No permission.";
		}
		return false;
	}
	return true;
}
_PATCH
		cat <<"_PATCH" >>makefile.gcc || error "Failed to patch newly created ${BUILD}/7zip/CPP/7zip/Bundles/SFXWin/makefile.gcc."

include ../../LzmaDec_gcc.mak

COMMON_OBJS += \
  $O/Sha256Prepare.o \

C_OBJS += \
  $O/7zCrc.o \
  $O/7zCrcOpt.o \
  $O/Aes.o \
  $O/AesOpt.o \
  $O/Sha256.o \
  $O/Sha256Opt.o \

OBJS = \
  $(CURRENT_OBJS) \
  $(COMMON_OBJS) \
  $(WIN_OBJS) \
  $(WIN_CTRL_OBJS) \
  $(7ZIP_COMMON_OBJS) \
  $(UI_COMMON_OBJS) \
  $(AGENT_OBJS) \
  $(CONSOLE_OBJS) \
  $(EXPLORER_OBJS) \
  $(FM_OBJS) \
  $(GUI_OBJS) \
  $(AR_COMMON_OBJS) \
  $(AR_OBJS) \
  $(7Z_OBJS) \
  $(CAB_OBJS) \
  $(CHM_OBJS) \
  $(COM_OBJS) \
  $(ISO_OBJS) \
  $(NSIS_OBJS) \
  $(RAR_OBJS) \
  $(TAR_OBJS) \
  $(UDF_OBJS) \
  $(WIM_OBJS) \
  $(ZIP_OBJS) \
  $(COMPRESS_OBJS) \
  $(CRYPTO_OBJS) \
  $(C_OBJS) \
  $(ASM_OBJS) \
  $O/SetCase.o \
  $O/resource.o \

include ../../7zip_gcc.mak

$O/SetCase.o: ./SetCase.cpp
	$(CXX) $(CXXFLAGS) $<
$O/SfxWin.o: ./SfxWin.cpp
	$(CXX) $(CXXFLAGS) $<
_PATCH
		find ../../ -type f -name '*.mak' -exec sed -i 's/\(-l[^ ]*\)/\L\1/g' '{}' ';' >>"${LOG}" 2>&1 || error "Failed to patch case for libraries in Makefiles within ${BUILD}/7zip/CPP/7zip."
		find ../../../../ -type f \( -name '*.h' -o -name '*.c' -o -name '*.cpp' -o -name '*.rc' \) -exec sed -i 's/\(#include \+<\)\([^>]*\)\(>\)/\1\L\2\E\3/' '{}' ';' >>"${LOG}" 2>&1 || error "Failed to patch case for C/C++ includes within ${BUILD}/7zip/CPP/7zip."
		make -f makefile.gcc all -j $THREADS O=out IS_MINGW=1 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ RC=x86_64-w64-mingw32-windres SHARED_EXT= 'CXXFLAGS_EXTRA=-O2 -DZ7_NO_CRYPTO' 'CFLAGS_WARN_WALL=-Wall -Wextra -DZ7_NO_CRYPTO' 'FLAGS_FLTO=-flto -flto-partition=none -fuse-linker-plugin -mwindows' >>"${LOG}" 2>&1 || error "Failed to build ${SEVENZIP}."
	else
		echo 'Skipped. Not configured.'
	fi
fi

if step 'strip debug symbols in executables'; then
	cd "${PREFIX}"
	cat <<"_EOF" >"${BUILD}/remove-signature.sh" || error "Failed to create ${BUILD}/remove-signature.sh."
#!/bin/sh
osslsigncode remove-signature -in "$1" -out "$1.tmp" >/dev/null 2>&1 && mv -f "$1.tmp" "$1" >/dev/null 2>&1
_EOF
	chmod 755 "${BUILD}/remove-signature.sh"
	# ensure previously attached code sign certificates are removed before stripping
	find . -type f '(' -iname '*.dll' -o -iname '*.pyd' -o -iname '*.exe' ')' -exec "${BUILD}/remove-signature.sh" '{}' ';' >>"${LOG}" 2>&1
	find . -type f '(' -iname '*.dll' -o -iname '*.pyd' -o -iname '*.exe' ')' -exec "${HOST}/bin/x86_64-w64-mingw32-strip" --strip-all '{}' ';' >>"${LOG}" 2>&1
	find "${TARGET_TRIPLET}/libexec" -type f -iname '*.so' -exec "${HOST}/bin/${TARGET_TRIPLET}-strip" --strip-all '{}' ';' >>"${LOG}" 2>&1
fi

if step 'create copyright and license files'; then
	mkdir -p "${LICENSE}" || error "Failed to create ${LICENSE}."
	mkdir -p "${BUILD}/license" || error "Failed to create ${BUILD}/license."
	cd "${BUILD}/license"
	targets="${ZLIB}"
	targets="${targets} ${GMP}"
	targets="${targets} ${MPFR}"
	targets="${targets} ${MPC}"
	targets="${targets} ${ISL}"
	targets="${targets} ${CLOOG_ISL}"
	targets="${targets} ${BINUTILS}"
	targets="${targets} ${MINGW}"
	targets="${targets} ${GCC}"
	targets="${targets} ${MUSL}"
	targets="${targets} ${LINUX}"
	[ "x${ZSTD}" != 'x' ] && targets="${targets} ${ZSTD}"
	[ "x${SEVENZIP}" != 'x' ] && targets="${targets} ${SEVENZIP}"
	cat <<"_EOF" >Makefile
all: $(addsuffix .txt,$(addprefix $(DST)/,$(TARGETS)))
$(DST)/%.txt: $(SRC)/%
	cd "$<" && licensecheck --copyright -c '.*' -r -l 0 -i '(?i)(.*(huffman-rand-max\.in)|(mutation\.d)|(\.(1|au|bin|bz2|chm|crw|doctree|dia|elf5|exe|golden|gif|gmo|gz|html|icns|ico|jpg|jpeg|odg|odp|pdf|png|po|pptx|psd|pyc|sln|so|tar|tif|vcproj|vcxproj|wav|whl|xls|xz|zip)))' -- * | sed -e '/: \*No copyright\* UNKNOWN$$/d' -e '/^[[:space:]]*$$/d' >"$@"
_EOF
	make -j $THREADS "SRC=${SRC}" "DST=${LICENSE}" "TARGETS=${targets}" 2>&1 | grep -v 'does not map to ascii at' >>"${LOG}" || error "Failed to create copyright and licenses."
fi

if step 'sign executables'; then
	if [ "x${SIGN}" != 'x' ]; then
		cd "${ROOT}"
		find "${PREFIX}" -type f '(' -iname '*.dll' -o -iname '*.pyd' -o -iname '*.exe' ')' -exec "${SIGN}" '{}' ';' >>"${LOG}" 2>&1 || error "Failed to sign files."
	else
		echo 'Skipped. Not configured.'
	fi
fi

if step 'create distribution package'; then
	cd "${ROOT}"
	cp "${0}" "${PREFIX}/" || error "Failed to copy ${0} to ${PREFIX}."
	cd "${PREFIX}"
	find . -depth -type d -name '__pycache__' -exec rm -rf '{}' ';'
	GDB="$(echo "${GDB}" | sed 's/^gdb-gdb/gdb/')"
	OUTNAME="${GCC}-${BINUTILS}-${LINUX}-${MUSL}-${GCC_ARCH}"
	rm -f "${ROOT}/${OUTNAME}."* >/dev/null 2>&1
	7z a -t7z -mx9 -myx -md192m -mfb273 -ms=on -l "${ROOT}/${OUTNAME}.7z" * || error "Failed to pack ${OUTNAME}.7z."
	if [ "x${SEVENZIP}" != 'x' ]; then
		cat "${BUILD}/7zip/CPP/7zip/Bundles/SFXWin/out/7z.sfx" "${ROOT}/${OUTNAME}.7z" >"${ROOT}/${OUTNAME}.exe" || error "Failed to create ${OUTNAME}.exe."
		if [ "x${SIGN}" != 'x' ]; then
			"${SIGN}" "${ROOT}/${OUTNAME}.exe" >>"${LOG}" 2>&1 || error "Failed to sign ${ROOT}/${OUTNAME}.exe."
		fi
	fi
	# The following commands can be used to retain symlinks.
	# This, however, requires admin right on Windows for unpacking.
	#rm -f "${ROOT}/${OUTNAME}.tar.xz" >/dev/null 2>&1
	#XZ_OPT="-e9 --lzma2=dict=192MiB,nice=273" tar -cJf "${ROOT}/${OUTNAME}.tar.xz" --owner=0 --group=0 --mode=og-w * || error "Failed to pack ${OUTNAME}.tar.xz."
fi
