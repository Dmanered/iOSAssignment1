//
//  MathOperation.swift
//  MyCalculator
//
//  Created by Anglinov, Dmitry on 9/10/17.
//  Copyright © 2017 Anglinov, Dmitry. All rights reserved.
//

import Foundation

enum Precedence: Int {
    case Min = 0, Max
}

enum OperationType {
    case constant(Double)
    case unaryOperation((Double) -> Double, (String) -> String)
    case binaryOperation((Double, Double) -> Double, (String, String) -> String, Precedence)
    case equals
}

enum Value {
    case number(Double)
    case variable([String:Double])
}

indirect enum MathOperation {
    // stores value of the variable or constant
    case value(Value, String)
    // stores binary operations
    case binaryOperation(MathOperation, MathOperation, (Double, Double) -> Double, String, Precedence)
    // stores unary operations
    case unaryOperation(MathOperation, (Double) -> Double, String)
    
    func getPreviousOperation() -> MathOperation? {
        switch(self) {
        // there is no previous operation
        case .value:
            return nil
        // previous operation would be the operand to the unary operation
        case .unaryOperation(let mathExpression, _, _):
            return mathExpression
        // previous operation would be the left operand to the binary operation
        case .binaryOperation(let leftExpression, _, _, _, _):
            return leftExpression
        }
    }
    
    func getDescription() -> String {
        switch(self) {
        case .value(_, let description):
            return description
        case .unaryOperation(_, _, let description):
            return description
        case .binaryOperation(_, _, _, let description, _):
            return description
        }
    }
    
    func getPrecedence() -> Precedence? {
        switch(self) {
        case .value:
            return nil
        case .unaryOperation:
            return nil
        case .binaryOperation(_, _, _, _, let precedence):
            return precedence
        }
    }
}
