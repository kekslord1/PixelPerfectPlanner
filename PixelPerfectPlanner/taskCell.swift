//
//  taskCell.swift
//  PixelPerfectPlanner
//
//  Created by Philipp Haug on 28.01.24.
//

import UIKit
import SQLite

// Class of the table Cell for displaying the task
class TaskCell: UITableViewCell {

    // define the outlets in the cell
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    // variable for the task id
    var taskId: Int64 = 0
    
    // Define the habittime table schema
    let habittime = Table("habittime")
    let date = Expression<String>("date")
    let descriptionh = Expression<String>("descriptionh")
    let typeth = Expression<String>("typeth")
    let timeDuration = Expression<Double>("timeDuration")

    // set date formatter
    let dateFormatter = DateFormatter()
    
    
    // set up of the task cell in the configure function
    func configure(with task: Task) {
        
        // set the title label to the task title
        titleLabel.text = task.taskTitle
        
        // set the ID variable to the task id
        taskId = task.id
        
        // check wether the task is due or overdue
        let currentDate = Date()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let formattedDate = dateFormatter.date(from: task.date) ?? currentDate
        
        // if overdue or due color the text red
        if formattedDate < currentDate {
            dueDateLabel.textColor = .red
        }
        
        // set the date label to the due date
        dueDateLabel.text = task.date
        
        // connect the button to the function
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
    }
    
    // function of the button to tick of the task
    @objc func buttonTapped() {
        
        // set the path of the database
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")
            
            // Connect to the SQLite database
            do {
                let db = try Connection(dbPath.path)
                
                // run the SQL command toset the done bool to due by looking up the task id
                try db.run("UPDATE tasks SET done = true WHERE id = \(taskId)")
                
                // update the tasklist and the table viecontroller by calling the fetchTask function
                if let dailyVC = self.findViewController() as? DailyVC {
                    dailyVC.fetchTasksForToday()
                }
                
                // get the date of today
                dateFormatter.dateFormat = "dd.MM.yyyy"
                let currentDate = dateFormatter.string(from: Date())
                
                // Add Task Completion to Habittime table
                let testValue = try db.prepare(habittime.filter(date == currentDate && typeth == "Habit" && descriptionh == "Task"))

                // check for the time duration
                let test = try testValue.map { row in
                    return try row.get(timeDuration)
                }
                
                // if theres no duration set it to 1
                if test.isEmpty {
                    // Execute the INSERT statement
                    try db.run(habittime.insert(date <- currentDate, typeth <- "Habit", descriptionh <- "Task", timeDuration <- 1))
                } else {
                    // if theres a duration add 1 to it
                    let newHours = test[0] + 1
                    try db.run(habittime.filter(date == currentDate && typeth == "Habit" && descriptionh == "Task")
                        .update(timeDuration <- newHours))
                }
            } catch {
                print("Error connecting to or updating tables in the database: \(error)")
            }
        } else {
            print("Error getting documents directory.")
        }
    }
}
