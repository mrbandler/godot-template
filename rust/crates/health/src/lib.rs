//! `health` `GDExtension`: engine-free logic in plain modules, thin Godot classes on top.

// gdext's entry point is an `unsafe impl`; the workspace denies `unsafe_code` everywhere else.
#![allow(unsafe_code)]

pub mod health;
mod rust_health;

use godot::prelude::*;

struct HealthExtension;

#[gdextension(entry_symbol = health_init)]
unsafe impl ExtensionLibrary for HealthExtension {}
