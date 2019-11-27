//
//  NutrientStruct.swift
//  NutrientPlus
//
//  Created by DSCommons on 11/22/19.
//  Copyright © 2019 hoo. All rights reserved.
//

import Foundation

class NutrientStruct {
    var nutrName: String
    var nutrWeight: Double
    var nutrTarget: Double
    var nutrProgress: Double

    init(nutrName: String) {
        self.nutrName = nutrName
        nutrWeight = 0
        nutrTarget = 0
        nutrProgress = 0
    }

    init(nutrName: String, nutrWeight: Double, nutrTarget: Double, nutrProgress: Double) {
        self.nutrName = nutrName
        self.nutrWeight = nutrWeight
        self.nutrTarget = nutrTarget
        self.nutrProgress = nutrProgress
    }
}
