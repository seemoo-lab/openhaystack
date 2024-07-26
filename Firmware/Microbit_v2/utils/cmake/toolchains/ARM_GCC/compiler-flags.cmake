set(EXPLICIT_INCLUDES "")
if((CMAKE_VERSION VERSION_GREATER "3.4.0") OR (CMAKE_VERSION VERSION_EQUAL "3.4.0"))
    # from CMake 3.4 <INCLUDES> are separate to <FLAGS> in the
    # CMAKE_<LANG>_COMPILE_OBJECT, CMAKE_<LANG>_CREATE_ASSEMBLY_SOURCE, and
    # CMAKE_<LANG>_CREATE_PREPROCESSED_SOURCE commands
    set(EXPLICIT_INCLUDES "<INCLUDES> ")
endif()

# Override the link rules:
set(CMAKE_C_CREATE_SHARED_LIBRARY "echo 'shared libraries not supported' && 1")
set(CMAKE_C_CREATE_SHARED_MODULE  "echo 'shared modules not supported' && 1")
set(CMAKE_C_CREATE_STATIC_LIBRARY "<CMAKE_AR> -cr <LINK_FLAGS> <TARGET> <OBJECTS>")
set(CMAKE_C_COMPILE_OBJECT        "<CMAKE_C_COMPILER> <DEFINES> ${EXPLICIT_INCLUDES}<FLAGS> -o <OBJECT> -c <SOURCE>")

set(CMAKE_C_LINK_EXECUTABLE       "<CMAKE_C_COMPILER> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> -Wl,-Map,<TARGET>.map -Wl,--start-group <OBJECTS> <LINK_LIBRARIES> -lm -lc -lgcc -lm -lc -lgcc -Wl,--end-group --specs=nano.specs -o <TARGET>")

set(CMAKE_CXX_OUTPUT_EXTENSION ".o")
set(CMAKE_DEPFILE_FLAGS_CXX "-MMD -MT <OBJECT> -MF <DEPFILE>")
set(CMAKE_C_OUTPUT_EXTENSION ".o")
set(CMAKE_DEPFILE_FLAGS_C "-MMD -MT <OBJECT> -MF <DEPFILE>")

set(CMAKE_C_FLAGS_DEBUG_INIT          "-g -gdwarf-3")
set(CMAKE_C_FLAGS_MINSIZEREL_INIT     "-Os -DNDEBUG")
set(CMAKE_C_FLAGS_RELEASE_INIT        "-Os -DNDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO_INIT "-Os -g -gdwarf-3 -DNDEBUG")
set(CMAKE_INCLUDE_SYSTEM_FLAG_C "-isystem ")


set(CMAKE_ASM_FLAGS_DEBUG_INIT          "-g -gdwarf-3")
set(CMAKE_ASM_FLAGS_MINSIZEREL_INIT     "-Os -DNDEBUG")
set(CMAKE_ASM_FLAGS_RELEASE_INIT        "-Os -DNDEBUG")
set(CMAKE_ASM_FLAGS_RELWITHDEBINFO_INIT "-Os -g -gdwarf-3 -DNDEBUG")
set(CMAKE_INCLUDE_SYSTEM_FLAG_ASM  "-isystem ")

set(CMAKE_CXX_CREATE_STATIC_LIBRARY "<CMAKE_AR> -cr <LINK_FLAGS> <TARGET> <OBJECTS>")

set(CMAKE_CXX_LINK_EXECUTABLE       "<CMAKE_CXX_COMPILER> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> -Wl,-Map,<TARGET>.map -Wl,--start-group <OBJECTS> <LINK_LIBRARIES> -lnosys -lstdc++ -lsupc++ -lm -lc -lgcc -lstdc++ -lsupc++ -lm -lc -lgcc -Wl,--end-group  --specs=nano.specs -o <TARGET>")

set(CMAKE_CXX_FLAGS_DEBUG_INIT          "-g -gdwarf-3")
set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT     "-Os -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE_INIT        "-Os -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT "-Os -g -gdwarf-3 -DNDEBUG")
set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX "-isystem ")

if (CMAKE_C_COMPILER_VERSION VERSION_GREATER "7.1.0" OR CMAKE_C_COMPILER_VERSION VERSION_EQUAL "7.1.0")
    message("${BoldRed}Supressing -Wexpansion-to-defined.${ColourReset}")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-expansion-to-defined")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-expansion-to-defined")
endif ()