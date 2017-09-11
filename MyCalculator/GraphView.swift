//
//  GraphView.swift
//  MyCalculator
//
//  Created by Anglinov, Dmitry on 9/6/17.
//  Copyright © 2017 Anglinov, Dmitry. All rights reserved.
//

import UIKit

class GraphView: UIView {
    
    let MIN_SCALE : CGFloat = 5.0
    
    // how many pixels per unit double
    @IBInspectable
    var scale : CGFloat = 25 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // how many function calls to move 1 unit (AKA how many points per unit we will draw)
    @IBInspectable
    var resolution : Double = 100
    
    var functionToGraph : ((Double) -> Double)?
    
    var initialY : Double = 0
    
    func getCenter() -> CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    override func draw(_ rect: CGRect) {
        let center : CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let axesDrawer : AxesDrawer = AxesDrawer()
        axesDrawer.drawAxes(in: rect, origin: center, pointsPerUnit: scale)
        let origin = CGPoint(x: center.x, y: center.y - CGFloat(initialY)*scale)
        if functionToGraph != nil {
            drawContinuousFunction(from: origin, using: functionToGraph!)
        }
    }
    
    func changeScale(byReactingTo pinchRecognizer: UIPinchGestureRecognizer) {
        switch(pinchRecognizer.state) {
        case .changed, .ended:
            let newScale = pinchRecognizer.scale * scale
            scale = max(MIN_SCALE, newScale)
            pinchRecognizer.scale = 1
        default:
            break
        }
    }
    
    func drawContinuousFunction(from origin: CGPoint, using function: (Double) -> Double) {
        let rightmostViewBoundary = bounds.width
        let leftmostViewBoundary = bounds.minX
        let center : CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let initialOperand = Double((origin.x - center.x) / scale)

        // moving right from origin
        var currentPoint : CGPoint = origin
        var currentOperand : Double = initialOperand
        let righDotPath = UIBezierPath()
        righDotPath.move(to: origin)
        while (currentPoint.x < rightmostViewBoundary)
        {
            // destination will move a minimum of 1 'scale' unit each time
            // We will draw 'resolution' number of points to reach the destinationOperand
            let destinationXPoint : CGFloat = currentPoint.x + scale
            let destinationOperand = Double((abs(destinationXPoint - currentPoint.x)) / scale) + currentOperand
            let operandStep = abs(destinationOperand / resolution)
            let graphStep = abs(CGFloat(operandStep) * scale)
            while (currentOperand < destinationOperand)
            {
                // get new point and draw it
                currentOperand = currentOperand + operandStep
                // center.y is the y = 0 line. We subtract to go up on the y axis
                let newYCoordinate = center.y - (CGFloat(function(currentOperand)) * scale)
                currentPoint = CGPoint(x: currentPoint.x + graphStep, y: newYCoordinate)
                righDotPath.addLine(to: currentPoint)

            }
            // 1 scale = 1 Double so this needs to be a whole number at the end
            currentOperand = round(currentOperand)
        }
        
        // moving left from origin
        currentPoint = origin
        currentOperand = initialOperand
        let leftDotPath = UIBezierPath()
        leftDotPath.move(to: origin)
        while (currentPoint.x > leftmostViewBoundary)
        {
            // destination will move a minimum of 1 'scale' unit each time
            // We will draw 'resolution' number of points to reach the destinationOperand
            let destinationXPoint : CGFloat = currentPoint.x - scale
            let destinationOperand = currentOperand - Double((abs(destinationXPoint - currentPoint.x)) / scale)
            let operandStep = abs(destinationOperand / resolution)
            let graphStep = abs(CGFloat(operandStep) * scale)
            while (currentOperand > destinationOperand)
            {
                // get new point and draw it
                currentOperand = currentOperand - operandStep // moving left
                // center.y is the y = 0 line. We subtract to go up on the y axis
                let newYCoordinate = center.y - (CGFloat(function(currentOperand)) * scale)
                currentPoint = CGPoint(x: currentPoint.x - graphStep, y: newYCoordinate)
                leftDotPath.addLine(to: currentPoint)
            }
            // 1 scale = 1 Double so this needs to be a whole number at the end
            currentOperand = round(currentOperand)
        }
        
        // Stroke
        UIColor.red.setStroke()
        righDotPath.lineWidth = 1
        righDotPath.stroke()
        leftDotPath.lineWidth = 1
        leftDotPath.stroke()
    }
    
}
