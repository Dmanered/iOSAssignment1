
//
//  ControllerBrain.swift
//  MyCalculator
//
//  Created by Anglinov, Dmitry on 8/22/17.
//  Copyright © 2017 Anglinov, Dmitry. All rights reserved.
//

import Foundation

infix operator ** : MultiplicationPrecedence

func ** (num: Double, power: Double) -> Double {
    return pow(num, power)
}

func clearDisplay(operand: Double?) -> Double {
    return 0
}

func backspace(operand: Double?) -> Double {
    if operand != nil {
        let displayValue = String(Int(operand!))
        let secondLastCharacter = displayValue.index(displayValue.endIndex, offsetBy: -1)
        let newDisplayValue : String = displayValue.substring(to: secondLastCharacter)
        if !newDisplayValue.isEmpty {
            return Double(newDisplayValue)!
        }
    }
    return 0
}


struct CalculatorBrain {
    
    struct PendingBinaryOperation {
        let binaryFunction: (Double, Double) -> Double
        let firstOperand: Double
        let descriptionOperand : String
        let descriptionFunction : (String, String) -> String

        func perform(with secondOperand: Double) -> Double {
            return binaryFunction(firstOperand, secondOperand)
        }
    }
    
    private var currentPrecedence = Precedence.Max
    
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    private var accumulator : Double?
    
    private var descriptionAccumulator : String = "0"
    
    var resultIsPending: Bool {
        get {
            return pendingBinaryOperation != nil ? true : false
        }
    }

    var description: String {
        get {
            if resultIsPending {
                return pendingBinaryOperation!.descriptionFunction(pendingBinaryOperation!.descriptionOperand, "")
            } else {
                return descriptionAccumulator
            }
        }
    }
    
    private enum Precedence: Int {
        case Min = 0, Max
    }
    
    private var operations =
    [
        "π"     : OperationType.constant(Double.pi),
        "e"     : OperationType.constant(M_E),
        "√"     : OperationType.unaryOperation(sqrt, { "√(\($0))"}),
        "x²"    : OperationType.unaryOperation({ $0 ** 2 }, { "(\($0))²"}),
        "sin"   : OperationType.unaryOperation(sin, { "sin(\($0))"}),
        "cos"   : OperationType.unaryOperation(cos, { "cos(\($0))"}),
        "tan"   : OperationType.unaryOperation(tan, { "tan(\($0))"}),
        "±"     : OperationType.unaryOperation({ -$0 }, { "-(\($0))"}),
        "+"     : OperationType.binaryOperation({ $0 + $1 }, { "\($0) + \($1)"}, Precedence.Min),
        "-"     : OperationType.binaryOperation({ $0 - $1 }, { "\($0) - \($1)"}, Precedence.Min),
        "×"     : OperationType.binaryOperation({ $0 * $1 }, { "\($0) × \($1)"}, Precedence.Max),
        "÷"     : OperationType.binaryOperation({ $0 / $1 }, { "\($0) ÷ \($1)"}, Precedence.Max),
        "EE"    : OperationType.binaryOperation({ $0 * (10**$1) }, { "\($0) EE \($1)"}, Precedence.Max),
        "="     : OperationType.equals
    ]
    
    
    private enum OperationType {
        case constant(Double)
        case unaryOperation((Double) -> Double, (String) -> String)
        case binaryOperation((Double, Double) -> Double, (String, String) -> String, Precedence)
        case equals
    }
    
    mutating func clear() {
        descriptionAccumulator = "0"
        accumulator = 0
        currentPrecedence = Precedence.Max
        pendingBinaryOperation = nil
    }
    
    // Called by Controller when user clicks a mathematical operation
    mutating func performOperation(_ symbol: String) {
        if let operationType = operations[symbol] {
            switch operationType {
            case .constant(let value):
                accumulator = value
                descriptionAccumulator = symbol
            case .unaryOperation(let function, let descriptionFunction):
                if accumulator != nil {
                    accumulator = function(accumulator!)
                    descriptionAccumulator = descriptionFunction(descriptionAccumulator)
                }
            case .binaryOperation(let function, let descriptionFunction, let precedence):
                if accumulator != nil {
                    if currentPrecedence.rawValue < precedence.rawValue {
                        descriptionAccumulator = "(\(descriptionAccumulator))"
                    }
                    currentPrecedence = precedence

                    pendingBinaryOperation = PendingBinaryOperation(
                                               binaryFunction: function,
                                               firstOperand: accumulator!,
                                               descriptionOperand: descriptionAccumulator,
                                               descriptionFunction: descriptionFunction)
                    accumulator = nil
                }
            case .equals:
                performPendingBinaryOperation()
            }
        }
    }
    
    // accumulator currently stores contents of second operand
    mutating func performPendingBinaryOperation() {
        if accumulator != nil && pendingBinaryOperation != nil {
            accumulator = pendingBinaryOperation!.perform(with: accumulator!)
            descriptionAccumulator = pendingBinaryOperation!.descriptionFunction(
                                        pendingBinaryOperation!.descriptionOperand, descriptionAccumulator)
            pendingBinaryOperation = nil
        }
    }
    

    mutating func setOperand(_ operand: Double) {
        accumulator = operand
        descriptionAccumulator = String(operand)
    }
    
    var result : Double? {
        get {
            return accumulator
        }
    }
}









