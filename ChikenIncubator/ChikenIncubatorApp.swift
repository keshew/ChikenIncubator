import SwiftUI

@main
struct ChickenIncubatorApp: App {
    @StateObject var data = DataManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(data)
        }
    }
}
