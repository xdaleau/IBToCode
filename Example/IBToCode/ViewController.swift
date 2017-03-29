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
        
        IBToCode.generateCode(viewController: self)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

