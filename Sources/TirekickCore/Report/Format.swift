import Foundation

/// Units as Apple labels them, identical on every platform and locale.
public enum Format {
    /// Nearest marketing size: 994_662_584_320 (a 1 TB drive's APFS container) → "1 TB"; nil → "Unknown".
    public static func storage(_ bytes: Int64?) -> String {
        guard let bytes, bytes > 0 else { return "Unknown" }
        // No 500 GB: Apple's "512 GB" drives report about 500.3 GB.
        let sizes: [Int64] = [128, 256, 512, 1000, 2000, 3000, 4000, 8000, 16000]
        func distance(_ gb: Int64) -> Double {
            let ratio = Double(bytes) / Double(gb * 1_000_000_000)
            return max(ratio, 1 / ratio)
        }
        let best = sizes.min { distance($0) < distance($1) }!
        return best >= 1000 ? "\(best / 1000) TB" : "\(best) GB"
    }

    /// Binary GB as Apple labels RAM: 17179869184 → "16 GB"; 1.5 TiB → "1.5 TB"; nil → "Unknown".
    public static func memory(_ bytes: Int64?) -> String {
        guard let bytes, bytes > 0 else { return "Unknown" }
        let gb = Int((Double(bytes) / 1_073_741_824).rounded())
        guard gb >= 1024 else { return "\(gb) GB" }
        let tenths = Int((Double(gb) / 102.4).rounded())
        return tenths % 10 == 0 ? "\(tenths / 10) TB" : "\(tenths / 10).\(tenths % 10) TB"
    }

    /// "12 Nov 2026" in the user's time zone.
    public static func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    /// "1,000".
    static func count(_ n: Int) -> String {
        n < 1000 ? "\(n)" : count(n / 1000) + "," + "00\(n % 1000)".suffix(3)
    }
}

/// Redaction for the share card, the report and "Copy raw data": no serial (last 4 only), no user or host name.
public enum Redact {
    /// "····G5J7" (last 4); nil → "Unknown".
    public static func serial(_ serial: String?) -> String {
        guard let serial, !serial.isEmpty else { return "Unknown" }
        return "····" + serial.suffix(4)
    }

    /// Masks the serial wherever it appears plus the value of every key containing "serial", "UUID" or "UDID"
    /// (serial_number, platform_UUID, provisioning_UDID, device_serial, ioreg "Serial") in JSON, ioreg text and
    /// plist forms, and removes user and host names from pasted Terminal prompts and the account name fdesetup prints.
    public static func evidence(_ text: String, serial: String?) -> String {
        var out = prompts(text)
        if let serial, serial.count >= 8 { out = out.replacingOccurrences(of: serial, with: self.serial(serial)) }
        let patterns = [
            #""[^"]*(?:serial|uuid|udid)[^"]*"\s*[:=]\s*"([^"]+)""#,
            #"<key>[^<]*(?:serial|uuid|udid)[^<]*</key>\s*<string>([^<]+)</string>"#,
        ]
        for pattern in patterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            for match in regex.matches(in: out, range: NSRange(out.startIndex..., in: out)).reversed() {
                guard let range = Range(match.range(at: 1), in: out) else { continue }
                out.replaceSubrange(range, with: self.serial(String(out[range])))
            }
        }
        // fdesetup names the account while deferred enablement is pending: "… active for user 'jane'."
        return out.replacingOccurrences(of: #"for user '[^']*'"#, with: "for user '…'", options: .regularExpression)
    }

    /// Terminal prompts and sudo refusals name the user and the Mac. The prompt becomes "%", the command stays:
    /// zsh "jane@Janes-MacBook ~ % …", bash "Janes-MacBook:~ jane$ …", either after a "(base) " env prefix, or any
    /// prompt before `profiles`. Indented lines are output, never a prompt (`OrganizationEmail = "it@acme.com";`).
    static func prompts(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
            if line.contains("sudoers") || line.contains("may not run sudo") { return "(sudo refused: this account isn't an administrator)" }
            if let sudo = line.range(of: "sudo ") { return "% " + line[sudo.lowerBound...] }
            // A prompt and the command fit in 256 characters; the bound stops a long pasted line from backtracking.
            if let prompt = line.prefix(256).range(of: #"^(\(\S+\) )?([^\s@]+@\S.*?[%$#]|[^\s:@]+:.*? \S+[$#])( |$)"#, options: .regularExpression) {
                return "% " + line[prompt.upperBound...]
            }
            // fish ("jane@Janes-MacBook ~>") and Powerlevel10k ("❯") prompts end in neither % nor $: cut at the command.
            if line.first?.isWhitespace == false, let cmd = line.range(of: #"(/usr/bin/)?profiles "#, options: .regularExpression) {
                return "% " + line[cmd.lowerBound...]
            }
            return String(line)
        }.joined(separator: "\n")
    }
}
