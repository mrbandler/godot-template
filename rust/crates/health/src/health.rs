//! Engine-free health logic, unit tested with `cargo test`.

/// Hit points clamped to `0..=max`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Health {
    max: i32,
    current: i32,
}

impl Health {
    #[must_use]
    pub const fn new(max: i32) -> Self {
        Self { max, current: max }
    }

    pub fn damage(&mut self, amount: i32) {
        self.current = (self.current - amount.max(0)).clamp(0, self.max);
    }

    pub fn heal(&mut self, amount: i32) {
        self.current = (self.current + amount.max(0)).clamp(0, self.max);
    }

    #[must_use]
    pub const fn current(&self) -> i32 {
        self.current
    }

    #[must_use]
    pub const fn is_dead(&self) -> bool {
        self.current == 0
    }
}

#[cfg(test)]
mod tests {
    use super::Health;

    #[test]
    fn starts_full() {
        assert_eq!(Health::new(100).current(), 100);
    }

    #[test]
    fn damage_reduces_and_clamps_at_zero() {
        let mut health = Health::new(100);
        health.damage(30);
        assert_eq!(health.current(), 70);
        health.damage(500);
        assert_eq!(health.current(), 0);
        assert!(health.is_dead());
    }

    #[test]
    fn heal_clamps_at_max() {
        let mut health = Health::new(100);
        health.damage(50);
        health.heal(80);
        assert_eq!(health.current(), 100);
    }

    #[test]
    fn negative_amounts_are_ignored() {
        let mut health = Health::new(100);
        health.damage(-10);
        health.heal(-10);
        assert_eq!(health.current(), 100);
    }
}
