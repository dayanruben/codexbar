import CodexBarCore
import CodexBarMacroSupport
import Foundation

@ProviderImplementationRegistration
struct JunieProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .junie
}
