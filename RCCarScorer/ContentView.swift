import SwiftUI

struct ContentView: View {
    @StateObject var raceManager = RaceManager()
    @State private var newCarName = ""
    @State private var showingResults = false
    @State private var showingRaceSelection = false // Added state for race selection

    var body: some View {
        VStack {
            Text(raceManager.raceName)
                .font(.title)

            if raceManager.raceActive == false {
                Button("Start Race") {
                    raceManager.startRace()
                }
            } else {
                Button("Stop Race") {
                    raceManager.stopRace()
                    showingResults = true
                }
            }

            List {
                            ForEach(raceManager.cars.indices, id: \.self) { index in
                                HStack {
                                    Text(raceManager.cars[index].name)
                                    Spacer()
                                    VStack {
                                        Text("Laps: \(raceManager.cars[index].lapCount)")
                                        Text("Last Lap: \(raceManager.cars[index].lastLapTime, specifier: "%.2f")s") // Display lastLapTime from Car
                                    }
                                }
                                .onTapGesture {
                                    raceManager.recordLap(car: &raceManager.cars[index])
                                }
                            }
                        }

            HStack {
                TextField("Car Name", text: $newCarName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add Car") {
                    raceManager.addCar(carName: newCarName)
                    newCarName = ""
                }
            }
            .padding()

            Button("Select Race") { // Added "Select Race" button
                showingRaceSelection = true
            }
            .sheet(isPresented: $showingRaceSelection) {
                RaceSelectionView(raceManager: raceManager)
            }
        }
        .padding()
        .sheet(isPresented: $showingResults) {
            ResultsView(raceManager: raceManager)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
