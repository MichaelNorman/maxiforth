#cmake_minimum_required(VERSION 3.31)
#project(min_forth C)

#set(CMAKE_C_STANDARD 11)

# add_executable(maxiForth main.c)

#################################


cmake_minimum_required(VERSION 3.25)
project(maxiForth C)  # <- "C" required to set a linker language

set(SRC_FILE ${CMAKE_SOURCE_DIR}/maxiForth.asm)
set(OBJ_FILE ${CMAKE_BINARY_DIR}/maxiForth.obj)
set(MAXIFORTH_ROOT "" CACHE PATH "Root for .forth paths")

if (NOT MAXIFORTH_ROOT)
    message(FATAL_ERROR
        "MAXIFORTH_ROOT is not set. In CLion: Settings > Build, Execution, "
        "Deployment > CMake > (profile) > CMake options, add "
        "-DMAXIFORTH_ROOT=/path/to/your/maxiforth")
endif()
# Build the object file from NASM source
add_custom_command(
        OUTPUT ${OBJ_FILE}
        COMMAND nasm -I ${CMAKE_SOURCE_DIR} -f win64 ${SRC_FILE} -o ${OBJ_FILE}
        DEPENDS ${SRC_FILE}
        COMMENT "Assembling ${SRC_FILE}"
)

# Create a dummy C file to satisfy the linker and enable C as the linker language
file(WRITE ${CMAKE_BINARY_DIR}/dummy.c "\n")

# Add executable from object file
add_executable(maxiForth ${OBJ_FILE} ${CMAKE_BINARY_DIR}/dummy.c) # ${CMAKE_SOURCE_DIR}/shim.c)

# Copy *.forth files with @<variable>@ substitution.
configure_file(
        ${CMAKE_SOURCE_DIR}/init.forth
        ${CMAKE_BINARY_DIR}/init.forth
        @ONLY
)

configure_file(
        ${CMAKE_SOURCE_DIR}/custom/custom.forth
        ${CMAKE_BINARY_DIR}/custom/custom.forth
        @ONLY
)

configure_file(
        ${CMAKE_SOURCE_DIR}/custom/heap-strings.forth
        ${CMAKE_BINARY_DIR}/custom/heap-strings.forth
        @ONLY
)

configure_file(
        ${CMAKE_SOURCE_DIR}/explore/dll.forth
        ${CMAKE_BINARY_DIR}/explore/dll.forth
        @ONLY
)

# needed for linking
target_link_libraries(maxiForth PRIVATE kernel32)
