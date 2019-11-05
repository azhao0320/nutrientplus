//
//  ViewController.swift
//  Nutrient+
//
//  Created by Robert Sato on 10/11/19.
//  Copyright © 2019 Robert Sato. All rights reserved.
//

import UIKit

struct Card {
    var nutritionLabel : String
    var progressPercent : Float
    var color : UIColor
}

class NutritionCards: UITableViewCell {
    @IBOutlet weak var nutritionProgressView: UIProgressView!
    @IBOutlet weak var nutritionTitleLabel: UILabel!
}

class ViewController: UIViewController {	
    @IBOutlet weak var tableView: UITableView!
    var cards: [Card] = []
    var height : Float=0.0
    var weight :Float=0.0
    var calories = "2000"
    var tester :String="did not change"
    var gender : String = ""
    
    // for transfering data
    @IBOutlet weak var transferDataLabel: UILabel!
    
    //for initializing nutrients
    let macros = ["Energy", "Protein", "Carbs", "Fat"]
    let vitamins = ["B1", "B2", "B3", "B5", "B6", "B12",
                     "B12", "Folate", "Vitamin A", "Vitamin C",
                     "Vitamin D", "Vitamin E", "Vitamin K"]
    let minerals = ["Calcium", "Copper", "Iron", "Magnesium",
                    "Manganese", "Phosphorus", "Potassium",
                    "Selenium", "Sodium", "Zinc"]
    //nutrients stores daily nutritional data
    var nutrients = [String: Float]()
    //nutrientTargets stores the daily targets
    var nutrientTargets = [String: Float]()
    var targetsEdited = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        transferDataLabel.text = calories
        tableView.delegate = self
        tableView.dataSource = self
        if !targetsEdited {//if nutrient targets werent edited in EditInfoVC
            print("Reseting nutrients and creating targets;targetsEdited = false")
            //reset nutrient progress and create the target goals
            resetNutrients()
            createTargets()
        }
        cards = populate()
        print("height is equal to ----------> ", height)
        print("weight is equal to ----------> ", weight)
        print("gender is equal to ----------> ", gender)
        let ans=calculate(weight: weight, gender: gender)
        print(ans)
        
        //print("Printing targets in ViewController.swift")
        //printTargets()
    }
    
    func resetNutrients() {
        for item in macros {
            nutrients[item] = 0
        }
        for item in vitamins {
            nutrients[item] = 0
        }
        for item in minerals {
            nutrients[item] = 0
        }
    }
    
    func createTargets() {
        for item in macros {
            nutrientTargets[item] = 200
        }
        for item in vitamins {
            nutrientTargets[item] = 10
        }
        for item in minerals {
            nutrientTargets[item] = 5
        }
    }
    
    func printTargets() {
        print("Macros")
        for item in macros {
            print("nutrientTargets[\(item)]: \(nutrientTargets[item] ?? -1)")
        }
        print("Vitamins")
        for item in vitamins {
            print("nutrientTargets[\(item)]: \(nutrientTargets[item] ?? -1)")
        }
        print("Minerals")
        for item in minerals {
            print("nutrientTargets[\(item)]: \(nutrientTargets[item] ?? -1)")
        }
    }
    
    func populate() -> [Card] {
        
        //create an array of Card
        var tempCards: [Card] = []
        
        
        var card: Card
        print("Populate: Macros")
        for item in macros {
            print("nutrients[\(item)]: \(nutrients[item] ?? 0)")
            print("nutrientTargets[\(item)]: \(nutrientTargets[item] ?? 0)")
            //set the card to a macro, look up the value in nutrients dictionary, give random color
            //this is not the right calculation for progress
            card = Card(nutritionLabel: item, progressPercent: (nutrients[item] ?? 0) / (nutrientTargets["Energy"] ?? 2000), color: .random())
            tempCards.append(card)
        }
        print("Populate: Vitamins")
        for item in vitamins {
            print("nutrients[\(item)]: \(nutrients[item] ?? 0)")
            print("nutrientTargets[\(item)]: \(nutrientTargets[item] ?? 0)")
            //set the card to a vitamin, look up the value in nutrients dictionary, give random color
            card = Card(nutritionLabel: item, progressPercent: ((nutrients[item] ?? 0) / (nutrientTargets[item] ?? 10)), color: .random())
            tempCards.append(card)
        }
        print("Populate: Minerals")
        for item in minerals {
            print("nutrients[\(item)]: \(nutrients[item] ?? 0)")
            print("nutrientTargets[\(item)]: \(nutrientTargets[item] ?? 0)")
            //set the card to a mineral, look up the value in nutrients dictionary, give random color
            card = Card(nutritionLabel: item, progressPercent: ((nutrients[item] ?? 0) / (nutrientTargets[item] ?? 5)), color: .random())
            tempCards.append(card)
        }
        return tempCards
    }
    
    //for sending data over segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is EditInfoVC
        {
            let vc = segue.destination as? EditInfoVC
            vc?.nutrientTargets = self.nutrientTargets
        }
    }
    
}
func calculate(weight : Float,gender : String  )->NSInteger{
    if(gender=="Female"){
        let ans=0.9*weight*24
        let intAns:Int = Int(ans)
        return intAns
    }
    else{
        let ans=1*weight*24
        let intAns:Int = Int(ans)
        return intAns
    }
    
}


extension ViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NutritionCards", for: indexPath) as! NutritionCards
        let card = cards[indexPath.row]
        cell.nutritionTitleLabel?.text = card.nutritionLabel
        cell.nutritionProgressView?.progress = card.progressPercent
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
