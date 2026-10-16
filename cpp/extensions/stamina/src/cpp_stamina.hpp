#pragma once

#include <godot_cpp/classes/ref_counted.hpp>

#include "stamina.hpp"

// Godot-facing wrapper around game::Stamina.
class CppStamina : public godot::RefCounted {
    GDCLASS(CppStamina, godot::RefCounted)

  public:
    void setup(int max) { inner_ = game::Stamina(max); }
    void spend(int amount) { inner_.spend(amount); }
    void recover(int amount) { inner_.recover(amount); }
    [[nodiscard]] int current() const { return inner_.current(); }
    [[nodiscard]] bool is_exhausted() const { return inner_.is_exhausted(); }

  protected:
    static void _bind_methods();

  private:
    game::Stamina inner_{100};
};
