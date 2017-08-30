
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
    
    var currentVariable : String {
        get {
            return calculatorVariable!.keys.first!
        }
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
    
    private var currentMathExpression : MathOperation?
    
    private var pendingMathExpression : MathOperation?
    
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
                currentMathExpression = MathOperation.value(Value.number(value))
            case .unaryOperation(let function, let descriptionFunction):
                if accumulator != nil && currentMathExpression != nil {
                    accumulator = function(accumulator!)
                    currentMathExpression = MathOperation.unaryOperation(currentMathExpression!, function)
                }
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .binaryOperation(let function, let descriptionFunction, let precedence):
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
            // save the binary operation
            currentMathExpression = MathOperation.binaryOperation(pendingBinaryOperation!.mathExpression, //retrieving first operand
                                                                  currentMathExpression!, // storing 2nd operand
                                                                  pendingBinaryOperation!.binaryFunction) // preserving type of operation it was
            descriptionAccumulator = pendingBinaryOperation!.descriptionFunction(
                pendingBinaryOperation!.descriptionOperand, descriptionAccumulator)
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
        case value(Value)
        // stores binary operations
        case binaryOperation(MathOperation, MathOperation, (Double, Double) -> Double)
        // stores unary operations
        case unaryOperation(MathOperation, (Double) -> Double)
    }
    
    mutating func evaluate(using variables: Dictionary<String, Double>? = nil)
            -> (result: Double?, isPending: Bool, description: String) {
        if let variables = variables {
            calculatorVariable?[currentVariable] = variables[currentVariable]!
            return (compute(currentMathExpression!), resultIsPending, description)
        }
        return (compute(currentMathExpression!), resultIsPending, description)
    }
    
    private func compute(_ expression: MathOperation) -> Double {
        switch(expression) {
        // obtained value of the variable or constant
        case .value(let innerValue):
            switch (innerValue) {
            case .number(let doubleValue):
                return doubleValue
            case .variable:
                return (calculatorVariable?[currentVariable])!
            }
        case .unaryOperation(let mathExpression, let unaryFunction):
            return unaryFunction(compute(mathExpression))
        case .binaryOperation(let leftExpression, let rightExpression, let binaryFunction):
            return binaryFunction(compute(leftExpression), compute(rightExpression))
        }
    }
    
    mutating func setOperand(variable named: String) {
        calculatorVariable = [ named : 0 ]
        currentMathExpression = MathOperation.value(Value.variable(calculatorVariable!))
        descriptionAccumulator = named
    }
    

    mutating func setOperand(_ operand: Double) {
        accumulator = operand
        currentMathExpression = MathOperation.value(Value.number(operand))
        descriptionAccumulator = String(operand)
    }
    
    var result : Double? {
        get {
            return accumulator
        }
    }
}









