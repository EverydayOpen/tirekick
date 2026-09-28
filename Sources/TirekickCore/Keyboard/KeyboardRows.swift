extension KeyboardLayout {
    /// Apple laptop keyboard rows, top to bottom, with kVK_* codes (Carbon HIToolbox/Events.h).
    /// `touchBar` drops F1–F12 but keeps Esc: it is a real key on later Touch Bar models and the Touch Bar's
    /// Esc sends the same key code. Excludes the power/Touch ID key (it sends no key event).
    /// Globe/fn, Caps Lock and the modifiers arrive as flagsChanged (VERIFY Globe in a local monitor).
    public func rows(touchBar: Bool) -> [[Key]] {
        let fKeys: [(UInt16, String)] = [(0x7A, "F1"), (0x78, "F2"), (0x63, "F3"), (0x76, "F4"), (0x60, "F5"), (0x61, "F6"),
                                         (0x62, "F7"), (0x64, "F8"), (0x65, "F9"), (0x6D, "F10"), (0x67, "F11"), (0x6F, "F12")]
        let function = [Key(0x35, "esc", width: 1.5)] + (touchBar ? [] : fKeys.map { Key($0.0, $0.1) })
        let digits = [Key(0x12, "1"), Key(0x13, "2"), Key(0x14, "3"), Key(0x15, "4"), Key(0x17, "5"), Key(0x16, "6"),
                      Key(0x1A, "7"), Key(0x1C, "8"), Key(0x19, "9"), Key(0x1D, "0"), Key(0x1B, "-"), Key(0x18, "="),
                      Key(0x33, "delete", width: 1.5)]
        let top = [Key(0x0C, "Q"), Key(0x0D, "W"), Key(0x0E, "E"), Key(0x0F, "R"), Key(0x11, "T"), Key(0x10, "Y"),
                   Key(0x20, "U"), Key(0x22, "I"), Key(0x1F, "O"), Key(0x23, "P"), Key(0x21, "["), Key(0x1E, "]")]
        let home = [Key(0x00, "A"), Key(0x01, "S"), Key(0x02, "D"), Key(0x03, "F"), Key(0x05, "G"), Key(0x04, "H"),
                    Key(0x26, "J"), Key(0x28, "K"), Key(0x25, "L"), Key(0x29, ";"), Key(0x27, "'")]
        let bottom = [Key(0x06, "Z"), Key(0x07, "X"), Key(0x08, "C"), Key(0x09, "V"), Key(0x0B, "B"), Key(0x2D, "N"),
                      Key(0x2E, "M"), Key(0x2B, ","), Key(0x2F, "."), Key(0x2C, "/")]
        let modifiers = [Key(0x3F, "fn"), Key(0x3B, "control"), Key(0x3A, "option"), Key(0x37, "command", width: 1.25),
                         Key(0x31, "space", width: 4), Key(0x36, "command", width: 1.25), Key(0x3D, "option"),
                         Key(0x7B, "←"), Key(0x7E, "↑"), Key(0x7D, "↓"), Key(0x7C, "→")]
        let tab = Key(0x30, "tab", width: 1.5), caps = Key(0x39, "caps lock", width: 1.75), rightShift = Key(0x3C, "shift", width: 2.25)
        switch self {
        case .ansi:
            return [
                function,
                [Key(0x32, "`")] + digits,
                [tab] + top + [Key(0x2A, "\\")],
                [caps] + home + [Key(0x24, "return", width: 1.75)],
                [Key(0x38, "shift", width: 2.25)] + bottom + [rightShift],
                modifiers,
            ]
        case .iso:
            // ISO: § top left, ` beside a short left Shift, \ beside a tall Return.
            return [
                function,
                [Key(0x0A, "§")] + digits,
                [tab] + top + [Key(0x24, "return")],
                [caps] + home + [Key(0x2A, "\\")],
                [Key(0x38, "shift", width: 1.25), Key(0x32, "`")] + bottom + [rightShift],
                modifiers,
            ]
        }
    }
}
