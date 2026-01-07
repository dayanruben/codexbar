#if !os(macOS)
import Foundation

/// Minimal stub so UsageSnapshot compiles on non-macOS platforms.
public struct CursorRequestUsage: Codable, Sendable {
    public let used: Int
    public let limit: Int

    public init(used: Int, limit: Int) {
        self.used = used
        self.limit = limit
    }
}
#endif
