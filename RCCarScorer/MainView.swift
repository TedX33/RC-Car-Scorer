//
//  MainView.swift
//  RCCarScorer
//
//  Created by Ted Brown on 3/18/25.
//


import SwiftUI

struct MainView: View {
    @StateObject var raceManager = RaceManager()
    @State private var showingScoreRace = false
    @State private var showingPreviousResults = false

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
            }
            .navigationTitle("Main Menu")
            .sheet(isPresented: $showingScoreRace) {
                ContentView(raceManager: raceManager) // Passing raceManager
            }
            .sheet(isPresented: $showingPreviousResults) {
                PreviousRaceResultsView(raceManager: raceManager)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}