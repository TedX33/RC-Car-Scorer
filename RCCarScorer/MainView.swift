import SwiftUI

struct MainView: View {
    @StateObject var raceManager = RaceManager()
    @State private var showingScoreRace = false
    @State private var showingPreviousResults = false
    @State private var showingCreateRace = false // New state for CreateRaceView

    var body: some View {
        NavigationView {
            VStack {
                Text("RC Car Scorer")
                    .font(.largeTitle)
                    .padding()

                Button("Score a Race") {
                    showingScoreRace = true
                }
                .padding()

                Button("See Results") {
                    showingPreviousResults = true
                }
                .padding()

                Button("Create a Race") { // New button
                    showingCreateRace = true
                }
                .padding()
            }
            .navigationTitle("Main Menu")
            .sheet(isPresented: $showingScoreRace) {
                ContentView(raceManager: raceManager)
            }
            .sheet(isPresented: $showingPreviousResults) {
                PreviousRaceResultsView(raceManager: raceManager)
            }
            .sheet(isPresented: $showingCreateRace) { // Present CreateRaceView
                CreateRaceView()
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
