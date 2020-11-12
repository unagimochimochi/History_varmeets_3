//
//  RequestedCell.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/09/28.
//

import UIKit

class RequestedCell: UITableViewCell {

    var approval = true
    
    @IBOutlet weak var approvalLabel: UILabel!
    @IBOutlet weak var rejectLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func tappedSwitch(_ sender: UISwitch) {
        
        if sender.isOn {
            approvalLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
            rejectLabel.font = UIFont.systemFont(ofSize: 14.0)
            
            approval = true
        }
        
        else {
            approvalLabel.font = UIFont.systemFont(ofSize: 14.0)
            rejectLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
            
            approval = false
        }
    }
}
