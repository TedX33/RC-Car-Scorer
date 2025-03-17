import SwiftUI

struct ContentView: View {
    @StateObject var raceManager = RaceManager()
    @State private var newCarName = ""
    @State private var showingResults = false
    @State private var showingRaceSelection = false
    @State private var raceNameInput: String = ""
    @State private var stopwatchTime: Double = 0
    @State private var timer: Timer?

    var body: some View {
        VStack {
            Text(formattedTime(stopwatchTime))
                .font(.largeTitle)
                .padding(.top)

            Spacer()

            TextField("Race Name", text: $raceNameInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if raceManager.raceActive == false {
                Button("Start Race") {
                    raceManager.raceName = raceNameInput
                    raceManager.startRace()
                    startStopwatch()
                }
            } else {
                Button("Stop Race") {
                    raceManager.stopRace()
                    stopStopwatch()
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
                            Text("Last Lap: \(raceManager.cars[index].lastLapTime, specifier: "%.2f")s")
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

            Button("Select Race") {
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

    func startStopwatch() {
            stopwatchTime = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in // Changed to 0.01
                stopwatchTime += 0.01
            }
        }

        func stopStopwatch() {
            timer?.invalidate()
            timer = nil
        }

        func formattedTime(_ timeInterval: Double) -> String {
            let minutes = Int(timeInterval / 60)
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            let hundredths = Int((timeInterval * 100).truncatingRemainder(dividingBy: 100)) // Calculate hundredths
            return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths) // Changed format
        }

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}
