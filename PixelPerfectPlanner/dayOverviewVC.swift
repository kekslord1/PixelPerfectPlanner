//
//  dayOverviewVC.swift
//  PixelPerfectPlanner
//
//  Created by Philipp Haug on 27.01.24.
//

import UIKit
import SQLite

// view controller to view detailed stats of the day
class testerVC: UIViewController {

    // Define the big Label
    @IBOutlet weak var dayOverviewLabel: UILabel!
    
    // Set Variables
    var dateCV: String?
    var habitText = ""
    var dayDataTable: [HabitStruct] = []
    
    // Define the habittime table schema
    let habittime = Table("habittime")
    let date = Expression<String>("date")
    let descriptionh = Expression<String>("descriptionh")
    let typeth = Expression<String>("typeth")
    let timeDuration = Expression<Double>("timeDuration")

    // Load the View
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Unwrap date Variable
        let dateCV1 = dateCV ?? "Error"
        
        // Set title to the date
        self.title = dateCV1
        
        // Get Data of all habits and times of the day
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")
            
            // Connect to Database
            do {
                let db = try Connection(dbPath.path)
                
                // Clear the data from before
                dayDataTable.removeAll()
                
                // filter database to the selected date
                let dayValues = try db.prepare(habittime.filter(date == dateCV1))
                
                // add data in the habitstruct form to the datatable
                for dayValue in dayValues {
                    let dayData = HabitStruct(
                        descriptionh: dayValue[descriptionh],
                        date: dayValue[date],
                        typeth: dayValue[typeth],
                        timeDuration: dayValue[timeDuration]
                    )
                    dayDataTable.append(dayData)
                }
            } catch {
                print("Error getting data from the database: \(error)")
            }
        } else {
            print("Error getting documents directory.")
        }
        
        // Iterate over all Habits and Times for the date and write them in a text
        for habit in dayDataTable {
            var durationText = ""
            if habit.typeth == "Habit" {
                durationText = "\(Int(habit.timeDuration))x"
            } else if habit.typeth == "Time" {
                durationText = "\(habit.timeDuration)hr"
            }
            habitText += "\(habit.descriptionh): \(durationText)\n"
        }
        
        // Change the label to present the text
        dayOverviewLabel.numberOfLines = 0
        dayOverviewLabel.text = habitText
    }
}
