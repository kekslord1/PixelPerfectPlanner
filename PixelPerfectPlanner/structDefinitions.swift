//
//  structDefinitions.swift
//  PixelPerfectPlanner
//
//  Created by Philipp Haug on 28.01.24.
//

import UIKit
import SQLite

// Structure of a Habit or Time allocation
// timeDuration is either a count of how many Habits or of how much Time
struct HabitStruct {
    let descriptionh: String
    let date : String
    let typeth: String
    let timeDuration: Double
}

// Structure of a Task
struct Task {
    let id: Int64
    let date: String
    let taskTitle: String
    let notes: String?
    let done: Bool
}
