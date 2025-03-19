//
//  PreviousRaceResultsView.swift
//  RCCarScorer
//
//  Created by Ted Brown on 3/18/25.
//


import SwiftUI
import FirebaseFirestore

struct PreviousRaceResultsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var raceManager: RaceManager
    @State private var races: [(id: String, raceName: String, createdAt: Date)] = []
    @State private var selectedRaceID: String? = nil
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(races, id: \.id) { race in
                        DisclosureGroup(
                            content: {
                                if selectedRaceID == race.id {
                                    RaceResults(raceID: race.id, raceManager: raceManager)
                                } else {
                                    Text("Select Race to view results")
                                }
                            },
                            label: {
                                HStack {
                                    Text(race.raceName)
                                    Spacer()
                                    Text(race.createdAt, style: .date)
                                }
                            }
                        )
                        .onTapGesture {
                            if selectedRaceID == race.id {
                                selectedRaceID = nil
                            } else {
                                selectedRaceID = race.id
                            }
                        }
                    }
                }
            }
            .navigationTitle("Previous Race Results")
            .toolbar {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .onAppear {
                fetchRaces()
            }
        }
    }

    func fetchRaces() {
        db.collection("races").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting races: \(error.localizedDescription)")
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No documents found in 'races' collection.")
                return
            }

            self.races = documents.compactMap { document in
                let data = document.data()
                if let raceName = data["raceName"] as? String,
                   let timestamp = data["startTime"] as? Timestamp {
                    return (id: document.documentID, raceName: raceName, createdAt: timestamp.dateValue())
                }
                return nil
            }
        }
    }

    init(raceManager: RaceManager){
        self.raceManager = raceManager
    }
}
