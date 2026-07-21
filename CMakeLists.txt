#cmake_minimum_required(VERSION 3.31)
#project(min_forth C)

#set(CMAKE_C_STANDARD 11)

# add_executable(min_forth main.c)

#################################


cmake_minimum_required(VERSION 3.25)
project(maxiForth C)  # <- "C" required to set a linker language

set(SRC_FILE ${CMAKE_SOURCE_DIR}/maxiForth.asm)
set(OBJ_FILE ${CMAKE_BINARY_DIR}/maxiForth.obj)

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

# Copy init.forth next to the exe.
add_custom_command(
        TARGET maxiForth POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_SOURCE_DIR}/init.forth
        $<TARGET_FILE_DIR:maxiForth>
        COMMENT "Copying init.forth next to executable"
)

# needed for linking
target_link_libraries(maxiForth PRIVATE kernel32)
