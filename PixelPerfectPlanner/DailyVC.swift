//
//  DailyVC.swift
//  PixelPerfectPlanner
//
//  Created by Philipp Haug on 19.01.24.
//

import UIKit
import SQLite

class DailyVC: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    
    // Define the tasks table schema
    let tasks = Table("tasks")
    let id = Expression<Int64>("id")
    let date = Expression<String>("date")
    let taskTitle = Expression<String>("title")
    let notes = Expression<String?>("notes")
    let done = Expression<Bool>("done")
    
    // Define the habittime table schema
    let habittime = Table("habittime")
    let descriptionh = Expression<String>("descriptionh")
    let typeth = Expression<String>("typeth")
    let timeDuration = Expression<Double>("timeDuration")

    // Define the habit table schema
    let habit = Table("habit")
    
    // set Tasktable to store tasks
    var tasksTable: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // define path to SQLite database
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")
            
            // Connect to the SQLite database
            do {
                print(dbPath)
                let db = try Connection(dbPath.path)
                
                // create Tasks table if not existent
                try db.run(tasks.create(ifNotExists: true) { table in
                    table.column(id, primaryKey: .autoincrement)
                    table.column(date)
                    table.column(taskTitle, check: taskTitle != "")
                    table.column(notes)
                    table.column(done, defaultValue: false)
                })
                
                // create habit table if not existent
                try db.run(habit.create(ifNotExists: true) { table in
                    table.column(id, primaryKey: .autoincrement)
                    table.column(descriptionh, unique: true)
                    table.column(typeth)
                })
                
                // create habit table if not existent
                try db.run(habittime.create(ifNotExists: true) { table in
                    table.column(id, primaryKey: .autoincrement)
                    table.column(date)
                    table.column(descriptionh)
                    table.column(typeth)
                    table.column(timeDuration)
                })
                
                // Insert Task as a Habit
                try db.run(habit.insert(or: .replace, descriptionh <- "Task", typeth <- "Habit"))

            } catch {
                print("Error connecting to or creating tables in the database: \(error)")
            }
        } else {
            print("Error getting documents directory.")
        }
        
        // run the function that checks for all undone tasks
        fetchTasksForToday()
    }
    
    
    // when view appears due to the tab bar also check for all undone task
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTasksForToday()
    }
    
    
    // function to check for all undone tasks
    func fetchTasksForToday() {
        
        // set path to database
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")
            
            // connect to database
            do {
                let db = try Connection(dbPath.path)
                
                // clear the array to save tasks only once
                tasksTable.removeAll()

                // filter the tasks table to show only undone tasks -> ordered by date
                let filteredTasks = try db.prepare(tasks.filter(done == false).order(date))

                // store them all in the taskstable array
                for taskRow in filteredTasks {
                   let task = Task(
                       id: taskRow[id],
                       date: taskRow[date],
                       taskTitle: taskRow[taskTitle],
                       notes: taskRow[notes],
                       done: taskRow[done]
                   )
                   tasksTable.append(task)
                }
            } catch {
                print("Error fetching tasks: \(error)")
            }
        } else {
            print("Error getting documents directory.")
        }
        // reload the table view to update the tasks list
        tableView.reloadData()
    }
    
    
    // prepare segue to the detailed view of the task send the information of the task
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! dailyTaskDetailVC
        destVC.task = sender as? Task
    }
    
    
    // by clicking on a task perform the segue to the detailed view and send the information of the task
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = tasksTable[indexPath.row]
        performSegue(withIdentifier: "toDailyTaskDetail", sender: task)
    }
    
    
// set up the table view to display the tasks
    // set the count of the row to the length of the array with the tasks
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksTable.count
    }

    
    // set up each cell with the information of the corresponding task
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        let task = tasksTable[indexPath.row]
        
        // esecute the configure function of the cell class
        cell.configure(with: task)

        return cell
    }
    
    
    // close keyboard when tapping somewhere else
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
}
