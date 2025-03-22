//
//  CreateRaceView.swift
//  RCCarScorer
//
//  Created by Ted Brown on 3/22/25.
//
//

import SwiftUI
import FirebaseFirestore

struct CreateRaceView: View {
    @State private var raceName: String = ""
    @State private var startTime: Date = Date()
    @State private var carName: String = ""
    @State private var cars: [String] = []
    @Environment(\.presentationMode) var presentationMode
    let db = Firestore.firestore()
    
    var body: some View {
        Form {
            Section(header: Text("Race Details")) {
                TextField("Race Name", text: $raceName)
                DatePicker("Start Time", selection: $startTime)
            }
            
            Section(header: Text("Add Cars")) {
                TextField("Car Name", text: $carName)
                Button("Add Car") {
                    cars.append(carName)
                    carName = ""
                }
                List(cars, id: \.self) { car in
                    Text(car)
                }
            }
            
            Button("Create Race") {
                createRace()
            }
        }
        .navigationTitle("Create Race")
    }
    
    func createRace() {
        let raceData: [String: Any] = [
            "raceName": raceName,
            "startTime": Timestamp(date: startTime),
            "raceStatus": "active"
        ]
        
        db.collection("races").addDocument(data: raceData) { error in
            if let error = error {
                print("Error creating race: \(error.localizedDescription)")
            } else {
                // Document creation successful
                db.collection("races").getDocuments() { (querySnapshot, error) in
                    if let err = error {
                        print("Error getting documents: \(err)")
                        return
                    }
                    guard let documents = querySnapshot?.documents else {
                        print("No documents found")
                        return
                    }
                    let lastDocument = documents.last
                    guard let lastDocId = lastDocument?.documentID else {return}
                    for car in cars {
                        addCarToRace(raceID: lastDocId, carName: car)
                    }
                    print("Race created successfully.")
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    func addCarToRace(raceID: String, carName: String) {
        db.collection("races").document(raceID).collection("cars").addDocument(data: ["name": carName]) { error in
            if let error = error {
                print("Error adding car: \(error.localizedDescription)")
            } else {
                print("Car '\(carName)' added to race.")
            }
        }
    }
}
