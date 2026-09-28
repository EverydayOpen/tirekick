/// Every Mac that can run macOS 13 or later, hand-built from Apple's pages (all checked 2026-09-28):
/// Identify your MacBook Pro https://support.apple.com/en-us/108052, MacBook Air /102869, MacBook /103257,
/// iMac /108054, Mac mini /102852, Mac Studio /102231, Mac Pro /102887 ("Newest compatible operating system");
/// compatibility lists for Ventura /102861, Sonoma /105113, Tahoe /122867, macOS 27 Golden Gate /127255.
/// Add a row per Apple launch. Names are Apple's; where one identifier covers two Identify-page entries the
/// name joins them ("2018 or 2019").
public enum ModelCatalog {
    public static let newestMacOS = 27
    /// Majors in release order (Apple jumped from 15 to 26). Update distances count positions here, not numbers.
    public static let macOSReleases = [13, 14, 15, 26, 27]

    public static func lookup(_ identifier: String) -> ModelInfo? {
        models.first { $0.identifier == identifier }
    }

    public static let models: [ModelInfo] = [
        // MacBook Pro
        m("MacBook Pro (14-inch, M5 Pro or M5 Max)", 2026, "Mac17,7", "Mac17,9"),
        m("MacBook Pro (16-inch, M5 Pro or M5 Max)", 2026, "Mac17,6", "Mac17,8"),
        m("MacBook Pro (14-inch, M5)", 2025, "Mac17,2"),
        m("MacBook Pro (14-inch, 2024)", 2024, "Mac16,1", "Mac16,6", "Mac16,8"),
        m("MacBook Pro (16-inch, 2024)", 2024, "Mac16,7", "Mac16,5"),
        m("MacBook Pro (14-inch, Nov 2023)", 2023, "Mac15,3", "Mac15,6", "Mac15,8", "Mac15,10"),
        m("MacBook Pro (16-inch, Nov 2023)", 2023, "Mac15,7", "Mac15,9", "Mac15,11"),
        m("MacBook Pro (14-inch, 2023)", 2023, "Mac14,5", "Mac14,9"),
        m("MacBook Pro (16-inch, 2023)", 2023, "Mac14,6", "Mac14,10"),
        m("MacBook Pro (13-inch, M2, 2022)", 2022, "Mac14,7", touchBar: true),
        m("MacBook Pro (14-inch, 2021)", 2021, "MacBookPro18,3", "MacBookPro18,4"),
        m("MacBook Pro (16-inch, 2021)", 2021, "MacBookPro18,1", "MacBookPro18,2"),
        m("MacBook Pro (13-inch, M1, 2020)", 2020, "MacBookPro17,1", touchBar: true),
        m("MacBook Pro (13-inch, 2020, Two Thunderbolt 3 ports)", 2020, "MacBookPro16,3", last: 15, touchBar: true),
        m("MacBook Pro (13-inch, 2020, Four Thunderbolt 3 ports)", 2020, "MacBookPro16,2", last: 26, touchBar: true),
        m("MacBook Pro (16-inch, 2019)", 2019, "MacBookPro16,1", "MacBookPro16,4", last: 26, touchBar: true),
        m("MacBook Pro (13-inch, 2019, Two Thunderbolt 3 ports)", 2019, "MacBookPro15,4", last: 15, touchBar: true),
        m("MacBook Pro (15-inch, 2019)", 2019, "MacBookPro15,3", last: 15, touchBar: true),
        m("MacBook Pro (15-inch, 2018 or 2019)", 2018, "MacBookPro15,1", last: 15, touchBar: true),
        m("MacBook Pro (13-inch, 2018 or 2019, Four Thunderbolt 3 ports)", 2018, "MacBookPro15,2", last: 15, touchBar: true),
        m("MacBook Pro (15-inch, 2017)", 2017, "MacBookPro14,3", last: 13, touchBar: true),
        m("MacBook Pro (13-inch, 2017, Four Thunderbolt 3 ports)", 2017, "MacBookPro14,2", last: 13, touchBar: true),
        m("MacBook Pro (13-inch, 2017, Two Thunderbolt 3 ports)", 2017, "MacBookPro14,1", last: 13),
        // MacBook Air
        m("MacBook Air (15-inch, M5)", 2026, "Mac17,4"),
        m("MacBook Air (13-inch, M5)", 2026, "Mac17,3"),
        m("MacBook Air (15-inch, M4, 2025)", 2025, "Mac16,13"),
        m("MacBook Air (13-inch, M4, 2025)", 2025, "Mac16,12"),
        m("MacBook Air (15-inch, M3, 2024)", 2024, "Mac15,13"),
        m("MacBook Air (13-inch, M3, 2024)", 2024, "Mac15,12"),
        m("MacBook Air (15-inch, M2, 2023)", 2023, "Mac14,15"),
        m("MacBook Air (M2, 2022)", 2022, "Mac14,2"),
        m("MacBook Air (M1, 2020)", 2020, "MacBookAir10,1"),
        m("MacBook Air (Retina, 13-inch, 2020)", 2020, "MacBookAir9,1", last: 15),
        m("MacBook Air (Retina, 13-inch, 2019)", 2019, "MacBookAir8,2", last: 14),
        m("MacBook Air (Retina, 13-inch, 2018)", 2018, "MacBookAir8,1", last: 14),
        // MacBook Neo: name from Apple's macOS 27 list; no Apple Identify page yet.
        // VERIFY identifier: Mac17,5 comes from Wikipedia, AppleDB and a retail listing.
        m("MacBook Neo (13-inch, A18 Pro)", 2026, "Mac17,5"),
        // MacBook: the Identify page gives no newest OS; Ventura's list has it, Sonoma's doesn't.
        m("MacBook (Retina, 12-inch, 2017)", 2017, "MacBook10,1", last: 13),
        // iMac
        m("iMac (24-inch, 2024, Four ports)", 2024, "Mac16,3"),
        m("iMac (24-inch, 2024, Two ports)", 2024, "Mac16,2"),
        m("iMac (24-inch, 2023, Four ports)", 2023, "Mac15,5"),
        m("iMac (24-inch, 2023, Two ports)", 2023, "Mac15,4"),
        m("iMac (24-inch, M1, 2021)", 2021, "iMac21,1", "iMac21,2"),
        m("iMac (Retina 5K, 27-inch, 2020)", 2020, "iMac20,1", "iMac20,2", last: 26),
        m("iMac (Retina 5K, 27-inch, 2019)", 2019, "iMac19,1", last: 15),
        m("iMac (Retina 4K, 21.5-inch, 2019)", 2019, "iMac19,2", last: 15),
        m("iMac Pro (2017)", 2017, "iMacPro1,1", last: 15),
        m("iMac (Retina 5K, 27-inch, 2017)", 2017, "iMac18,3", last: 13),
        m("iMac (Retina 4K, 21.5-inch, 2017)", 2017, "iMac18,2", last: 13),
        m("iMac (21.5-inch, 2017)", 2017, "iMac18,1", last: 13),
        // Mac mini
        m("Mac mini (M6)", 2026, "Mac18,5"),
        m("Mac mini (M5 Pro)", 2026, "Mac17,16"),
        m("Mac mini (2024)", 2024, "Mac16,10", "Mac16,11"),
        m("Mac mini (2023)", 2023, "Mac14,3", "Mac14,12"),
        m("Mac mini (M1, 2020)", 2020, "Macmini9,1"),
        m("Mac mini (2018)", 2018, "Macmini8,1", last: 15),
        // Mac Studio
        m("Mac Studio (M5 Max)", 2026, "Mac17,14"),
        m("Mac Studio (M5 Ultra)", 2026, "Mac17,15"),
        m("Mac Studio (2025)", 2025, "Mac16,9", "Mac15,14"),
        m("Mac Studio (2023)", 2023, "Mac14,13", "Mac14,14"),
        m("Mac Studio (2022)", 2022, "Mac13,1", "Mac13,2"),
        // Mac Pro (the Rack models share the identifiers)
        m("Mac Pro (2023)", 2023, "Mac14,8"),
        m("Mac Pro (2019)", 2019, "MacPro7,1", last: 26),
    ].flatMap { $0 }

    private static func m(_ name: String, _ year: Int, _ ids: String..., last: Int? = nil, touchBar: Bool = false) -> [ModelInfo] {
        ids.map { ModelInfo(identifier: $0, name: name, year: year, lastMacOS: last, touchBar: touchBar) }
    }
}
