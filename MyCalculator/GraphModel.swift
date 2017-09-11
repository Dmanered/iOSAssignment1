//
//  GraphModel.swift
//  MyCalculator
//
//  Created by Anglinov, Dmitry on 9/6/17.
//  Copyright © 2017 Anglinov, Dmitry. All rights reserved.
//

import Foundation

class GraphModel {
    var functionToGraph : ((Double) -> Double)?
    
    var initialY : Double = 0
    
    init() {
        functionToGraph = nil
        initialY = 0
    }
    
    init(functionToGraph: @escaping (Double) -> Double, initialY : Double) {
        self.functionToGraph = functionToGraph
        self.initialY = initialY
    }
}


