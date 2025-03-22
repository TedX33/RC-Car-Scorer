//
//  Car.swift
//  RCCarScorer
//
//  Created by Ted Brown on 3/16/25.
//
//
import Foundation

class Car: Identifiable {
    let id: UUID
    var name: String
    var lapCount: Int
    var lapTimes: [Double]
    var lastLapTime: Double = 0
    var totalTime: Double = 0
    
    init(id: UUID = UUID(), name: String, lapCount: Int = 0, lapTimes: [Double] = []) {
        self.id = id
        self.name = name
        self.lapCount = lapCount
        self.lapTimes = lapTimes
    }
}
