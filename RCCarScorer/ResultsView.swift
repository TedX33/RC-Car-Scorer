import SwiftUI

struct RaceResults: View {
    @ObservedObject var raceManager: RaceManager
    @State var cars: [Car] = []
    let raceID: String

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
        }
    }

    init(raceID: String, raceManager: RaceManager) {
        self.raceID = raceID
        self.raceManager = raceManager
    }
}

extension Car {
    func calculateTotalLapTime() -> Double {
        var totalLapTime: Double = 0.0
        for lapTime in lapTimes {
            totalLapTime += lapTime
        }
        return totalLapTime
    }
}
