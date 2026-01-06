import CodexBarMacroSupport
import Foundation

@ProviderDescriptorRegistration
@ProviderDescriptorDefinition
public enum JunieProviderDescriptor {
    static func makeDescriptor() -> ProviderDescriptor {
        ProviderDescriptor(
            id: .junie,
            metadata: ProviderMetadata(
                id: .junie,
                displayName: "Junie",
                sessionLabel: "Session",
                weeklyLabel: "Weekly",
                opusLabel: nil,
                supportsOpus: false,
                supportsCredits: false,
                creditsHint: "",
                toggleTitle: "Show Junie usage",
                cliName: "junie",
                defaultEnabled: false,
                isPrimaryProvider: false,
                usesAccountFallback: false,
                dashboardURL: nil,
                statusPageURL: nil,
                statusLinkURL: nil),
            branding: ProviderBranding(
                iconStyle: .junie,
                iconResourceName: "ProviderIcon-junie",
                color: ProviderColor(red: 28 / 255, green: 160 / 255, blue: 242 / 255)),
            tokenCost: ProviderTokenCostConfig(
                supportsTokenCost: false,
                noDataMessage: { "Junie cost summary is not supported." }),
            fetchPlan: ProviderFetchPlan(
                sourceModes: [.auto, .cli],
                pipeline: ProviderFetchPipeline(resolveStrategies: { _ in [JunieCLIFetchStrategy()] })),
            cli: ProviderCLIConfig(
                name: "junie",
                aliases: ["junie-cli"],
                versionDetector: { JunieStatusProbe.detectVersion() }))
    }
}

struct JunieCLIFetchStrategy: ProviderFetchStrategy {
    let id: String = "junie.cli"
    let kind: ProviderFetchKind = .cli

    func isAvailable(_: ProviderFetchContext) async -> Bool {
        TTYCommandRunner.which("junie") != nil || TTYCommandRunner.which("junie-cli") != nil
    }

    func fetch(_: ProviderFetchContext) async throws -> ProviderFetchResult {
        let probe = JunieStatusProbe()
        let snap = try await probe.fetch()
        return self.makeResult(
            usage: snap,
            sourceLabel: "junie")
    }

    func shouldFallback(on _: Error, context _: ProviderFetchContext) -> Bool {
        false
    }
}
