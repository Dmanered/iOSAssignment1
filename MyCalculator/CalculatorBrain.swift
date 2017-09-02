
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

struct CalculatorBrain {
    
    private struct PendingBinaryOperation {
        let binaryFunction: (Double, Double) -> Double
        let firstOperand: Double
        let mathExpression : MathOperation
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
    
    private var calculatorVariable : [String:Double]?
    
    private var currentMathExpression : MathOperation?
    
    private var pendingMathExpression : MathOperation?
    
    var currentVariable : String {
        return calculatorVariable!.keys.first!
    }
    
    
    var resultIsPending: Bool {
        get {
            return pendingBinaryOperation != nil ? true : false
        }
    }

    var description: String {
        get {
            if resultIsPending {
                var tempSecondOperand = ""
                if pendingBinaryOperation!.descriptionOperand != descriptionAccumulator {
                    tempSecondOperand = descriptionAccumulator
                }
                return pendingBinaryOperation!.descriptionFunction(pendingBinaryOperation!.descriptionOperand, tempSecondOperand)
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
        calculatorVariable = nil
    }
    
    mutating func undoOperation() {
        currentMathExpression = currentMathExpression?.getPreviousOperation()
        descriptionAccumulator = currentMathExpression != nil ? currentMathExpression!.getDescription() : "0"
        accumulator = currentMathExpression != nil ? compute(currentMathExpression!) : 0
        currentPrecedence = currentMathExpression != nil ? (currentMathExpression!.getPrecedence() ?? Precedence.Max) : Precedence.Max
        pendingBinaryOperation = nil
    }
    
    // Called by Controller when user clicks a mathematical operation
    mutating func performOperation(_ symbol: String) {
        if let operationType = operations[symbol] {
            switch operationType {
            case .constant(let value):
                accumulator = value
                descriptionAccumulator = symbol
                currentMathExpression = MathOperation.value(Value.number(value), descriptionAccumulator)
            case .unaryOperation(let function, let descriptionFunction):
                if accumulator != nil && currentMathExpression != nil {
                    descriptionAccumulator = descriptionFunction(descriptionAccumulator)
                    accumulator = function(accumulator!)
                    currentMathExpression = MathOperation.unaryOperation(currentMathExpression!, function, descriptionAccumulator)
                }
            case .binaryOperation(let function, let descriptionFunction, let precedence):
                if accumulator != nil && currentMathExpression != nil {
                    if currentPrecedence.rawValue < precedence.rawValue {
                        descriptionAccumulator = "(\(descriptionAccumulator))"
                        
                    }
                    currentPrecedence = precedence
                    
                    // preserve the operand, which may be nested operations
                    pendingMathExpression = currentMathExpression
                    
                    pendingBinaryOperation = PendingBinaryOperation(
                        binaryFunction: function,
                        firstOperand: accumulator!,
                        mathExpression: pendingMathExpression!,
                        descriptionOperand: descriptionAccumulator,
                        descriptionFunction: descriptionFunction)
                    
                    // we now always want this to have a value
                    accumulator = 0
                }
            case .equals:
                performPendingBinaryOperation()
            }
        }
    }
    
    // accumulator currently stores contents of second operand
    mutating func performPendingBinaryOperation() {
        if pendingBinaryOperation != nil {
            // perform the binary operation
            accumulator = pendingBinaryOperation!.perform(with: accumulator!)
            // obtain new description
            descriptionAccumulator = pendingBinaryOperation!.descriptionFunction(
                pendingBinaryOperation!.descriptionOperand, descriptionAccumulator)
            // save the binary operation
            currentMathExpression = MathOperation.binaryOperation(pendingBinaryOperation!.mathExpression, //retrieving first operand
                                                                  currentMathExpression!, // storing 2nd operand
                                                                  pendingBinaryOperation!.binaryFunction, // preserving type of operation it was
                                                                  descriptionAccumulator, // used for undo
                                                                  currentPrecedence)
            pendingBinaryOperation = nil
            pendingMathExpression = nil
        }

    }
    
    private enum Value {
        case number(Double)
        case variable([String:Double])
    }
    
    private indirect enum MathOperation {
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
    
    mutating func evaluate(using variables: Dictionary<String, Double>? = nil)
            -> (result: Double?, isPending: Bool, description: String) {
        if let variables = variables {
            calculatorVariable?[currentVariable] = variables[currentVariable]!
            accumulator = compute(currentMathExpression!)
            // currentMathExpression = MathOperation.value(Value.number(accumulator!), description)
            return (accumulator, resultIsPending, description)
        }
        if let mathExpression = currentMathExpression {
            accumulator = compute(mathExpression)
        }
        return (accumulator, resultIsPending, description)
    }
    
    private func compute(_ expression: MathOperation) -> Double {
        switch(expression) {
        // obtained value of the variable or constant
        case .value(let innerValue, _):
            switch (innerValue) {
            case .number(let doubleValue):
                return doubleValue
            case .variable:
                return (calculatorVariable?[currentVariable])!
            }
        case .unaryOperation(let mathExpression, let unaryFunction, _):
            return unaryFunction(compute(mathExpression))
        case .binaryOperation(let leftExpression, let rightExpression, let binaryFunction, _, _):
            return binaryFunction(compute(leftExpression), compute(rightExpression))
        }
    }
    
    mutating func setOperand(variable named: String) {
        calculatorVariable = [ named : 0 ]
        descriptionAccumulator = named
        currentMathExpression = MathOperation.value(Value.variable(calculatorVariable!), descriptionAccumulator)
    }
    

    mutating func setOperand(_ operand: Double) {
        accumulator = operand
        descriptionAccumulator = String(operand)
        currentMathExpression = MathOperation.value(Value.number(operand), descriptionAccumulator)
    }
    
    
    var result : Double? {
        get {
            return accumulator
        }
    }
}









