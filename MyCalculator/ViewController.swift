//
//  ViewController.swift
//  MyCalculator
//
//  Created by Anglinov, Dmitry on 8/22/17.
//  Copyright © 2017 Anglinov, Dmitry. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let M : String = "M"
    
    private var brain : CalculatorBrain = CalculatorBrain()

    private var userIsInTheMiddleofTyping : Bool = false
    
    private var previousDigit : Int?
    
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
    
    func validateTouchDigitFailed(_ sender: UIButton) -> Bool {
        let digit : String = sender.currentTitle!
        // cannot perform dot operation on a number that is already decimal
        if currentDisplayContainsDot && digit == "." {
            print("cannot perform dot operation on a number that is already decimal")
            return true
        }
        return false
    }
    
    @IBAction func clear(_ sender: UIButton) {
        brain.clear()
        displayValue = brain.result!
        descriptionDisplayValue = brain.description
        userIsInTheMiddleofTyping = false
    }
    
    @IBAction func backspace(_ sender: UIButton) {
        if userIsInTheMiddleofTyping {
            display.text = String(previousDigit!)
            if displayValue == 0 {
                userIsInTheMiddleofTyping = false
            }
        } else {
            brain.undoOperation()
            let (result, resultIsPending, description) = brain.evaluate()
            updateDisplays(result: result, description: description, pending: resultIsPending)
        }
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
        // update the displays
        updateDisplays(result: brain.result, description: brain.description, pending: brain.resultIsPending)
    }
    
    // MR
    // This function declares the variable 'M'
    @IBAction func variableGet(_ sender: UIButton) {
        brain.setOperand(variable: M)
        let (result, resultIsPending, description) = brain.evaluate()
        updateDisplays(result: result, description: description, pending: resultIsPending)
    }
    
    // ->M
    // This function applies displayValue to 'M' and computes the result
    @IBAction func variableSet(_ sender: UIButton) {
        userIsInTheMiddleofTyping = false
        let variables = [M : displayValue]
        let (result, resultIsPending, description) = brain.evaluate(using: variables)
        updateDisplays(result: result, description: description, pending: resultIsPending)
    }
    
    func updateDisplays(result: Double?, description: String, pending resultIsPending: Bool) {
        if result != nil {
            displayValue = result!
        }
        // update the description
        descriptionDisplayValue = description
        if resultIsPending {
            descriptionDisplayValue = descriptionDisplayValue + " ..."
        } else if displayValue != 0 {
            descriptionDisplayValue = descriptionDisplayValue + " ="
        }
    }
}
