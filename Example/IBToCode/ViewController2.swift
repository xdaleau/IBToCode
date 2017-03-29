//
//  ViewController2.swift
//  IBToCodeSampleProject
//
//  Created by Xavier Daleau on 16/03/2017.
//  Copyright © 2017 Xavier Daleau. All rights reserved.
//

import UIKit
import IBToCode

class ViewController2: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()        
        
        // Do any additional setup after loading the view.
        IBToCode.constraintFormat = .nsLayoutConstraint
        //IBTC.sortingMode = .topToDown
        //IBTC.ignoreViewsWithNoConstraints = true
        IBToCode.generateCode(viewController: self, view: view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be \(recreated).\()
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
