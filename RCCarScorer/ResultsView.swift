//
//  ResultsView.swift
//  RCCarScorer
//
//  Created by Ted Brown on 3/16/25.
//


import SwiftUI

struct ResultsView: View {
    @ObservedObject var raceManager: RaceManager
    @Environment(\.presentationMode) var presentationMode

    var sortedCars: [Car] {
        raceManager.cars.sorted {
            if $0.lapCount != $1.lapCount {
                return $0.lapCount > $1.lapCount
            } else {
                return $0.lapTimes.reduce(0, +) < $1.lapTimes.reduce(0, +)
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
                    Text("Total Time: \(formattedTime(car.lapTimes.reduce(0, +)))") // Use formattedTime
                }
            }
            .navigationTitle("Race Results")
            .toolbar {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
