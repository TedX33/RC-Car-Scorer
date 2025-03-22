//
//  PreviousRaceResultsView.swift
//  RCCarScorer
//
//  Created by Ted Brown on 3/18/25.
//
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
                Text(race.raceName)
                            Spacer()
                            Text(race.startTime, style: .date)
            }
        )
        .onTapGesture {
            handleTap(race: race)
        }
    }

    private func disclosureGroupContent(for race: (id: String, raceName: String, startTime: Date)) -> some View {
            VStack {
                HStack {
                }
                if selectedRaceID == race.id {
                    RaceResultsView(raceID: race.id) // Pass the race.id to a dedicated view
                } else if selectedRaceID != nil {
                    Text("Select Race to view results")
                }
                    
            }
            .frame(minHeight: 300) // Example: Set a minimum height
    }
    struct RaceResultsView: View {
        let raceID: String
        @State var cars: [CarResult] = []


        struct CarResult: Identifiable {
            let id = UUID()
            let carName: String
            let totalTime: Double
            let lapTimes: [Double]
        }

        var body: some View {
            List(cars) { car in
                VStack(alignment: .leading) {
                    Text(car.carName).font(.headline)
                    Text("Total Time: \(car.totalTime, specifier: "%.3f")")
                    Text("Lap Times: \(car.lapTimes.map { String(format: "%.3f", $0) }.joined(separator: ", "))")
                }
            }
            .onAppear {
                fetchAndProcessLaps()
            }
        }

        func fetchAndProcessLaps() {
            // 1. Fetch Laps from Firestore
            Firestore.firestore().collection("laps").whereField("raceID", isEqualTo: raceID).getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }

                let laps = documents.compactMap { document -> Lap? in
                    // Map documents to Lap objects (you'll need your Lap struct)
                    guard let carID = document.data()["carID"] as? String,
                          let lapTime = document.data()["lapTime"] as? Double,
                          let timestamp = document.data()["timeStamp"] as? Timestamp else { return nil }
                    return Lap(raceID:raceID, carID: carID, lapTime: lapTime, timeStamp: timestamp.dateValue()) // Assuming your Lap struct has these fields
                }

                // 2. Group Laps by Car
                let carDictionary = Dictionary(grouping: laps, by: { $0.carID })

                // 3. Calculate Total Lap Time and 4. Sort Cars
                var carResults: [CarResult] = []
                let dispatchGroup = DispatchGroup()

                for (carID, laps) in carDictionary {
                    dispatchGroup.enter()
                    Firestore.firestore().collection("cars").document(carID).getDocument { document, error in
                        print("Fetching car info for carID:", carID)
                        print(document)
                        if let document = document, let carName = document.data()?["name"] as? String {
                            print ("Fetched car", carName)
                            let totalTime = laps.reduce(0.0) { $0 + $1.lapTime }
                            carResults.append(CarResult(carName: carName, totalTime: totalTime, lapTimes: laps.map { $0.lapTime }))
                            print("car Name", carName)
                        } else {
                            carResults.append(CarResult(carName: "Unknown", totalTime: laps.reduce(0.0) { $0 + $1.lapTime }, lapTimes: laps.map { $0.lapTime }))
                        }
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    self.cars = carResults.sorted(by: { $0.totalTime < $1.totalTime })
                }
            }
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
