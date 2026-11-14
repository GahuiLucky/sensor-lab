import SwiftUI

@main
struct SensorLabApp: App {
    @StateObject private var engine = SensorEngine()
    @StateObject private var tools = ToolStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .environmentObject(tools)
                .preferredColorScheme(.dark)
        }
    }
}
