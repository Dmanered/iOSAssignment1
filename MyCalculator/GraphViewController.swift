//
//  GraphViewController.swift
//  MyCalculator
//
//  Created by Anglinov, Dmitry on 9/7/17.
//  Copyright © 2017 Anglinov, Dmitry. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {

    @IBOutlet weak var graphView: GraphView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print("Changed orientation")
        graphView.draw(graphView.bounds)
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
