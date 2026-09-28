// Alone in its file: Carbon declares many old names that could clash with TirekickCore's types.
import Carbon

/// The physical layout of the keyboard macOS last saw, which at a meetup is the built-in one.
/// VERIFY on real ANSI and ISO Macs; the keyboard test's layout picker corrects a wrong guess.
func keyboardIsISO() -> Bool {
    KBGetLayoutType(Int16(LMGetKbdType())) == PhysicalKeyboardLayoutType(kKeyboardISO)
}
