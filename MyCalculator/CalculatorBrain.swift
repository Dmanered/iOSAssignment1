
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
    
    mutating func clear() {
        descriptionAccumulator = "0"
        currentPrecedence = Precedence.Max
        pendingBinaryOperation = nil
        calculatorVariable = nil
        currentMathExpression = nil
        pendingMathExpression = nil
    }
    
    mutating func undoOperation() {
        currentMathExpression = currentMathExpression?.getPreviousOperation()
        descriptionAccumulator = currentMathExpression != nil ? currentMathExpression!.getDescription() : "0"
        currentPrecedence = currentMathExpression != nil ? (currentMathExpression!.getPrecedence() ?? Precedence.Max) : Precedence.Max
        pendingBinaryOperation = nil
    }
    
    // Called by Controller when user clicks a mathematical operation
    mutating func performOperation(_ symbol: String) {
        if let operationType = operations[symbol] {
            switch operationType {
            case .constant(let value):
                descriptionAccumulator = symbol
                currentMathExpression = MathOperation.value(Value.number(value), descriptionAccumulator)
            case .unaryOperation(let function, let descriptionFunction):
                if currentMathExpression != nil {
                    descriptionAccumulator = descriptionFunction(descriptionAccumulator)
                    currentMathExpression = MathOperation.unaryOperation(currentMathExpression!, function, descriptionAccumulator)
                }
            case .binaryOperation(let function, let descriptionFunction, let precedence):
                if currentMathExpression != nil {
                    if currentPrecedence.rawValue < precedence.rawValue {
                        descriptionAccumulator = "(\(descriptionAccumulator))"
                        
                    }
                    currentPrecedence = precedence
                    
                    // preserve the operand, which may be nested operations
                    pendingMathExpression = currentMathExpression
                    
                    let firstOperand = result!
                    
                    pendingBinaryOperation = PendingBinaryOperation(
                        binaryFunction: function,
                        firstOperand: firstOperand,
                        mathExpression: pendingMathExpression!,
                        descriptionOperand: descriptionAccumulator,
                        descriptionFunction: descriptionFunction)
                }
            case .equals:
                performPendingBinaryOperation()
            }
        }
    }
    
    // accumulator currently stores contents of second operand
    mutating func performPendingBinaryOperation() {
        if pendingBinaryOperation != nil {
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
    
    func evaluate(using variables: Dictionary<String, Double>? = nil)
            -> (result: Double, isPending: Bool, description: String) {
        var result : Double = 0
        if let variables = variables {
            if let mathExpression = currentMathExpression {
                result = compute(mathExpression, variableValue: variables[currentVariable]!)
            }
            return (result, resultIsPending, description)
        }
        if let mathExpression = currentMathExpression {
            let currentValue = calculatorVariable != nil ? calculatorVariable![currentVariable]! : 0
            result = compute(mathExpression, variableValue: currentValue)
        }
        return (result, resultIsPending, description)
    }
    
    private func compute(_ expression: MathOperation, variableValue : Double) -> Double {
        switch(expression) {
        // obtained value of the variable or constant
        case .value(let innerValue, _):
            switch (innerValue) {
            case .number(let doubleValue):
                return doubleValue
            case .variable:
                return variableValue
            }
        case .unaryOperation(let mathExpression, let unaryFunction, _):
            return unaryFunction(compute(mathExpression, variableValue: variableValue))
        case .binaryOperation(let leftExpression, let rightExpression, let binaryFunction, _, _):
            return binaryFunction(compute(leftExpression, variableValue: variableValue), compute(rightExpression, variableValue: variableValue))
        }
    }
    
    mutating func setOperand(variable named: String) {
        calculatorVariable = [ named : 0 ]
        descriptionAccumulator = named
        currentMathExpression = MathOperation.value(Value.variable(calculatorVariable!), descriptionAccumulator)
    }
    
    mutating func setVariable(with variable: Double) {
        calculatorVariable?[currentVariable] = variable
    }

    mutating func setOperand(_ operand: Double) {
        descriptionAccumulator = String(operand)
        currentMathExpression = MathOperation.value(Value.number(operand), descriptionAccumulator)
    }
    
    var result : Double? {
        let (result, _, _) = evaluate()
        return result
    }
}









