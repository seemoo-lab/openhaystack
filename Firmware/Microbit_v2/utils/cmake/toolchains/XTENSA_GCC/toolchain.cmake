find_program(XTENSA_RANLIB xtensa-lx106-elf-gcc-ranlib)
find_program(XTENSA_AR xtensa-lx106-elf-gcc-ar)
find_program(XTENSA_GCC xtensa-lx106-elf-gcc)
find_program(XTENSA_GPP xtensa-lx106-elf-g++)
find_program(XTENSA_OBJCOPY xtensa-lx106-elf-objcopy)

set(CMAKE_OSX_SYSROOT "/")
set(CMAKE_OSX_DEPLOYMENT_TARGET "")

set(CODAL_TOOLCHAIN "XTENSA_GCC")

if(CMAKE_VERSION VERSION_LESS "3.5.0")
    include(CMakeForceCompiler)
    cmake_force_c_compiler("${XTENSA_GCC}" GNU)
    cmake_force_cxx_compiler("${XTENSA_GPP}" GNU)
else()
    # from 3.5 the force_compiler macro is deprecated: CMake can detect
    # arm-none-eabi-gcc as being a GNU compiler automatically
	set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
    set(CMAKE_C_COMPILER "${XTENSA_GCC}")
    set(CMAKE_CXX_COMPILER "${XTENSA_GPP}")
endif()

SET(CMAKE_AR "${XTENSA_AR}" CACHE FILEPATH "Archiver")
SET(CMAKE_RANLIB "${XTENSA_RANLIB}" CACHE FILEPATH "rlib")
set(CMAKE_CXX_OUTPUT_EXTENSION ".o")
