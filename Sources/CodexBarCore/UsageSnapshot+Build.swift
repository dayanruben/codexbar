import Foundation

public extension UsageSnapshot {
    static func build(
        primary: RateWindow?,
        secondary: RateWindow?,
        tertiary: RateWindow? = nil,
        providerCost: ProviderCostSnapshot? = nil,
        zaiUsage: ZaiUsageSnapshot? = nil,
        cursorRequests: CursorRequestUsage? = nil,
        updatedAt: Date,
        identity: ProviderIdentitySnapshot? = nil) -> UsageSnapshot
    {
        UsageSnapshot(
            primary: primary,
            secondary: secondary,
            tertiary: tertiary,
            providerCost: providerCost,
            zaiUsage: zaiUsage,
            cursorRequests: cursorRequests,
            updatedAt: updatedAt,
            identity: identity)
    }
}
