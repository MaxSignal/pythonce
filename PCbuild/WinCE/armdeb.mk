#
#	ARM Debug
#
PLATFORM_OUTDIR=ARMDbg$(TARGET_OSVERSION)
PLATFORM_INTDIR=ARMDbg$(TARGET_OSVERSION)
#PLATFORM_DLL_SUFFIX=_d
PLATFORM_CPP=clarm.exe
PLATFORM_CPP_PROJ=/D "ARM" /D "_ARM_" $(CFLAGS_DEBUG) $(CFLAGS)
PLATFORM_LINK32_FLAGS=/debug /subsystem:$(CESubsystem) /align:"4096" /MACHINE:ARM 
PLATFORM_LINK32_DLL_FLAGS=/base:"0x00100000" /entry:"_DllMainCRTStartup" $(PLATFORM_LINK32_FLAGS)
PLATFORM_RSCFLAGS=/d "ARM" /d "_ARM_" /d "DEBUG"
