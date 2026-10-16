#include "cpp_stamina.hpp"

using godot::ClassDB;
using godot::D_METHOD;

void CppStamina::_bind_methods() {
    ClassDB::bind_method(D_METHOD("setup", "max"), &CppStamina::setup);
    ClassDB::bind_method(D_METHOD("spend", "amount"), &CppStamina::spend);
    ClassDB::bind_method(D_METHOD("recover", "amount"), &CppStamina::recover);
    ClassDB::bind_method(D_METHOD("current"), &CppStamina::current);
    ClassDB::bind_method(D_METHOD("is_exhausted"), &CppStamina::is_exhausted);
}
