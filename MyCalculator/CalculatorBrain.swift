
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
        let symbol: String
        let binaryFunction: (Double, Double) -> Double
        let firstOperand: Double
        
        func perform(with secondOperand: Double) -> Double {
            return binaryFunction(firstOperand, secondOperand)
        }
    }
    
    private var memoryStack = Array<Double>()
    
    private var pendingBinaryOperation: PendingBinaryOperation?
    
    private var accumulator : Double?
    
    // last operator invoked
    private var currentOperator : String?
    
    // tracks wether brain is performing an operation
    private var currentlyPerformingOperation : Bool = false
    
    var chainedUnaryOperation : Bool = false

    var resultIsPending: Bool {
        get {
            return pendingBinaryOperation != nil ? true : false
        }
    }
    
    var isUnaryOperation : Bool {
        get {
            if currentOperator != nil {
                let operationType = operations[currentOperator!]!
                switch operationType {
                case .unaryOperation:
                    return true
                default:
                    break
                }
            }
            return false
        }
    }
    
    var isEqualsOperation : Bool {
        get {
            if currentOperator != nil {
                let operationType = operations[currentOperator!]!
                switch operationType {
                case .equals:
                    return true
                default:
                    break
                }
            }
            return false
        }
    }

    var isClearOperation : Bool {
        get {
            if currentOperator != nil {
                let operationType = operations[currentOperator!]!
                switch operationType {
                case .clear:
                    return true
                default:
                    break
                }
            }
            return false
        }
    }
    
    var isBracketOperation : Bool {
        get {
            if currentDescription != nil {
                if currentOperator != nil {
                    let operationType = operations[currentOperator!]!
                    switch operationType {
                    case .binaryOperation:
                        return true
                    case .unaryOperation:
                        return true
                    default:
                        break
                    }
                }
            }
            return false
        }
    }
    
    // allows conversion from Double to String symbol for some constants
    // for display purposes in the description
    private var constants =
    [
        Double.pi : "π",
        M_E : "e"
    ]

    // the 'get' displays the sequence of operations that will eventually modify the currentDescription
    private var currentDescription: String?
    var description: String? {
        get {
            if currentDescription != nil {
                if !currentlyPerformingOperation && !resultIsPending {
                    return currentDescription
                }
                if resultIsPending {
                    // cannot use the last operator because other operations may have occured since
                    // the pending binary operation (ex addition then square root!)
                    if chainedUnaryOperation {
                        // if this is unary operation inside pending operation then we already have the binary symbol
                        // as part of the description since description is updated during unary operation
                        return currentDescription!
                    } else {
                        return "\(currentDescription!) \(pendingBinaryOperation!.symbol)"
                    }
                } else if isUnaryOperation {
                    return "\(currentOperator!)\(currentDescription!)"
                } else {
                    return currentDescription
                }
            } else {
                // base case before any operations are performed
                
                let tempAccumulator : String? = accumulator != nil ? ( constants[accumulator!] ?? String(accumulator!) ) : nil
                if resultIsPending {
                    if isUnaryOperation {
                        // performed unary operation during binary operation
                        return "\(pendingBinaryOperation!.firstOperand) \(pendingBinaryOperation!.symbol) \(currentOperator!)\(tempAccumulator!)"
                    }
                    // cannot use the last operator because other operations may have occured since
                    // the pending binary operation (ex addition then square root!)
                    return "\(pendingBinaryOperation!.firstOperand) \(pendingBinaryOperation!.symbol)"
                } else if isUnaryOperation {
                    return "\(currentOperator!)\(tempAccumulator!)"
                } else {
                    return "\(tempAccumulator!)"
                }
            }
        }
    }
    
    private enum OperationType {
        case constant(Double)
        case unaryOperation((Double) -> Double)
        case binaryOperation((Double, Double) -> Double)
        case clear((Double?) -> Double)
        case memoryPop
        case memoryAdd
        case equals
    }
    
    private var operations =
    [
        "π"     : OperationType.constant(Double.pi),
        "e"     : OperationType.constant(M_E),
        "√"     : OperationType.unaryOperation(sqrt),
        "x²"    : OperationType.unaryOperation({ $0 ** 2 }),
        "sin"   : OperationType.unaryOperation(sin),
        "cos"   : OperationType.unaryOperation(cos),
        "tan"   : OperationType.unaryOperation(tan),
        "±"     : OperationType.unaryOperation({ -$0 }),
        "CE"    : OperationType.clear(clearDisplay),
        "←"     : OperationType.clear(backspace),
        "M+"    : OperationType.memoryAdd,
        "MR"    : OperationType.memoryPop,
        "+"     : OperationType.binaryOperation({ $0 + $1 }),
        "-"     : OperationType.binaryOperation({ $0 - $1 }),
        "×"     : OperationType.binaryOperation({ $0 * $1 }),
        "÷"     : OperationType.binaryOperation({ $0 / $1 }),
        "EE"    : OperationType.binaryOperation({ $0 * (10**$1) }),
        "="     : OperationType.equals
    ]
    
    // Called by Controller when user clicks a mathematical operation
    mutating func performOperation(_ symbol: String) {
        currentlyPerformingOperation = true
        if let operationType = operations[symbol] {
            currentOperator = symbol
            
            // the current Description is modified when '=' is performed 
            // or unary operation is performed when no binary operation pending
            // or clear operaiton is performed
            updateDescription()

            switch operationType {
            case .constant(let value):
                accumulator = value
            case .unaryOperation(let function):
                if accumulator != nil {
                    accumulator = function(accumulator!)
                }
            case .binaryOperation(let function):
                if accumulator != nil {
                    pendingBinaryOperation = PendingBinaryOperation(symbol: symbol,
                        binaryFunction: function, firstOperand: accumulator!)
                    accumulator = nil
                }
            case .clear(let clearFunction):
                accumulator = clearFunction(accumulator)
            case .memoryAdd:
                if accumulator != nil {
                    memoryStack.append(accumulator!)
                }
            case .memoryPop:
                if let element = memoryStack.popLast() {
                    accumulator = element
                }
            case .equals:
                performPendingBinaryOperation()
            }
        }
        currentlyPerformingOperation = false
    }
    
    // accumulator currently stores contents of second operand
    mutating func performPendingBinaryOperation() {
        if accumulator != nil && pendingBinaryOperation != nil {
            accumulator = pendingBinaryOperation!.perform(with: accumulator!)
            pendingBinaryOperation = nil
        }
    }
    
    mutating private func updateDescription() {
        if isBracketOperation {
            // modify the current description directly since this is an aesthetic change
            currentDescription = "(\(currentDescription!))"
        }
        
        if (resultIsPending && isUnaryOperation) {
            currentDescription = description!
            chainedUnaryOperation = true
        } else if (isUnaryOperation) {
            currentDescription = description!
        }
        
        if isEqualsOperation {
            let tempAccumulator = constants[accumulator!] ?? String(accumulator!)
            currentDescription = chainedUnaryOperation ? description! : description! + " \(tempAccumulator)"
            chainedUnaryOperation = false
        }
        if isClearOperation {
            currentDescription = nil
        }
    }

    mutating func setOperand(_ operand: Double) {
        accumulator = operand
    }
    
    var result : Double? {
        get {
            return accumulator
        }
    }
}









