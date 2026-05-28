.autodepend

TESTDIR = test

all: makedirs genfiles objs

listhdrs:
        $(MAKEDIR)\GenSrc4Hdrs -f*.h -c.\testconfig.ini -m_filelist.inc -o$(TESTDIR) -l .

makeinc:
        $(MAKEDIR)\GenSrc4Hdrs -f*.h -c.\testconfig.ini -m_filelist.inc -o$(TESTDIR) -s- .

genfiles:
        $(MAKEDIR)\GenSrc4Hdrs -f*.h -c.\testconfig.ini -m_filelist.inc -o$(TESTDIR) .

cobjs:
        $(MAKE) -fc_comp.mak cobjs

cppobjs:
        $(MAKE) -fcpp_comp.mak cppobjs

objs: cppobjs cobjs

makedirs:
	@if not exist $(TESTDIR) md $(TESTDIR)
	@if not exist $(TESTDIR)\cppobj md $(TESTDIR)\cppobj
	@if not exist $(TESTDIR)\cobj md $(TESTDIR)\cobj

clean:
	@del $(TESTDIR)\cppobj\test.pch
	@del $(TESTDIR)\cppobj\test.?0?
	@del $(TESTDIR)\cobj\test.pch
	@del $(TESTDIR)\cobj\test.?0?




