//
//  GraphView.swift
//  MyCalculator
//
//  Created by Anglinov, Dmitry on 9/6/17.
//  Copyright © 2017 Anglinov, Dmitry. All rights reserved.
//

import UIKit

class GraphView: UIView {
    
    // how many pixels per unit double
    var scale : CGFloat = 25
    
    // how many function calls to move 1 unit (AKA how many points per unit we will draw)
    var resolution : Double = 100
    
    override func draw(_ rect: CGRect) {
        let center : CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let axesDrawer : AxesDrawer = AxesDrawer()
        axesDrawer.drawAxes(in: rect, origin: center, pointsPerUnit: scale)
        
        drawContinuousFunction(from: center, using: sin)
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
                currentPoint = CGPoint(x: currentPoint.x + graphStep, y: origin.y - CGFloat(function(currentOperand)) * scale)
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
                currentPoint = CGPoint(x: currentPoint.x - graphStep, y: origin.y - CGFloat(function(currentOperand)) * scale)
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
