//
//  ViewController.swift
//  MyCalculator
//
//  Created by Anglinov, Dmitry on 8/22/17.
//  Copyright © 2017 Anglinov, Dmitry. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private var brain : CalculatorBrain = CalculatorBrain()

    private var userIsInTheMiddleofTyping : Bool = false
    
    @IBOutlet weak var display: UILabel!
    var displayValue : Double {
        get {
            return Double(display.text!)!
        }
        set {
            display.text = String(newValue)
        }
    }
    
    @IBOutlet weak var descriptionDisplay: UILabel!
    var descriptionDisplayValue : String {
        get {
            return descriptionDisplay.text!
        }
        set {
            descriptionDisplay.text = newValue
        }
    }
    
    var currentDisplayContainsDot : Bool {
        get {
            return display.text!.contains(".")
        }
    }
    
    var chainedMathOperation: Bool = false
    
    func validateTouchDigitFailed(_ sender: UIButton) -> Bool {
        let digit : String = sender.currentTitle!
        // cannot perform dot operation on a number that is already decimal
        if currentDisplayContainsDot && digit == "." {
            print("cannot perform dot operation on a number that is already decimal")
            return true
        }
        return false
    }
    
    @IBAction func touchDigit(_ sender: UIButton) {
        if validateTouchDigitFailed(sender) {
            return
        }
        let digit = sender.currentTitle!
        if userIsInTheMiddleofTyping {
            let textCurrentlyInDisplay = display.text!
            display.text = textCurrentlyInDisplay + digit
        } else {
            display.text = digit
            userIsInTheMiddleofTyping = true
            chainedMathOperation = false
        }
    }
    
    // operation that will clear the display
    @IBAction func performOperation(_ sender: UIButton) {
        // User has just entered the 2nd operand for a binary operation
        // or a first operand for a unary operation
        if userIsInTheMiddleofTyping {
            brain.setOperand(displayValue)
        }
        userIsInTheMiddleofTyping = false
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        if let result = brain.result {
            displayValue = result
        }
        // update the description
        if let newDescription = brain.description {
            descriptionDisplayValue = newDescription
            if brain.resultIsPending {
                descriptionDisplayValue = descriptionDisplayValue + " ..."
            } else if brain.isEqualsOperation || brain.chainedUnaryOperation {
                descriptionDisplayValue = descriptionDisplayValue + " ="
            }
        }
    }
}
