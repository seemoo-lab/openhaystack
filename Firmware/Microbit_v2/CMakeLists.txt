# The MIT License (MIT)

# Copyright (c) 2017 Lancaster University.

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
cmake_minimum_required(VERSION 3.3)

# include additional cmake
include(utils/cmake/JSONParser.cmake)
include(utils/cmake/util.cmake)
include(utils/cmake/colours.cmake)

if (NOT "${BUILD_TOOL}" STRGREATER "")
    set(BUILD_TOOL "CODAL")
endif()

#
# Supress unecessary (and often inaccurate) validity check of the toolchain
#
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)


#read our config file...
file(READ "./codal.json" codal_json)
sbeParseJson(codal codal_json)

set(CODAL_APP_OUTPUT_DIR ".")
set(CODAL_APP_SOURCE_DIR "source")

if("${codal.application}" STRGREATER "")
    set(CODAL_APP_SOURCE_DIR "${codal.application}")
endif()

if("${codal.output_folder}" STRGREATER "")
    set(CODAL_APP_OUTPUT_DIR "${codal.output_folder}")
endif()

if(NOT "${codal.target.name}" STRGREATER "")
    message(FATAL_ERROR "${BoldRed}INVALID TARGET.${ColourReset}")
endif()

set(CODAL_DEPS "")
set(LIB_DEST "libraries")

#install the target
INSTALL_DEPENDENCY(${LIB_DEST} ${codal.target.name} ${codal.target.url} ${codal.target.branch} ${codal.target.type})
message("${BoldMagenta}Set target: ${codal.target.name} ${ColourReset}")
list(APPEND CODAL_DEPS ${codal.target.name})

if("${codal.target.dev}" STRGREATER "")
    file(READ "./${LIB_DEST}/${codal.target.name}/target.json" device_json)
    message("${BoldMagenta}Using target.json (dev version) ${ColourReset}")
else()
    file(READ "./${LIB_DEST}/${codal.target.name}/target-locked.json" device_json)
    message("${BoldMagenta}Using target-locked.json${ColourReset}")
endif()

message("${BoldBlue}Targeting ${codal.target.name}${ColourReset}")

sbeParseJson(device device_json)

SET(CODAL_TARGET_NAME ${device.target.name})
SET(CODAL_OUTPUT_NAME ${device.device})
SET(CODAL_TARGET_PROCESSOR ${device.processor})
SET(CODAL_TARGET_CPU_ARCHITECTURE ${device.architecture})

# if this is the first build, lets copy a sample main.cpp from the target if available.
if(NOT EXISTS ${CMAKE_CURRENT_LIST_DIR}/${CODAL_APP_SOURCE_DIR} AND EXISTS ${CMAKE_CURRENT_LIST_DIR}/${LIB_DEST}/${codal.target.name}/samples/main.cpp)
    FILE(COPY ${CMAKE_CURRENT_LIST_DIR}/${LIB_DEST}/${codal.target.name}/samples/main.cpp DESTINATION ${CMAKE_CURRENT_LIST_DIR}/${CODAL_APP_SOURCE_DIR})
endif()

#copy samples and remove main.cpp
if(NOT EXISTS ${CMAKE_CURRENT_LIST_DIR}/samples AND EXISTS ${CMAKE_CURRENT_LIST_DIR}/${LIB_DEST}/${codal.target.name}/samples/)
    FILE(COPY ${CMAKE_CURRENT_LIST_DIR}/${LIB_DEST}/${codal.target.name}/samples DESTINATION ${CMAKE_CURRENT_LIST_DIR})
    FILE(REMOVE ${CMAKE_CURRENT_LIST_DIR}/samples/main.cpp)
endif()

####################

SET(TOOLCHAIN ${device.toolchain})
SET(TOOLCHAIN_FOLDER "./utils/cmake/toolchains/${device.toolchain}")

# include toolchain file
set(CMAKE_TOOLCHAIN_FILE "${TOOLCHAIN_FOLDER}/toolchain.cmake" CACHE PATH "toolchain file")

# required to force TOOLCHAIN settings...
project(codal)
enable_language(ASM)

# include compiler flags overrides
include(${TOOLCHAIN_FOLDER}/compiler-flags.cmake)
set(PLATFORM_INCLUDES_PATH "${PROJECT_SOURCE_DIR}/utils/cmake/toolchains/${device.toolchain}")

file(MAKE_DIRECTORY "${PROJECT_SOURCE_DIR}/build")

# configure output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY  "${PROJECT_SOURCE_DIR}/build")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/build")

SET(CODAL_DEFINITIONS "")

EXTRACT_JSON_ARRAY(codal "codal\.config\." CODAL_FIELDS CODAL_VALUES)
EXTRACT_JSON_ARRAY(device "device\.config\." DEVICE_FIELDS DEVICE_VALUES)
UNIQUE_JSON_KEYS(CODAL_FIELDS CODAL_VALUES DEVICE_FIELDS DEVICE_VALUES FINAL_FIELDS FINAL_VALUES)
FORM_DEFINITIONS(FINAL_FIELDS FINAL_VALUES CODAL_DEFINITIONS)

# extract any CMAKE definitions specified in the target.json object, and set as native cmake vars
# cmake definitions require special handling as types are not safe in cmake, any semi-colon would need escaped, which would be ugly.
foreach(var ${device})
    #if it is not prefixed by codal.cmake_definitions, do not consider the key.		 +
    if(NOT "${var}" MATCHES "device\.cmake_definitions\.")
        continue()
    endif()

    string(REGEX MATCH "[^device\.cmake_definitions\.]([A-Z,a-z,0-9,_,]+)" CODAL_CMAKE_DEFINITION "${var}")

    set(${CODAL_CMAKE_DEFINITION} ${${var}})
 endforeach()

#define any additional symbols specified by the target.
if("${device.definitions}" STRGREATER "")
    add_definitions("${device.definitions}")
endif()

####################
# optional JSON flags for compilation + assembly
###################
if("${device.cpu_opts}" STRGREATER "")
    set(_CPU_COMPILATION_OPTIONS "${device.cpu_opts}")
    set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${device.cpu_opts}")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${device.cpu_opts}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${device.cpu_opts}")
    set(CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS} ${device.cpu_opts}")
endif()

set(_C_FAMILY_FLAGS_INIT "-fno-exceptions -fno-unwind-tables -ffunction-sections -fdata-sections -Wall -Wextra -Wno-unused-parameter")

# asm
if("${device.asm_flags}" STRGREATER "")
    set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${device.asm_flags}")
endif()

# c
if("${device.c_flags}" STRGREATER "")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${_C_FAMILY_FLAGS_INIT} ${device.c_flags}")
    set(CMAKE_C_LINK_FLAGS "${CMAKE_C_LINK_FLAGS} ${device.c_flags}")
endif()

# cpp
if("${device.cpp_flags}" STRGREATER "")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_C_FAMILY_FLAGS_INIT} ${device.cpp_flags}")
    set(CMAKE_CXX_LINK_FLAGS "${device.cpp_flags}")
endif()

# linker opts
if("${device.linker_flags}" STRGREATER "")
    set(CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS} ${device.linker_flags}")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${device.linker_flags}")
endif()

# create a header file from the definitions specified in JSON
if("${CODAL_DEFINITIONS}" STRGREATER "")
    set(EXTRA_INCLUDES_NEW_PATH "${PROJECT_SOURCE_DIR}/build/codal_extra_definitions_new.h")
    set(EXTRA_INCLUDES_PATH "${PROJECT_SOURCE_DIR}/build/codal_extra_definitions.h")
    file(WRITE "${EXTRA_INCLUDES_NEW_PATH}" ${CODAL_DEFINITIONS})
    configure_file(${EXTRA_INCLUDES_NEW_PATH} ${EXTRA_INCLUDES_PATH} COPYONLY)

    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -include ${EXTRA_INCLUDES_PATH}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -include ${EXTRA_INCLUDES_PATH}")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -I${PLATFORM_INCLUDES_PATH}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I${PLATFORM_INCLUDES_PATH}")

# a define for cmake if statements to detect if within the CODAL build environment
set(CODAL_BUILD_SYSTEM TRUE)

# a define specificying common utils used in codal
set(CODAL_UTILS_LOCATION "${PROJECT_SOURCE_DIR}/utils/cmake/util.cmake")

# this variable is used in the linking step of the final binary.
set(LIB_FOLDERS "")

# Add the root of the libraries folder as a search path. Useful for disambiguating header files with duplicated names.
MESSAGE (STATUS "Adding library path: (${PROJECT_SOURCE_DIR}/${LIB_DEST})")
include_directories(${PROJECT_SOURCE_DIR}/${LIB_DEST})

#add_subdirectory("${PROJECT_SOURCE_DIR}/${LIB_DEST}/${dep}")

# "import" and add any specified libraries to the build list
if("${device.libraries}" STRGREATER "")
    message("Installing dependencies...")
    set(DEVICE_LIBS ${device.libraries})

    foreach(i ${DEVICE_LIBS})
        SET(BRANCH "NONE")
        SET(URL "${device.libraries_${i}.url}")
        if("${device.libraries_${i}.branch}" STRGREATER "")
            SET(BRANCH "${device.libraries_${i}.branch}")
        endif()
        if("${codal.target.branches.${URL}}" STRGREATER "")
            SET(BRANCH "${codal.target.branches.${URL}}")
            MESSAGE (STATUS "Override branch: ${BRANCH}")
        endif()

        INSTALL_DEPENDENCY(${LIB_DEST} ${device.libraries_${i}.name} ${URL} ${BRANCH} ${device.libraries_${i}.type})
        list(APPEND CODAL_DEPS "${device.libraries_${i}.name}")
    endforeach()

    foreach(dep ${CODAL_DEPS})
        message("${BoldGreen}Using library: ${dep}${ColourReset}")
        add_subdirectory("${PROJECT_SOURCE_DIR}/${LIB_DEST}/${dep}")
    endforeach()
endif()

#finally, find sources and includes of the application, and create a target.
RECURSIVE_FIND_DIR(INCLUDE_DIRS "${PROJECT_SOURCE_DIR}/${CODAL_APP_SOURCE_DIR}" "*.h")
# *.c?? only catches .cpp, not .c, so let's be precise
RECURSIVE_FIND_FILE(SOURCE_FILES "${PROJECT_SOURCE_DIR}/${CODAL_APP_SOURCE_DIR}" "*.cpp")

RECURSIVE_FIND_FILE(S_FILES "${PROJECT_SOURCE_DIR}/${CODAL_APP_SOURCE_DIR}" "*.s")
RECURSIVE_FIND_FILE(C_FILES "${PROJECT_SOURCE_DIR}/${CODAL_APP_SOURCE_DIR}" "*.c")
list(APPEND SOURCE_FILES ${S_FILES})
list(APPEND SOURCE_FILES ${C_FILES})

if("${SOURCE_FILES}" STREQUAL "")
    message(FATAL_ERROR "${BoldRed}No user application to build, please add a main.cpp at: ${PROJECT_SOURCE_DIR}/${CODAL_APP_SOURCE_DIR}${ColourReset}")
endif()

if ("${BUILD_TOOL}" STRGREATER "")
    string(COMPARE EQUAL "${BUILD_TOOL}" "YOTTA" YOTTA_BUILD)
    if (${YOTTA_BUILD})
        include("${PROJECT_SOURCE_DIR}/utils/cmake/buildtools/yotta.cmake")
    endif ()

    string(COMPARE EQUAL "${BUILD_TOOL}" "CODAL" CODAL_BUILD)
    if (${CODAL_BUILD})
        include("${PROJECT_SOURCE_DIR}/utils/cmake/buildtools/codal.cmake")
    endif()
endif()

#
# Supress the addition of implicit linker flags (such as -rdynamic)
#
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
set(CMAKE_EXE_EXPORTS_C_FLAG "")
set(CMAKE_EXE_EXPORTS_CXX_FLAG "")
