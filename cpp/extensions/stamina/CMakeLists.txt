# Extension name = directory name.
get_filename_component(ext "${CMAKE_CURRENT_SOURCE_DIR}" NAME)

add_library(${ext} SHARED src/register_types.cpp src/cpp_stamina.cpp)
target_link_libraries(${ext} PRIVATE godot-cpp)

# Engine-free unit tests.
add_executable(${ext}_tests tests/stamina_test.cpp)
target_include_directories(${ext}_tests PRIVATE src)
target_link_libraries(${ext}_tests PRIVATE doctest::doctest)
add_test(NAME ${ext} COMMAND ${ext}_tests)
