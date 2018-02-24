//
//  LoadingVC.swift
//  MVC 2.0
//
//  Created by Farzad Nazifi on 06.02.18.
//  Copyright © 2018 Farzad Nazifi. All rights reserved.
//

import UIKit

protocol FailedViewControllerDelegate: class {
    func failedViewControllerTryAgainTapped(_ failedVC: FailedViewController)
}

class FailedViewController: UIViewController {
    
    @IBOutlet var label: UILabel?
    private var message: String
    weak var delegate: FailedViewControllerDelegate?

    required init?(coder aDecoder: NSCoder) { fatalError("...") }
    
    init(message: String) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.label?.text = message
    }
    
    @IBAction func tryAgainAction(_ sender: UIButton) {
        delegate?.failedViewControllerTryAgainTapped(self)
    }
}
