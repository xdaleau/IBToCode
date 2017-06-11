//
//  ViewController.swift
//  IBToCodeSampleProject
//
//  Created by Xavier Daleau on 27/03/2017.
//  Copyright © 2017 Xavier Daleau. All rights reserved.
//

import UIKit
import IBToCode

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // you can chose between the nsLayoutConstaint (default), anchors, or SnapKit 3 constaints syntax.
        // IBToCode.constraintFormat = .snapKit3
        
        
        // IBTC.sortingMode = .topToDown
        
        // Use the viewController as source to get the UILayoutGuide constraints
        IBToCode.generateCode(viewController: self)
        
        // If you want to use a view as source:
        //IBToCode.generateCode(viewController:nil, view: view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

