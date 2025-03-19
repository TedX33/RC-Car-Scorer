import Foundation
import FirebaseFirestore

class RaceManager: ObservableObject {
    @Published var cars: [Car] = []
    @Published var raceActive = false
    @Published var raceID: String = ""
    @Published var raceName: String = ""
    let db = Firestore.firestore()
    var startTime: Date?
    
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
    func fetchLaps(raceID: String, completion: @escaping ([Lap]) -> Void) {
        db.collection("laps").whereField("raceID", isEqualTo: raceID).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting laps: \(error)")
                //completion // Provide an empty array on error
                return
            }

            guard let documents = querySnapshot?.documents else {
                //completion // Provide an empty array if no documents
                return
            }

            let laps = documents.compactMap { document -> Lap? in
                let data = document.data()
                guard let carID = data["carID"] as? String,
                      let lapTime = data["lapTime"] as? Double,
                      let timeStampTimestamp = data["timeStamp"] as? Timestamp else {
                    return nil
                }
                let timeStamp = timeStampTimestamp.dateValue()
                return Lap(raceID: raceID, carID: carID, lapTime: lapTime, timeStamp: timeStamp)
            }
            completion(laps) // Provide the 'laps' array
        }
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

    func organizeLapsByCar(laps: [Lap], completion: @escaping ([Car]) -> Void) {
        var carDict: [String: Car] = [:]
        let group = DispatchGroup()
        
        for lap in laps {
            group.enter()
            db.collection("cars").document(lap.carID).getDocument { (document, error) in
                if let document = document, document.exists, let data = document.data(), let carName = data["name"] as? String {
                    if var car = carDict[lap.carID] {
                        car.lapTimes.append(lap.lapTime)
                        car.lapCount += 1
                        carDict[lap.carID] = car
                    } else {
                        let newCar = Car(id: UUID(uuidString: lap.carID)!, name: carName, lapCount: 1, lapTimes: [lap.lapTime])
                        carDict[lap.carID] = newCar
                    }
                } else {
                    print("Car document not found for ID: \(lap.carID)")
                    if var car = carDict[lap.carID] {
                        car.lapTimes.append(lap.lapTime)
                        car.lapCount += 1
                        carDict[lap.carID] = car
                    } else {
                        let newCar = Car(id: UUID(uuidString: lap.carID)!, name: "Unknown", lapCount: 1, lapTimes: [lap.lapTime])
                        carDict[lap.carID] = newCar
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(Array(carDict.values))
        }
    }
    
    func addCar(carName: String) {
        let newCar = Car(name: carName, lapCount: 0, lapTimes: [])
        cars.append(newCar)
        db.collection("cars").document(newCar.id.uuidString).setData(["name": newCar.name])
    }
}
