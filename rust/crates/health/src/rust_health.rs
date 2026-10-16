use godot::prelude::*;

use crate::health::Health;

/// Godot-facing wrapper around [`Health`].
#[derive(GodotClass)]
#[class(base = RefCounted)]
pub struct RustHealth {
    inner: Health,
}

#[godot_api]
impl IRefCounted for RustHealth {
    fn init(_base: Base<RefCounted>) -> Self {
        Self {
            inner: Health::new(100),
        }
    }
}

// #[func] forbids `const fn`, so the const suggestion does not apply.
#[allow(clippy::missing_const_for_fn)]
#[godot_api]
impl RustHealth {
    #[func]
    fn setup(&mut self, max: i32) {
        self.inner = Health::new(max);
    }

    #[func]
    fn damage(&mut self, amount: i32) {
        self.inner.damage(amount);
    }

    #[func]
    fn heal(&mut self, amount: i32) {
        self.inner.heal(amount);
    }

    #[func]
    fn current(&self) -> i32 {
        self.inner.current()
    }

    #[func]
    fn is_dead(&self) -> bool {
        self.inner.is_dead()
    }
}
