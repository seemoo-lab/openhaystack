find_program(AVR_GCC_RANLIB avr-gcc-ranlib)
find_program(AVR_AR avr-ar)
find_program(AVR_AS avr-as)
find_program(AVR_GCC avr-gcc)
find_program(AVR_GPP avr-g++)
find_program(AVR_OBJCOPY avr-objcopy)

set(CMAKE_OSX_SYSROOT "/")
set(CMAKE_OSX_DEPLOYMENT_TARGET "")

set(CODAL_TOOLCHAIN "AVR_GCC")

if(CMAKE_VERSION VERSION_LESS "3.5.0")
    include(CMakeForceCompiler)
    cmake_force_c_compiler("${AVR_GCC}" GNU)
    cmake_force_cxx_compiler("${AVR_GPP}" GNU)
else()
    #-Wl,-flto -flto -fno-fat-lto-objects
    # from 3.5 the force_compiler macro is deprecated: CMake can detect
    # arm-none-eabi-gcc as being a GNU compiler automatically
	set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
    set(CMAKE_C_COMPILER "${AVR_GCC}")
    set(CMAKE_CXX_COMPILER "${AVR_GPP}")
endif()

SET(CMAKE_ASM_COMPILER "${AVR_GCC}")
SET(CMAKE_AR "${AVR_AR}" CACHE FILEPATH "Archiver")
SET(CMAKE_RANLIB "${AVR_GCC_RANLIB}" CACHE FILEPATH "rlib")
set(CMAKE_CXX_OUTPUT_EXTENSION ".o")
