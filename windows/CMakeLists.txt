cmake_minimum_required(VERSION 3.20)
project(windows NONE)          # NONE: no C/C++ compiler detection

find_program(NASM_EXECUTABLE nasm REQUIRED)

set(WINSRC_SRC ${CMAKE_CURRENT_SOURCE_DIR}/winstubs.asm)
set(WINSRC_BIN ${CMAKE_CURRENT_BINARY_DIR}/winstubs.bin)

add_custom_command(
        OUTPUT  ${WINSRC_BIN}
        COMMAND ${NASM_EXECUTABLE} -f bin -o ${WINSRC_BIN} ${WINSRC_SRC}
        DEPENDS ${WINSRC_SRC}
        COMMENT "Assembling winstubs.asm to flat binary"
        VERBATIM)

add_custom_target(winsrc ALL DEPENDS ${WINSRC_BIN})