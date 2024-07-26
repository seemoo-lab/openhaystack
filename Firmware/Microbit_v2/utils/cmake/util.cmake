MACRO(RECURSIVE_FIND_DIR return_list dir pattern)
    FILE(GLOB_RECURSE new_list "${dir}/${pattern}")
    SET(dir_list "")
    FOREACH(file_path ${new_list})
        GET_FILENAME_COMPONENT(dir_path ${file_path} PATH)
        SET(dir_list ${dir_list} ${dir_path})
    ENDFOREACH()
    LIST(REMOVE_DUPLICATES dir_list)
    SET(${return_list} ${dir_list})
ENDMACRO()

MACRO(RECURSIVE_FIND_FILE return_list dir pattern)
    FILE(GLOB_RECURSE new_list "${dir}/${pattern}")
    SET(dir_list "")
    FOREACH(file_path ${new_list})
        SET(dir_list ${dir_list} ${file_path})
    ENDFOREACH()
    LIST(REMOVE_DUPLICATES dir_list)
    SET(${return_list} ${dir_list})
ENDMACRO()

MACRO(SOURCE_FILES return_list dir pattern)
    FILE(GLOB new_list "${dir}/${pattern}")
    SET(dir_list "")
    FOREACH(file_path ${new_list})
        LIST(APPEND dir_list ${file_path})
    ENDFOREACH()
    LIST(REMOVE_DUPLICATES dir_list)
    SET(${return_list} ${dir_list})
ENDMACRO()

function(EXTRACT_JSON_ARRAY json_file json_field_path fields values)

    set(VALUES "")
    set(FIELDS "")

    foreach(var ${${json_file}})
        # extract any cmd line definitions specified in the json object, and add them
        # if it is not prefixed by json_field_path, do not consider the key.
        if("${var}" MATCHES "${json_field_path}")
            string(REGEX MATCH "[^${json_field_path}]([A-Z,a-z,0-9,_,]+)" VALUE "${var}")

            # never quote the value - gives more flexibility
            list(APPEND FIELDS ${VALUE})
            list(APPEND VALUES "${${var}}")
        endif()
    endforeach()

    set(${fields} ${FIELDS} PARENT_SCOPE)
    set(${values} ${VALUES} PARENT_SCOPE)
endfunction()

function(FORM_DEFINITIONS fields values definitions)

    set(DEFINITIONS "")
    list(LENGTH ${fields} LEN)

    # - 1 for for loop index...
    MATH(EXPR LEN "${LEN}-1")

    foreach(i RANGE ${LEN})
        list(GET ${fields} ${i} DEFINITION)
        list(GET ${values} ${i} VALUE)

        set(DEFINITIONS "${DEFINITIONS} #define ${DEFINITION}\t ${VALUE}\n")
    endforeach()

    set(${definitions} ${DEFINITIONS} PARENT_SCOPE)
endfunction()

function(UNIQUE_JSON_KEYS priority_fields priority_values secondary_fields secondary_values merged_fields merged_values)

    # always keep the first fields and values
    set(MERGED_FIELDS ${${priority_fields}})
    set(MERGED_VALUES ${${priority_values}})

    # measure the second set...
    list(LENGTH ${secondary_fields} LEN)
    # - 1 for for loop index...
    MATH(EXPR LEN "${LEN}-1")

    # iterate, dropping any duplicate fields regardless of the value
    foreach(i RANGE ${LEN})
        list(GET ${secondary_fields} ${i} FIELD)
        list(GET ${secondary_values} ${i} VALUE)

        list(FIND MERGED_FIELDS ${FIELD} INDEX)

        if (${INDEX} GREATER -1)
            continue()
        endif()

        list(APPEND MERGED_FIELDS ${FIELD})
        list(APPEND MERGED_VALUES ${VALUE})
    endforeach()

    set(${merged_fields} ${MERGED_FIELDS} PARENT_SCOPE)
    set(${merged_values} ${MERGED_VALUES} PARENT_SCOPE)
endfunction()

MACRO(HEADER_FILES return_list dir)
    FILE(GLOB new_list "${dir}/*.h")
    SET(${return_list} ${new_list})
ENDMACRO()

function(INSTALL_DEPENDENCY dir name url branch type)
    if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/${dir}")
        message("Creating libraries folder")
        FILE(MAKE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/${dir}")
    endif()

    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${dir}/${name}")
        message("${name} is already installed")
        return()
    endif()

    if(${type} STREQUAL "git")
        message("Cloning into: ${url}")
	    # git clone -b doesn't work with SHAs
        execute_process(
            COMMAND git clone --recurse-submodules ${url} ${name}
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${dir}
        )

        if(NOT "${branch}" STREQUAL "")
            message("Checking out branch: ${branch}")
            execute_process(
                COMMAND git -c advice.detachedHead=false checkout ${branch}
                WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${dir}/${name}
            )
            execute_process(
                COMMAND git submodule update --init
                WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${dir}/${name}
            )
            execute_process(
                COMMAND git submodule sync
                WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${dir}/${name}
            )
            execute_process(
                COMMAND git submodule update
                WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${dir}/${name}
            )
        endif()
    else()
        message("No mechanism exists to install this library.")
    endif()
endfunction()

MACRO(SUB_DIRS return_dirs dir)
    FILE(GLOB list "${PROJECT_SOURCE_DIR}/${dir}/*")
    SET(dir_list "")
    FOREACH(file_path ${list})
        SET(dir_list ${dir_list} ${file_path})
    ENDFOREACH()
    set(${return_dirs} ${dir_list})
ENDMACRO()
