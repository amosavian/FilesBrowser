//
//  ErrorVC.swift
//  MVC 2.0
//
//  Created by Farzad Nazifi on 06.02.18.
//  Copyright © 2018 Farzad Nazifi. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {
    init() {
        let bundle = Bundle(for: LoadingViewController.self)
        super.init(nibName: nil, bundle: bundle)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("die") }
}
