//
//  dailyTaskDetail.swift
//  PixelPerfectPlanner
//
//  Created by Philipp Haug on 21.01.24.
//

import UIKit
import SQLite

// Detailed view of the task
class dailyTaskDetailVC: UIViewController {
    
    // input Variable from Segue
    var task: Task?

    // Define the outlets
    @IBOutlet weak var dueLabel: UILabel!
    @IBOutlet weak var detailNotes: UITextField!
    @IBOutlet weak var taskTitleComplete: UILabel!
    
    // Load view
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // unwrap input var
        let detailTaskTitle = task?.taskTitle ?? "Error"
        
        // set task titles
        self.title = detailTaskTitle
        taskTitleComplete.text = detailTaskTitle
        
        // when theres no input exit
        if detailTaskTitle == "Error" {
            return
        
        // else set all the information
        } else {
            
            // set the date
            dueLabel.text = task?.date
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let formattedDate = dateFormatter.date(from: task?.date ?? dateFormatter.string(from: currentDate)) ?? currentDate
            
            // color due label red its due or overdue
            if formattedDate < currentDate {
                dueLabel.textColor = .red
            }
            
            // set the notes
            detailNotes.text = task?.notes
        }
    }
}
