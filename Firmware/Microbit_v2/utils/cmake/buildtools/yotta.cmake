if("${INCLUDE_DIRS}" STRGREATER "")
    target_include_directories(codal PUBLIC "${INCLUDE_DIRS}")
endif()

add_library(codal "${SOURCE_FILES}")
set_target_properties(codal PROPERTIES SUFFIX "" ENABLE_EXPORTS ON)

target_compile_definitions(codal PUBLIC "${device.definitions}")
target_include_directories(codal PUBLIC ${PLATFORM_INCLUDES_PATH})
target_compile_options(codal PUBLIC -include ${EXTRA_INCLUDES_PATH})

set(STRIPPED "")
string(STRIP "${CMAKE_LINKER_FLAGS}" STRIPPED)
# link the executable with supporting libraries.
target_link_libraries(codal "${CODAL_DEPS};${STRIPPED}")

#
# Supress the addition of implicit linker flags (such as -rdynamic)
#
set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS "")
set(CMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS "")
set(CMAKE_EXE_EXPORTS_C_FLAG "")
set(CMAKE_EXE_EXPORTS_CXX_FLAG "")