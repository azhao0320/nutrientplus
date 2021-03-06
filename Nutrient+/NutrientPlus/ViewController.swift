//
//  ViewController.swift
//  Nutrient+
//
//  Created by Robert Sato on 10/11/19.
//  Copyright © 2019 Robert Sato. All rights reserved.
//
// image retrieval tutorial: https:// www.youtube.com/watch?v=bF9cEcte0-E&t=623s
// URL retrieval through web scraping: https:// www.youtube.com/watch?v=gscuaUSkxnI

import UIKit
import WebKit
import CoreData
import SQLite

struct Card {
    var nutritionLabel : String
    var progressPercent : Double
    var color : UIColor
}

class NutritionCards: UITableViewCell {
    @IBOutlet weak var nutritionProgressView: UIProgressView!
    @IBOutlet weak var nutritionTitleLabel: UILabel!
    @IBOutlet weak var nutritionProgressLabel: UILabel!
}

class ViewController: UIViewController {	
    @IBOutlet weak var tableView: UITableView!
    var cards: [Card] = []
    var height: Int16 = 0
    var weight: Double = 0.0
    var birthdate: Date = Date()
    var tester: String = "did not change"
    var gender: String = ""
    var user = [User]()
    var length: NSInteger = 0

    
    // variable for displaying image; used in viewDidLoad()
    @IBOutlet weak var recFoodImg: UIImageView!
    @IBOutlet weak var recFoodLabel: UILabel!
    var recFoodArrayInfo: [String] = []
    
    //for initializing nutrients
    let macros = ["Energy", "Protein", "Carbs", "Fat"]
    let vitamins = ["B1", "B2", "B3", "B5", "B6", "B12",
                    "Folate", "VitaminA", "VitaminC",
                    "VitaminD", "VitaminE", "VitaminK"]
    let minerals = ["Calcium", "Copper", "Iron", "Magnesium",
                    "Manganese", "Phosphorus", "Potassium",
                    "Selenium", "Sodium", "Zinc"]
    //nutrients stores daily nutritional data
    var nutrients = [String: Double]()
    //nutrientTargets stores the daily targets
    var nutrientTargets = [String: Double]()
    var targetsEdited = false
    
    //Database local data
    let nutrDB = SQLiteDatabase.instance
    let staticDB = NutrientDB.instance
    
    var storedNutrientData = [NutrientStruct]()
    var storedNutrientDataDict = [String:NutrientStruct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //SQL DB stuff
        if !targetsEdited {
            // assigns the user's info to the class variable to be used to calculate target goals
            let test: NSFetchRequest<User> = User.fetchRequest()
            do {
                let formatter = NumberFormatter()
                formatter.generatesDecimalNumbers = true
                let user = try PersistenceService.context.fetch(test)
                self.user = user
                length = user.count - 1
                //let origWeight = String(describing: user[length].weight)
                weight = Double(truncating: user[length].weight!)
                height = user[length].height
                gender = user[length].sex ?? "Male"
                birthdate = user[length].birthday!
                
                let weightUnitString = user[length].weightUnit
                let heightUnitString = user[length].heightUnit
                
                // convert height to cm
                if heightUnitString == "in" {
                    height = Int16(Double(height) * 2.54)
                }
                
                // convert weight to kg
                if weightUnitString == "lbs" {
                    let divisor =  0.453592
                    weight = weight * divisor
                    //weight = weight * 0.45
                }
            } catch {}
            //calculate the targets and store in a dictionary
            nutrientTargets = calculate(weight: weight, gender: gender, length: length, birthdate: birthdate)
        }
        
        //using the dictionary, initialize nutrients and targets
        //nutrDB.deleteTable()
        init_nutrients_and_targets()
        
        //tableView.reloadData()
        tableView.delegate = self
        tableView.dataSource = self
        
        
        // creates each of the nutrient cards in the table view
        self.cards = self.populate()
        
        // displays recommended food at top tab
        self.recFoodArrayInfo = self.staticDB.printRemainingNutrients()
        if recFoodArrayInfo.count != 0 {
            self.recFoodLabel.text = self.recFoodArrayInfo[0]
        } else {
            self.recFoodLabel.text = "N/A"
        }

    }

    func init_nutrients_and_targets() {
        var insertId: Int64 = 0
        for item in macros {
            insertId = nutrDB.addNutr(iName: item, iWeight: 0, iTarget: Double(nutrientTargets[item] ?? 0), iProgress: 0)!
            if insertId == -1 {
                nutrDB.updateTarget(iName: item, iTarget: Double(nutrientTargets[item] ?? 0))
            }
        }
        for item in vitamins {
            insertId = nutrDB.addNutr(iName: item, iWeight: 0, iTarget: Double(nutrientTargets[item] ?? 0), iProgress: 0)!
            if insertId == -1 {
                nutrDB.updateTarget(iName: item, iTarget: Double(nutrientTargets[item] ?? 0))
            }
        }
        for item in minerals {
            insertId = nutrDB.addNutr(iName: item, iWeight: 0, iTarget: Double(nutrientTargets[item] ?? 0), iProgress: 0)!
            if insertId == -1 {
                nutrDB.updateTarget(iName: item, iTarget: Double(nutrientTargets[item] ?? 0))
            }
        }
    }
    
    // creates the table view on the main page
    func populate() -> [Card] {
        //create an array of Card
        var tempCards: [Card] = []
        var card: Card
        storedNutrientData = nutrDB.getNutr()
        storedNutrientDataDict = nutrDB.getNutrDict()
        //print(storedNutrientDataDict)
        for nutrient in storedNutrientData {
            card = Card(nutritionLabel: nutrient.nutrName, progressPercent: (nutrient.nutrProgress) / (nutrient.nutrTarget), color: .random())
            tempCards.append(card)
        }
        return tempCards
    }
    
    // for sending data over segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is EditInfoVC
        {
            let vc = segue.destination as? EditInfoVC
            vc?.nutrientTargets = self.nutrientTargets
            vc?.nutrients = self.nutrients
        }
        if segue.destination is RecFoodInfo {
            let vc = segue.destination as? RecFoodInfo
            vc?.recFoodArrayInfo = self.recFoodArrayInfo
            var macroMicroInfo: [String] = macros
            macroMicroInfo += vitamins
            macroMicroInfo += minerals
            vc?.nutrientNames = macroMicroInfo
        }
    }
    
}

// calculates the target goal given the user's inputted info from Startup
func calculate(weight: Double, gender: String, length: NSInteger, birthdate: Date  ) ->  Dictionary<String, Double> {
    var dictionary: [String : Double] = [:]
    let calendar = Calendar.current
    let birthday = birthdate
    let now = Date()
    let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
    let age = ageComponents.year!
    
    if (gender == "Female") {
        let ans = 0.9 * weight * 24 
        //let intAns: Int = Int(ans)
        
        dictionary["Energy"] = Double(ans)
        if (age<=50 && age>18){
            dictionary["B6"] = 1.3
        }
        if(age < 3){
            dictionary["B1"] = 0.5
            dictionary["B2"] = 0.5
            dictionary["B5"] = 2
            dictionary["B6"] = 0.5
            dictionary["B12"] = 0.9
            dictionary["Folate"] = 150
            dictionary["Iron"] = 15.1
            dictionary["Calcium"] = 1200 //mg
            dictionary["VitaminA"] = 300/0.3
            dictionary["VitaminC"] = 15
            dictionary["VitaminE"] = 6
            dictionary["VitaminK"] = 30
            dictionary["Magnesium"] = 80
        } else if (age <= 8){
            dictionary["B1"] = 0.6
            dictionary["B2"] = 0.6
            dictionary["B5"] = 3
            dictionary["B6"] = 0.6
            dictionary["B12"] = 1.2
            dictionary["Folate"] = 200
            dictionary["Iron"] = 15.1
            dictionary["Calcium"] = 1300
            dictionary["VitaminA"] = 400/0.3
            dictionary["VitaminC"] = 25
            dictionary["VotaminE"] = 7
            dictionary["VitaminK"] = 55
            dictionary["Magnesium"] = 130
        } else if (age <= 13){
            dictionary["B1"] = 0.9
            dictionary["B2"] = 0.9
            dictionary["B5"] = 4
            dictionary["B6"] = 1.0
            dictionary["B12"] = 1.3
            dictionary["Folate"] = 300
            dictionary["VitaminA"] = 600/0.3
            dictionary["Calcium"] = 1300
            dictionary["VitaminC"] = 45
            dictionary["VotaminE"] = 11
            dictionary["VitaminK"] = 60
            dictionary["Iron"] = 15.1
            dictionary["Magnesium"] = 240
        } else if (age <= 18){
            dictionary["B1"] = 1.0
            dictionary["B2"] = 1.0
            dictionary["B6"] = 1.3
            dictionary["Folate"] = 400
            dictionary["VitaminA"] = 700/0.3
            dictionary["VitaminC"] = 65
            dictionary["VitaminK"] = 75
            dictionary["Calcium"] = 1300
            dictionary["Iron"] = 16.3
            dictionary["Magnesium"] = 360
        }  else {
            dictionary["B1"] = 1.1
            dictionary["B2"]=1.2
            dictionary["B5"] = 5
            dictionary["B6"] = 1.7
            dictionary["B12"] = 2.4
            dictionary["Folate"] = 150
            dictionary["VitaminA"] = 700/0.3
            dictionary["VitaminC"] = 75
            dictionary["VitaminK"] = 120
            dictionary["Calcium"] = 1200
            dictionary["Iron"] = 20.5
            dictionary["Magnesium"] = 320
        }
        dictionary["B3"] = 14
        dictionary["VitaminE"] = 15
    }
    
    if (gender == "Male") {
        let ans = 1 * weight * 24 * 1.55
        let intAns: Int = Int(ans)
        let ans1 = Double(intAns)
        dictionary["Energy"] = ans1
        if (age<=50 && age>18){
            dictionary["B6"] = 1.3
        }
        if(age<3){
            dictionary["B1"] = 0.5
            dictionary["B2"] = 0.5
            dictionary["B5"] = 2
            dictionary["B6"] = 0.5
            dictionary["B12"] = 0.9
            dictionary["Folate"] = 150
            dictionary["Iron"] = 15.1
            dictionary["Calcium"] = 1200
            dictionary["VitaminA"] = 300/0.3
            dictionary["VitaminC"] = 15
            dictionary["VitaminE"] = 6
            dictionary["VitaminK"] = 30
            dictionary["Magnesium"] = 80
        } else if (age <= 8) {
            dictionary["B1"] = 0.6
            dictionary["B2"] = 0.6
            dictionary["B5"] = 3
            dictionary["B6"] = 0.6
            dictionary["B12"] = 1.2
            dictionary["Calcium"] = 1200
            dictionary["Iron"] = 15.1
            dictionary["Folate"] = 200
            dictionary["VitaminA"] = 400/0.3
            dictionary["VitaminC"] = 25
            dictionary["VitaminE"] = 7
            dictionary["VitaminK"] = 55
            dictionary["Magnesium"] = 130
        } else if (age<=13){
              dictionary["B1"] = 0.9 //mg
              dictionary["B2"] = 0.9 //mg
              dictionary["B5"] = 4   //mg
              dictionary["B6"] = 1.0 //mg
              dictionary["B12"] = 1.8 //mg
              dictionary["Folate"] = 300 //mcg
            dictionary["VitaminA"] = 600/0.3
              dictionary["VitaminC"] = 45 //mg
              dictionary["VitaminE"] = 11 //mg
              dictionary["VitaminK"] = 60 //mg
              dictionary["Iron"] = 16.3 //mg
              dictionary["Calcium"] = 1300
              dictionary["Magnesium"] = 240 //mcg
            
        } else if (age <= 18){
            dictionary["B6"] = 1.3
            dictionary["Folate"] = 400
             dictionary["VitaminA"] = 600/0.3
            dictionary["VitaminC"] = 75
            dictionary["VitaminK"] = 75
            dictionary["VitaminE"] = 15
            dictionary["Calcium"] = 1300
            dictionary["Iron"] = 16.3
            dictionary["Magnesium"] = 410
        }  else {
            dictionary["B1"]=1.2
            dictionary["B2"]=1.3
            dictionary["B6"]=1.5
            dictionary["B12"]=2.4
            dictionary["Folate"] = 400
            dictionary["VitaminA"]=900/0.3
            dictionary["VitaminC"] = 90
            dictionary["VitaminE"] = 15
            dictionary["VitaminK"] = 120
            dictionary["Calcium"] = 1200
            dictionary["Iron"] = 20.5
            dictionary["Magnesium"] = 420
        }
        dictionary["B3"] = 16
        dictionary["B5"] = 5
        dictionary["Zinc"] = 14
    }
    let proteinIntake: Double = Double(0.8 * weight)
    dictionary["Protein"] = proteinIntake
    let carbs: Double = 0.55 * (dictionary["Energy"] ?? 0.0) / 4
    dictionary["Carbs"] = carbs
    dictionary["Fat"] = 0.275 * (dictionary["Energy"] ?? 0.0) / 7
    dictionary["VitaminD"] = 600
    dictionary["Copper"] = 0.9 //mcg
    dictionary["Manganese"] = 3.4
    dictionary["Potassium"] = 4700
    dictionary["Phosphorus"] = 700
    //Se in mcg
    dictionary["Selenium"] = 55
    dictionary["Sodium"] = 2300
    dictionary["Zinc"] = 13
    return dictionary
}

// inputs the cards into the table view in ViewController view
extension ViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NutritionCards", for: indexPath) as! NutritionCards
        let card = cards[indexPath.row]
        print(card.nutritionLabel)
        let currentProgress = round(storedNutrientDataDict[card.nutritionLabel]!.nutrProgress * 10) / 10
        let currentTarget = round(nutrientTargets[card.nutritionLabel]! * 10) / 10
        cell.nutritionProgressLabel.text = String(currentProgress) + "/" + String(currentTarget)
        cell.nutritionTitleLabel?.text = card.nutritionLabel
        cell.nutritionProgressView?.progress = Float(card.progressPercent)
        cell.nutritionProgressView?.progressTintColor = card.color
        return cell
    }
}

// Random Color Generator
// Source: stackoverflow.com/questions/29779128/how-to-make-a-random-color-with-swift
extension CGFloat{
    static func random() -> CGFloat {
        return CGFloat (arc4random())/CGFloat(UInt32.max)
    }
}
extension UIColor{
    static func random() -> UIColor{
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1.0)
    }
}
