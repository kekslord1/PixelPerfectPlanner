//
//  YearlyVC.swift
//  PixelPerfectPlanner
//
//  Created by Philipp Haug on 19.01.24.
//

import UIKit
import SQLite

// Screen for the year in pixel view
class YearlyVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate, UICollectionViewDelegateFlowLayout {
    
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

    // connection to the collection view for the year in pixels
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Selector for Items
    var stats: [String] = []
    @IBOutlet weak var selectorStat: UIPickerView!
    
    // Empty table to store habits or time
    var habitsTable: [HabitStruct] = []
    
    // Set up Calender + Year
    let calendar = Calendar.current
    let currentYear = Calendar.current.component(.year, from: Date())
    let dateFormatter = DateFormatter()
    
    // Color Scale Display
    var colorScale: [Double] = []
    @IBOutlet weak var maxColoring: UIView!
    @IBOutlet weak var maxColoringLabel: UILabel!
    @IBOutlet weak var minColoring: UIView!
    @IBOutlet weak var minColoringLabel: UILabel!
    let minColor = UIColor(red: 1.0, green: 0.2745, blue: 0.2745, alpha: 1.0)
    let maxColor = UIColor(red: 0.4, green: 1.0   , blue: 0.4   , alpha: 1.0)
    
    // load the view
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set dataSource and delegate for the picker and the collection view
        selectorStat.dataSource = self
        selectorStat.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // round the edges of the color legend
        maxColoring.layer.cornerRadius = 10
        maxColoring.clipsToBounds = true
        minColoring.layer.cornerRadius = 10
        minColoring.clipsToBounds = true
        
        // set coloring in the legend
        maxColoring.backgroundColor = maxColor
        minColoring.backgroundColor = minColor
        
        // Register cell classes
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Day")

        // Populate Pickerview with selection options
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")

            // Connect to the SQLite database
            do {
                let db = try Connection(dbPath.path)
                
                // get the values of all the habits from the database
                let statsValues = try db.prepare(habit)

                // Map the results to an array of descriptionh values
                stats = try statsValues.map { row in
                    return try row.get(descriptionh)
                }
                // sort the array that "Task" is always on the top
                stats.sort { $0 == "Task" ? true : $1 == "Task" ? false : $0 < $1 }
                
                // reload the pickerview with the new items
                selectorStat.reloadAllComponents()
            } catch {
                print("Error getting data from the database: \(error)")
            }
        } else {
            print("Error getting documents directory.")
        }
    }
    
    
    // when page is selected by tab bar the data on page should be updated
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Populate Pickerview with selection options
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")

            // Connect to the SQLite database
            do {
                let db = try Connection(dbPath.path)
                
                // get the values of all the habits from the database
                let statsValues = try db.prepare(habit)

                // Map the results to an array of descriptionh values
                stats = try statsValues.map { row in
                    return try row.get(descriptionh)
                }
                // sort the array that "Task" is always on the top
                stats.sort { $0 == "Task" ? true : $1 == "Task" ? false : $0 < $1 }
                
                // reload the pickerview with the new items
                selectorStat.reloadAllComponents()
            } catch {
                print("Error getting data from the database: \(error)")
            }
        } else {
            print("Error getting documents directory.")
        }
        
        // find out which stat the picker view has selected
        let selectedRow = selectorStat.selectedRow(inComponent: 0)
        
        // get the respective data
        handlePickerSelection(row: selectedRow)
        selectorStat.reloadAllComponents()
    }

    
// Set Up the Picker view
    // number of Components
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    // how many components
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return stats.count
    }
    
    
    // title of the components
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stats[row]
    }
    
    
    // when new selection get data for the selected option
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        handlePickerSelection(row: row)
    }

    
    // function to get the data for the selected option and set the color scale
    func handlePickerSelection(row : Int) {
        let selectedOption = stats[row]
        
        // connect to sqlite database
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dbPath = documentsPath.appendingPathComponent("pixelPerfectPlanner.db")
            
            do {
                let db = try Connection(dbPath.path)
                
                // clear the current data to store all the updated data
                habitsTable.removeAll()
        
                // get data from the database
                let habitValues = try db.prepare(habittime.filter(descriptionh == selectedOption))
                
                // store relevant data in the array
                for habitValue in habitValues {
                    let habit = HabitStruct(
                        descriptionh: habitValue[descriptionh],
                        date: habitValue[date],
                        typeth: habitValue[typeth],
                        timeDuration: habitValue[timeDuration]
                    )
                    habitsTable.append(habit)
                }
                
                // set maximum and minimum by looking for the respective values in the array
                let maxDuration = habitsTable.max(by: { $0.timeDuration < $1.timeDuration })?.timeDuration ?? 0
                let minDuration = habitsTable.min(by: { $0.timeDuration < $1.timeDuration })?.timeDuration ?? 0
                
                // reset the colorscale
                colorScale.removeAll()
                
                // calculate the steps between the milestones for the scale
                let stepper = (maxDuration - minDuration) / 4
                
                // create color scale
                colorScale.append(maxDuration)
                for i in 1..<5 {
                    colorScale.append(maxDuration - (stepper * Double(i)))
                }
                
                // change the legend on the screen to match the scale
                minColoringLabel.text = "Min: \(minDuration)"
                maxColoringLabel.text = "Max: \(maxDuration)"
                
            } catch {
                print("Error getting data from the database: \(error)")
            }
        } else {
            print("Error getting documents directory.")
        }
        // reload the collection view
        collectionView.reloadData()
    }
    

// set up collection view
    // adjust the number of sections -> should be updated to reflect more years
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    
    // calculates how many days are in the current year -> sets item count to that ammount
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let numberOfDaysInYear = calendar.range(of: .day, in: .year, for: Date())?.count ?? 365
        return numberOfDaysInYear
    }
    
    // Sets up the cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // connects cell to story board
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Day", for: indexPath)
        
        // sets date formatter
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        // start date should be the first of the current year
        let startDate = dateFormatter.date(from: "01.01.\(currentYear)")
        
        // check for date on the day for the current cell
        if let currentDate = calendar.date(byAdding: .day, value: indexPath.item, to: startDate ?? Date()) {
           // Find the corresponding HabitStruct in habitsTable
           if let habit = habitsTable.first(where: { $0.date == dateFormatter.string(from: currentDate) }) {
               
               // Set the background color based on the data and color scale
               switch habit.timeDuration {
               case ..<colorScale[4]:
                   cell.backgroundColor = .gray
               case colorScale[4]..<colorScale[3]:
                   cell.backgroundColor = minColor
               case colorScale[3]..<colorScale[2]:
                   cell.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)
               case colorScale[2]..<colorScale[1]:
                   cell.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 0.4, alpha: 1.0)
               case colorScale[1]..<colorScale[0]:
                   cell.backgroundColor = UIColor(red: 0.8, green: 1.0, blue: 0.4, alpha: 1.0)
               case colorScale[0]...:
                   cell.backgroundColor = maxColor
               default:
                   // otherwise leave set it gray
                   cell.backgroundColor = .gray
               }

           } else {
               // otherwise leave set it gray
               cell.backgroundColor = .gray
           }
       }
        return cell
    }
    
    // Adjust the width and height of the cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth: CGFloat = 20
        let cellHeight: CGFloat = 20
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    // Adjust the horizontal spacing between cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    
    // Adjust the vertical spacing between rows
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    
    // prepare the segue for new screen with specific data when one item is selected
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! testerVC
        destVC.dateCV = sender as? String
    }
    
    // show new screen with specific data when one item is selected
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // set date format
        dateFormatter.dateFormat = "dd.MM.yyyy"

        // get the date of the selected cell
        let startDate = dateFormatter.date(from: "01.01.\(currentYear)")
        let currentDate = calendar.date(byAdding: .day, value: indexPath.item, to: startDate ?? Date())
        
        // perform the segue and send the current date with it
        performSegue(withIdentifier: "toDailyOverview", sender: dateFormatter.string(from: currentDate!))
    }
}
