//
//  GraphViewController.swift
//  MyCalculator
//
//  Created by Anglinov, Dmitry on 9/7/17.
//  Copyright © 2017 Anglinov, Dmitry. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {
    
    public var functionToGraph : ((Double) -> Double)? {
        get {
            return model.functionToGraph
        }
        set {
            model.functionToGraph = newValue
        }
    }

    public var initialY : Double {
        get {
            return model.initialY
        }
        set {
            model.initialY = newValue
        }
    }
    
    private var model = GraphModel()
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            let handler = #selector(GraphView.changeScale(byReactingTo:))
            let pinchRecognizer = UIPinchGestureRecognizer(target: graphView, action: handler)
            graphView.addGestureRecognizer(pinchRecognizer)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        graphView.functionToGraph = model.functionToGraph
        graphView.initialY = model.initialY;
        graphView.setNeedsDisplay()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
