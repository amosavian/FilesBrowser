//
//  FileTableViewCell.swift
//  FilesBrowser
//
//  Copyright © 2018 Mousavian. All rights reserved.
//

import UIKit

class FileTableViewCell: UITableViewCell {

    @IBOutlet weak var fileImageView: UIImageView!
    
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var fileDescription: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
