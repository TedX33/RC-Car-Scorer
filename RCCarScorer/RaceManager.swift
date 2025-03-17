import Foundation
import FirebaseFirestore

class RaceManager: ObservableObject {
    @Published var cars: [Car] = []
    @Published var startTime: Date?
    @Published var raceName: String = "My Race"
    @Published var raceID: String = ""
    @Published var raceActive: Bool = false
    let db = Firestore.firestore()

    func addCar(carName: String) {
        let newCar = Car(name: carName)
        cars.append(newCar)
    }

    func startRace() {
        startTime = Date()
        let raceData: [String: Any] = [
            "raceName": raceName,
            "startTime": startTime!
        ]
        let raceRef = db.collection("races").document()
        raceID = raceRef.documentID
        raceRef.setData(raceData) { error in
            if let error = error {
                print("Error uploading race data: \(error)")
            } else {
                print("Race data uploaded successfully!")
            }
        }
        raceActive = true
    }

    func stopRace() {
        startTime = nil
        raceActive = false
    }

    func recordLap(car: inout Car) {
            let currentTime = Date()
            guard let startTime = startTime else { return }

            let lapTime = currentTime.timeIntervalSince(startTime)
            car.lapTimes.append(lapTime)
            car.lapCount += 1

            let lastLapTime: Double
            if car.lapTimes.count > 1 {
                lastLapTime = car.lapTimes.last! - car.lapTimes[car.lapTimes.count - 2]
            } else {
                lastLapTime = currentTime.timeIntervalSince(startTime)
            }

            car.lastLapTime = lastLapTime // Store the last lap time in the car

            let lapData: [String: Any] = [
                "raceID": raceID,
                "carID": car.id.uuidString,
                "lapTime": lastLapTime,
                "timeStamp": currentTime
            ]

            db.collection("laps").addDocument(data: lapData) { error in
                if let error = error {
                    print("Error uploading lap data: \(error)")
                } else {
                    print("Lap data uploaded successfully!")
                }
            }
        }


    func fetchRaces(completion: @escaping ([Race]) -> Void) {
        db.collection("races").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting races: \(error)")
                completion([])
                return
            }

            guard let documents = querySnapshot?.documents else {
                completion([])
                return
            }

            let races = documents.compactMap { document -> Race? in
                let data = document.data()
                guard let raceName = data["raceName"] as? String,
                      let startTimeTimestamp = data["startTime"] as? Timestamp else {
                    return nil
                }
                let startTime = startTimeTimestamp.dateValue()
                return Race(raceID: document.documentID, raceName: raceName, startTime: startTime)
            }
            completion(races)
        }
    }
}
