//
//  AddTaskVC.swift
//  PixelPerfectPlanner
//
//  Created by Philipp Haug on 19.01.24.
//
import UIKit
import SQLite

// view controller to add tasks, habits, times and types
class AddTaskVC: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // connect the segment controller
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    // Define the tasks table schema
    let tasks = Table("tasks")
    let date = Expression<String>("date")
    let taskTitle = Expression<String>("title")
    let notes = Expression<String>("notes")
    let done = Expression<Bool>("done")
    
    // Define the habittime table schema
    let habittime = Table("habittime")
    let descriptionh = Expression<String>("descriptionh")
    let typeth = Expression<String>("typeth")
    let timeDuration = Expression<Double>("timeDuration")

    // Define the habit table schema
    let habit = Table("habit")

// connect all the labels, pickers, and textfields
    // Task stuff
    @IBOutlet weak var taskName: UITextField!
    @IBOutlet weak var taskDate: UIDatePicker!
    @IBOutlet weak var taskNotes: UITextField!
    
    // Habit stuff
    var habits: [String] = []
    @IBOutlet weak var descrptPicker: UIPickerView!
    
    // Time Stuff
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var endTimePicker: UIDatePicker!
   
    // Add Type
    let trackedTypes = ["Habit", "Time"]
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var nameType: UITextField!
    
    // Set the date formatter
    let dateFormatter = DateFormatter()
    
    // Load the view
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set datasource and delegate of the two Pickerview
        typePicker.dataSource = self
        typePicker.delegate = self
        descrptPicker.dataSource = self
        descrptPicker.delegate = self
        
        // set the titles for the segment control
        segmentedControl.setTitle("Task", forSegmentAt: 0)
        segmentedControl.setTitle("Habit", forSegmentAt: 1)
        segmentedControl.setTitle("Time", forSegmentAt: 2)
        segmentedControl.setTitle("Type", forSegmentAt: 3)
        
        // connect segment change function with the segmented Control
        segmentChanged(segmentedControl)
        
        // Set the second time picker to 1hr from the first
        let currentDate = Date()
        let oneHourFromNow = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)
        endTimePicker.date = oneHourFromNow ?? currentDate
    }

    
// set up the picker views
    // 1 component per row
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    // set both the habit selector as well as the type selector
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == typePicker {
            return trackedTypes.count
        } else {
            return habits.count
        }
    }
    
    
    // return the values for both picker views
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == typePicker {
            return trackedTypes[row]
        } else {
            return habits[row]
        }
    }
    
    
    // executed upon changing of the segment
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {

        // Get the selected segment index
        let selectedSegmentIndex = sender.selectedSegmentIndex

// Update UI based on the selected segment
        // hide all UI components
        taskName.isHidden           = true
        taskDate.isHidden           = true
        taskNotes.isHidden          = true
        typePicker.isHidden         = true
        nameType.isHidden           = true
        descrptPicker.isHidden      = true
        startTime.isHidden          = true
        startTimePicker.isHidden    = true
        endTime.isHidden            = true
        endTimePicker.isHidden      = true
        
        // switch case for the different segments
        switch selectedSegmentIndex {
        
        // Tasks segment
        case 0:
            
            // Update UI
            taskName.isHidden           = false
            taskDate.isHidden           = false
            taskNotes.isHidden          = false
        
            
        // Habits segment
        case 1:
            
            // Update UI
            descrptPicker.isHidden      = false
            
            // Update the description picker
            updateDescrptPicker(typeUDP: "Habit")
           
        
        // Time segment
        case 2:
            
            // Update the UI
            descrptPicker.isHidden      = false
            startTime.isHidden          = false
            startTimePicker.isHidden    = false
            endTime.isHidden            = false
            endTimePicker.isHidden      = false
            
            // update the description picker
            updateDescrptPicker(typeUDP: "Time")
        
            
        // Type segment
        case 3:
            
            // Update UI
            nameType.isHidden           = false
            typePicker.isHidden         = false
            
        
        // Default break the loop
        default:
            break
        }
    }
    
    // Function to update the description picker
    func updateDescrptPicker (typeUDP : String) {
        
        // Set the database path
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")
            
            // Connect to the SQLite database
            do {
                let db = try Connection(dbPath.path)
        
                // Get the values by filtering for the type (either Time or Habit
                let descriptionhValues = try db.prepare(habit.filter(typeth == typeUDP && descriptionh != "Task"))

                // Map the results to an array of descriptionh values
                habits = try descriptionhValues.map { row in
                    return try row.get(descriptionh)
                }
                
                // reload the description picker with the habits array
                descrptPicker.reloadAllComponents()
                
            } catch {
                print("Error getting data from the database: \(error)")
            }
        } else {
            print("Error getting documents directory.")
        }
    }

    
    // Function of the add button
    @IBAction func add(_ sender: UIButton) {
        
        // Get the selected segment index
        let selectedSegmentIndex = segmentedControl.selectedSegmentIndex
        
        // Switch case per Segment
        switch selectedSegmentIndex {
            
        // Add Task
        case 0:
            
            // Check and unwrap input
            guard let taskName1 = taskName.text else {
                return
            }
            
            let taskNotes1 = taskNotes.text ?? ""
            
            dateFormatter.dateFormat = "dd.MM.yyyy"

            let selectedDate = dateFormatter.string(from: taskDate.date)

            
            if taskName1.isEmpty || !taskName1.contains(where: { $0.isLetter }) {
                taskName.layer.borderColor = UIColor.red.cgColor
                taskName.layer.borderWidth = 1.0
                print("Error: Please enter a string with at least one letter")
                return
            }
            
            // Get the documents directory path
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")
                
                // Connect to the SQLite database
                do {
                    let db = try Connection(dbPath.path)

                    // Execute the INSERT statement
                    try db.run(tasks.insert(date <- selectedDate, taskTitle <-  taskName1, notes <- taskNotes1, done <- false))
                    print("Data inserted successfully.")
                } catch {
                    print("Error connecting to or inserting data into the database: \(error)")
                }
            } else {
                print("Error getting documents directory.")
            }
            
            taskName.text = ""
            taskNotes.text = ""
            taskName.layer.borderColor = nil
            taskName.layer.borderWidth = 0.0
            
        // Add Habit
        case 1:
            
            // Execute function to add a Habit
            addHabitOrTime(typeAHT: "Habit", hoursAHT: 1)
                    
        // Alocate Time
        case 2:

            // Get start and endtime
            let startTime = startTimePicker.date
            let endTime = endTimePicker.date
            
            // Calculate the time interval in seconds
            let timeInterval = endTime.timeIntervalSince(startTime)
            
            // Adjust unit to hours
            let hours = (Double(timeInterval / 3600) * 100).rounded() / 100
            
            // Execute function to add a time allocation
            addHabitOrTime(typeAHT: "Time", hoursAHT: hours)
        
        // Add Type
        case 3:

            // Grab value from Type Name - protect against 0
            guard let nameType1 = nameType.text else {
                return
            }
            
            // If field is left empty mark it red and exit function
            if nameType1.isEmpty || !nameType1.contains(where: { $0.isLetter }) {
                nameType.layer.borderColor = UIColor.red.cgColor
                nameType.layer.borderWidth = 1.0
                print("Error: Please enter a string with at least one letter")
                return
            }
            
            // Grab value from Type Picker
            let selectedRow = typePicker.selectedRow(inComponent: 0)
            let selectedValue = trackedTypes[selectedRow]
            
            // Connect to database and write value
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")
                
                // Connect to the SQLite database
                do {
                    let db = try Connection(dbPath.path)

                    // Execute the insert statement
                    try db.run(habit.insert(descriptionh <- nameType1, typeth <- selectedValue))
                    print("Data inserted successfully.")
                } catch {
                    print("Error connecting to or inserting data into the database: \(error)")
                }
            } else {
                print("Error getting documents directory.")
            }
            
            // Reset Name Type Text Field
            nameType.layer.borderColor = nil
            nameType.layer.borderWidth = 0.0
            nameType.text = ""
           
            
        // Set default for the switchcase to break
        default:
            break
        }
    }
    
    
    // Function to add a Habit or a Time allocation
    func addHabitOrTime (typeAHT: String, hoursAHT: Double) {
        
        // Grab value from Descr Picker
        let selectedRow = descrptPicker.selectedRow(inComponent: 0)
        let selectedValue = habits[selectedRow]
        
        // Set date of today
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let currentDate = dateFormatter.string(from: Date())
        
        // Safe the Time in the Database
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")
            
            // Connect to the SQLite database
            do {
                let db = try Connection(dbPath.path)
                
                // Check if theres already a line with the same type for today
                let testValue = try db.prepare(habittime.filter(date == currentDate && typeth == typeAHT && descriptionh == selectedValue))

                // Map the results to an array of descriptionh values
                let test = try testValue.map { row in
                    return try row.get(timeDuration)
                }
                
                // if theres no line for today with the same type
                if test.isEmpty {
                    // Execute the insert statement
                    try db.run(habittime.insert(date <- currentDate, typeth <- typeAHT, descriptionh <- selectedValue, timeDuration <- hoursAHT))
                } else {
                    // Otherwise update the duration time
                    let newHours = test[0] + hoursAHT
                    try db.run(habittime.filter(date == currentDate && typeth == typeAHT && descriptionh == selectedValue)
                        .update(timeDuration <- newHours))
                }
                print("Data inserted successfully.")
            } catch {
                print("Error connecting to or inserting data into the database: \(error)")
            }
        } else {
            print("Error getting documents directory.")
        }
    }
    
    
    // close keyboard when tapping somewhere else
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
}
