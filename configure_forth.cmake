file(GLOB_RECURSE FORTH_FILES RELATIVE ${SRC}
        ${SRC}/init/*
        ${SRC}/explore/*
        ${SRC}/custom/*)

foreach(f IN LISTS FORTH_FILES)
    configure_file(${SRC}/${f} ${BIN}/${f} @ONLY)
endforeach()