//
//  RaceSelectionView.swift
//  RCCarScorer
//
//  Created by Ted Brown on 3/16/25.
//

import SwiftUI

struct RaceSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var raceManager: RaceManager
    @State var races: [Race] = []

    var body: some View {
        NavigationView{
            List(races){race in
                Button(race.raceName){
                    raceManager.raceID = race.raceID
                    raceManager.raceName = race.raceName
                    raceManager.startTime = race.startTime
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Select Race")
            .onAppear(){
                raceManager.fetchRaces(){fetchedRaces in
                    races = fetchedRaces
                }
            }
        }
    }
}
