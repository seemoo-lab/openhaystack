# The MIT License (MIT)

# Copyright (c) 2015 Stefan Bellus

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

cmake_minimum_required(VERSION 3.1)

if (DEFINED JSonParserGuard)
    return()
endif()

set(JSonParserGuard yes)

macro(sbeParseJson prefix jsonString)
    cmake_policy(PUSH)

    set(json_string "${${jsonString}}")
    string(LENGTH "${json_string}" json_jsonLen)
    set(json_index 0)
    set(json_AllVariables ${prefix})
    set(json_ArrayNestingLevel 0)
    set(json_MaxArrayNestingLevel 0)

    _sbeParse(${prefix})

    unset(json_index)
    unset(json_AllVariables)
    unset(json_jsonLen)
    unset(json_string)
    unset(json_value)
    unset(json_inValue)
    unset(json_name)
    unset(json_inName)
    unset(json_newPrefix)
    unset(json_reservedWord)
    unset(json_arrayIndex)
    unset(json_char)
    unset(json_end)
    unset(json_ArrayNestingLevel)
    foreach(json_nestingLevel RANGE ${json_MaxArrayNestingLevel})
        unset(json_${json_nestingLevel}_arrayIndex)
    endforeach()
    unset(json_nestingLevel)
    unset(json_MaxArrayNestingLevel)

    cmake_policy(POP)
endmacro()

macro(sbeClearJson prefix)
    foreach(json_var ${${prefix}})
        unset(${json_var})
    endforeach()

    unset(${prefix})
    unset(json_var)
endmacro()

macro(sbePrintJson prefix)
    foreach(json_var ${${prefix}})
        message("${json_var} = ${${json_var}}")
    endforeach()
endmacro()

macro(_sbeParse prefix)

    while(${json_index} LESS ${json_jsonLen})
        string(SUBSTRING "${json_string}" ${json_index} 1 json_char)

        if("\"" STREQUAL "${json_char}")
            _sbeParseNameValue(${prefix})
        elseif("{" STREQUAL "${json_char}")
            _sbeMoveToNextNonEmptyCharacter()
            _sbeParseObject(${prefix})
        elseif("[" STREQUAL "${json_char}")
            _sbeMoveToNextNonEmptyCharacter()
            _sbeParseArray(${prefix})
        endif()

        if(${json_index} LESS ${json_jsonLen})
            string(SUBSTRING "${json_string}" ${json_index} 1 json_char)
        else()
            break()
        endif()

        if ("}" STREQUAL "${json_char}" OR "]" STREQUAL "${json_char}")
            break()
        endif()

        _sbeMoveToNextNonEmptyCharacter()
    endwhile()
endmacro()

macro(_sbeParseNameValue prefix)
    set(json_name "")
    set(json_inName no)

    while(${json_index} LESS ${json_jsonLen})
        string(SUBSTRING "${json_string}" ${json_index} 1 json_char)

        # check if name ends
        if("\"" STREQUAL "${json_char}" AND json_inName)
            set(json_inName no)
            _sbeMoveToNextNonEmptyCharacter()
            if(NOT ${json_index} LESS ${json_jsonLen})
                break()
            endif()
            string(SUBSTRING "${json_string}" ${json_index} 1 json_char)
            set(json_newPrefix ${prefix}.${json_name})
            set(json_name "")

            if(":" STREQUAL "${json_char}")
                _sbeMoveToNextNonEmptyCharacter()
                if(NOT ${json_index} LESS ${json_jsonLen})
                    break()
                endif()
                string(SUBSTRING "${json_string}" ${json_index} 1 json_char)

                if("\"" STREQUAL "${json_char}")
                    _sbeParseValue(${json_newPrefix})
                    break()
                elseif("{" STREQUAL "${json_char}")
                    _sbeMoveToNextNonEmptyCharacter()
                    _sbeParseObject(${json_newPrefix})
                    break()
                elseif("[" STREQUAL "${json_char}")
                    _sbeMoveToNextNonEmptyCharacter()
                    _sbeParseArray(${json_newPrefix})
                    break()
                else()
                    # reserved word starts
                    _sbeParseReservedWord(${json_newPrefix})
                    break()
                endif()
            else()
                # name without value
                list(APPEND ${json_AllVariables} ${json_newPrefix})
                set(${json_newPrefix} "")
                break()
            endif()
        endif()

        if(json_inName)
            # remove escapes
            if("\\" STREQUAL "${json_char}")
                math(EXPR json_index "${json_index} + 1")
                if(NOT ${json_index} LESS ${json_jsonLen})
                    break()
                endif()
                string(SUBSTRING "${json_string}" ${json_index} 1 json_char)
            endif()

            set(json_name "${json_name}${json_char}")
        endif()

        # check if name starts
        if("\"" STREQUAL "${json_char}" AND NOT json_inName)
            set(json_inName yes)
        endif()

        _sbeMoveToNextNonEmptyCharacter()
    endwhile()
endmacro()

macro(_sbeParseReservedWord prefix)
    set(json_reservedWord "")
    set(json_end no)
    while(${json_index} LESS ${json_jsonLen} AND NOT json_end)
        string(SUBSTRING "${json_string}" ${json_index} 1 json_char)

        if("," STREQUAL "${json_char}" OR "}" STREQUAL "${json_char}" OR "]" STREQUAL "${json_char}")
            set(json_end yes)
        else()
            set(json_reservedWord "${json_reservedWord}${json_char}")
            math(EXPR json_index "${json_index} + 1")
        endif()
    endwhile()

    list(APPEND ${json_AllVariables} ${prefix})
    string(STRIP  "${json_reservedWord}" json_reservedWord)
    set(${prefix} ${json_reservedWord})
endmacro()

macro(_sbeParseValue prefix)
    cmake_policy(SET CMP0054 NEW) # turn off implicit expansions in if statement

    set(json_value "")
    set(json_inValue no)

    while(${json_index} LESS ${json_jsonLen})
        string(SUBSTRING "${json_string}" ${json_index} 1 json_char)

        # check if json_value ends, it is ended by "
        if("\"" STREQUAL "${json_char}" AND json_inValue)
            set(json_inValue no)

            set(${prefix} ${json_value})
            list(APPEND ${json_AllVariables} ${prefix})
            _sbeMoveToNextNonEmptyCharacter()
            break()
        endif()

        if(json_inValue)
             # if " is escaped consume
            if("\\" STREQUAL "${json_char}")
                math(EXPR json_index "${json_index} + 1")
                if(NOT ${json_index} LESS ${json_jsonLen})
                    break()
                endif()
                string(SUBSTRING "${json_string}" ${json_index} 1 json_char)
                if(NOT "\"" STREQUAL "${json_char}")
                    # if it is not " then copy also escape character
                    set(json_char "\\${json_char}")
                endif()
            endif()

            _sbeAddEscapedCharacter("${json_char}")
        endif()

        # check if value starts
        if("\"" STREQUAL "${json_char}" AND NOT json_inValue)
            set(json_inValue yes)
        endif()

        math(EXPR json_index "${json_index} + 1")
    endwhile()
endmacro()

macro(_sbeAddEscapedCharacter char)
    string(CONCAT json_value "${json_value}" "${char}")
endmacro()

macro(_sbeParseObject prefix)
    _sbeParse(${prefix})
    _sbeMoveToNextNonEmptyCharacter()
endmacro()

macro(_sbeParseArray prefix)
    math(EXPR json_ArrayNestingLevel "${json_ArrayNestingLevel} + 1")
    set(json_${json_ArrayNestingLevel}_arrayIndex 0)

    set(${prefix} "")
    list(APPEND ${json_AllVariables} ${prefix})

    while(${json_index} LESS ${json_jsonLen})
        string(SUBSTRING "${json_string}" ${json_index} 1 json_char)

        if("\"" STREQUAL "${json_char}")
            # simple value
            list(APPEND ${prefix} ${json_${json_ArrayNestingLevel}_arrayIndex})
            _sbeParseValue(${prefix}_${json_${json_ArrayNestingLevel}_arrayIndex})
        elseif("{" STREQUAL "${json_char}")
            # object
            _sbeMoveToNextNonEmptyCharacter()
            list(APPEND ${prefix} ${json_${json_ArrayNestingLevel}_arrayIndex})
            _sbeParseObject(${prefix}_${json_${json_ArrayNestingLevel}_arrayIndex})
        else()
            list(APPEND ${prefix} ${json_${json_ArrayNestingLevel}_arrayIndex})
            _sbeParseReservedWord(${prefix}_${json_${json_ArrayNestingLevel}_arrayIndex})
        endif()

        if(NOT ${json_index} LESS ${json_jsonLen})
            break()
        endif()

        string(SUBSTRING "${json_string}" ${json_index} 1 json_char)

        if("]" STREQUAL "${json_char}")
            _sbeMoveToNextNonEmptyCharacter()
            break()
        elseif("," STREQUAL "${json_char}")
            math(EXPR json_${json_ArrayNestingLevel}_arrayIndex "${json_${json_ArrayNestingLevel}_arrayIndex} + 1")
        endif()

        _sbeMoveToNextNonEmptyCharacter()
    endwhile()

    if(${json_MaxArrayNestingLevel} LESS ${json_ArrayNestingLevel})
        set(json_MaxArrayNestingLevel ${json_ArrayNestingLevel})
    endif()
    math(EXPR json_ArrayNestingLevel "${json_ArrayNestingLevel} - 1")
endmacro()

macro(_sbeMoveToNextNonEmptyCharacter)
    math(EXPR json_index "${json_index} + 1")
    if(${json_index} LESS ${json_jsonLen})
        string(SUBSTRING "${json_string}" ${json_index} 1 json_char)
        while(${json_char} MATCHES "[ \t\n\r]" AND ${json_index} LESS ${json_jsonLen})
            math(EXPR json_index "${json_index} + 1")
            string(SUBSTRING "${json_string}" ${json_index} 1 json_char)
        endwhile()
    endif()
endmacro()
