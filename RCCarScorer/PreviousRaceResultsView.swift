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
    @State private var races: [(id: String, raceName: String, startTime: Date)] = []
    @State private var selectedRaceID: String? = nil
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(races, id: \.id) { race in
                        raceDisclosureGroup(for: race)
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

    private func raceDisclosureGroup(for race: (id: String, raceName: String, startTime: Date)) -> some View {
        DisclosureGroup(
            content: {
                disclosureGroupContent(for: race)
            },
            label: {
                HStack {
                    Text(race.raceName)
                    Spacer()
                    Text(race.startTime, style: .date)
                }
            }
        )
        .onTapGesture {
            handleTap(race: race)
        }
    }

    private func disclosureGroupContent(for race: (id: String, raceName: String, startTime: Date)) -> some View {
        if selectedRaceID == race.id {
            AnyView(ResultsView(raceID: race.id, raceManager: raceManager))
        } else {
            AnyView(Text("Select Race to view results"))
        }
    }

    private func handleTap(race: (id: String, raceName: String, startTime: Date)) {
        if selectedRaceID == race.id {
            selectedRaceID = nil
        } else {
            selectedRaceID = race.id
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
                    return (id: document.documentID, raceName: raceName, startTime: timestamp.dateValue())
                }
                return nil
            }
        }
    }

    init(raceManager: RaceManager){
        self.raceManager = raceManager
    }
}
