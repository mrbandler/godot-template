#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

#include "stamina.hpp"

TEST_CASE("starts full") { CHECK(game::Stamina(100).current() == 100); }

TEST_CASE("spend reduces and clamps at zero") {
    game::Stamina stamina(100);
    stamina.spend(30);
    CHECK(stamina.current() == 70);
    stamina.spend(500);
    CHECK(stamina.current() == 0);
    CHECK(stamina.is_exhausted());
}

TEST_CASE("recover clamps at max") {
    game::Stamina stamina(100);
    stamina.spend(50);
    stamina.recover(80);
    CHECK(stamina.current() == 100);
}

TEST_CASE("negative amounts are ignored") {
    game::Stamina stamina(100);
    stamina.spend(-10);
    stamina.recover(-10);
    CHECK(stamina.current() == 100);
}
