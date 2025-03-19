import SwiftUI
import FirebaseFirestore

struct ResultsView: View {
    @ObservedObject var raceManager: RaceManager
    @State var cars: [Car] = []
    let raceID: String
    let db = Firestore.firestore() // ✅ Firestore reference added

    var sortedCars: [Car] {
        cars.sorted {
            if $0.lapCount != $1.lapCount {
                return $0.lapCount > $1.lapCount
            } else {
                return $0.calculateTotalLapTime() < $1.calculateTotalLapTime()
            }
        }
    }

    func formattedTime(_ timeInterval: Double) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((timeInterval * 1000).truncatingRemainder(dividingBy: 1000))
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }

    var body: some View {
        NavigationView {
            List(sortedCars) { car in
                VStack(alignment: .leading) {
                    Text(car.name)
                        .font(.headline)
                    Text("Laps: \(car.lapCount)")
                    Text("Total Time: \(formattedTime(car.calculateTotalLapTime()))")
                }
            }
            .navigationTitle("Race Results")
            .onAppear {
                fetchLaps()
            }
        }
    }

    func fetchLaps() {
        raceManager.fetchLaps(raceID: raceID) { laps in
            raceManager.organizeLapsByCar(laps: laps) { cars in
                self.cars = cars
            }
            print("Fetched laps: \(laps)")
            organizeLapsByCarAndSort(laps: laps)
        }
    }

    init(raceID: String, raceManager: RaceManager) {
        self.raceID = raceID
        self.raceManager = raceManager
    }

    func organizeLapsByCarAndSort(laps: [Lap]) {
        var carDictionary: [String: [Lap]] = [:]

        for lap in laps {
            carDictionary[lap.carID, default: []].append(lap)
        }

        var cars: [Car] = []
        let dispatchGroup = DispatchGroup()

        for (carID, laps) in carDictionary {
            dispatchGroup.enter()

            db.collection("races").document(self.raceID).collection("cars").document(carID).getDocument { (document, error) in
                defer { dispatchGroup.leave() }

                let carName = document?.data()?["name"] as? String ?? "Unknown"
                let totalTime = laps.reduce(0.0) { $0 + $1.lapTime }

                let car = Car(name: carName, lapTimes: laps.map { $0.lapTime })

                cars.append(car)
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.cars = cars.sorted { $0.totalTime < $1.totalTime }
        }
    }
}

extension Car {
    func calculateTotalLapTime() -> Double {
        lapTimes.reduce(0.0, +)
    }
}

