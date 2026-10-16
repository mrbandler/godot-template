cmake_minimum_required(VERSION 3.17)

# project() comes first so the vcpkg toolchain file is included once at top level.
project(game_cpp LANGUAGES CXX)

# godot-cpp is built once and shared by every extension. It must come before other
# dependencies (it sets the MSVC runtime).
add_subdirectory(godot-cpp SYSTEM)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(doctest CONFIG REQUIRED)
enable_testing()

# Every directory under extensions/ is one GDExtension.
file(GLOB extension_dirs LIST_DIRECTORIES true CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/extensions/*")
foreach(dir IN LISTS extension_dirs)
    if(IS_DIRECTORY "${dir}")
        add_subdirectory("${dir}")
    endif()
endforeach()
