#
#	X86 Emulator Release
#
PLATFORM_OUTDIR=X86EMRel
PLATFORM_INTDIR=X86EMRel
PLATFORM_CPP=cl.exe
PLATFORM_CPP_PROJ=/D "i486" /D "_X86_" /D "x86" /D "NDEBUG" $(CFLAGS) /Gz /Oxs 
PLATFORM_LINK32_FLAGS=/windowsce:emulation /MACHINE:IX86 
PLATFORM_LINK32_DLL_FLAGS=$(PLATFORM_LINK32_FLAGS)
PLATFORM_RSCFLAGS=/d "_X86_" /d "x86" /d "i486" /d "NDEBUG"
