import SwiftUI

struct ResultsView: View {
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
            print("Fetched laps: \(laps)") // Added print statement
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
            if carDictionary[lap.carID] == nil {
                carDictionary[lap.carID] = [lap]
            } else {
                carDictionary[lap.carID]?.append(lap)
            }
        }
        
        var cars: [Car] = []
        let dispatchGroup = DispatchGroup()
        
        for (carID, laps) in carDictionary {
            dispatchGroup.enter()
            
            self.db.collection("races").document(self.raceID).collection("cars").document(carID).getDocument { (document, error) in
                if let document = document, document.exists {
                    if let carName = document.data()?["name"] as? String {
                        let totalTime: Double = laps.reduce(0.0) { (result: Double, lap: Lap) -> Double in
                            return result + lap.lapTime
                        }
                        let car = Car(name: carName, lapTimes: laps.map { $0.lapTime }, carID: carID, totalTime: totalTime)
                        cars.append(car)
                    } else {
                        let totalTime: Double = laps.reduce(0.0) { (result: Double, lap: Lap) -> Double in
                            return result + lap.lapTime
                        }
                        let car = Car(name: "Unknown", lapTimes: laps.map { $0.lapTime }, carID: carID, totalTime: totalTime)
                        cars.append(car)
                    }
                } else {
                    let totalTime: Double = laps.reduce(0.0) { (result: Double, lap: Lap) -> Double in
                        return result + lap.lapTime
                    }
                    let car = Car(name: "Unknown", lapTimes: laps.map { $0.lapTime }, carID: carID, totalTime: totalTime)
                    cars.append(car)
                }
                dispatchGroup.leave()
            }
        
        dispatchGroup.notify(queue: .main) {
            let sortedCars = cars.sorted(using: KeyPathComparator(\Car.totalTime, order: .forward))
            self.cars = sortedCars
        }
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

