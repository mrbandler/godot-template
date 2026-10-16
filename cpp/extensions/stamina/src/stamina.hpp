#pragma once

#include <algorithm>

namespace game {

// Stamina points clamped to 0..max. No Godot types: unit tested with doctest.
class Stamina {
  public:
    explicit Stamina(int max) : max_(max), current_(max) {}

    void spend(int amount) { current_ = std::clamp(current_ - std::max(amount, 0), 0, max_); }
    void recover(int amount) { current_ = std::clamp(current_ + std::max(amount, 0), 0, max_); }
    [[nodiscard]] int current() const { return current_; }
    [[nodiscard]] bool is_exhausted() const { return current_ == 0; }

  private:
    int max_;
    int current_;
};

} // namespace game
