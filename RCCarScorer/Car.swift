//
//  Car.swift
//  RCCarScorer
//
//  Created by Ted Brown on 3/16/25.
//

import Foundation

struct Car: Identifiable {
    let id = UUID()
    var name: String
    var lapCount: Int = 0
    var lapTimes: [Double] = []
    var lastLapTime: Double = 0 // Added property
}
