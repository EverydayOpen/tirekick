import Foundation
import TirekickCore

public enum SystemInfo {
    public static func osVersion() -> OSVersion {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return OSVersion(v.majorVersion, v.minorVersion, v.patchVersion)
    }
}
