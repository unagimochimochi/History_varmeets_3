//
//  ApprovePlanParticipantCell.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/11/03.
//

import UIKit

class ApprovePlanParticipantCell: UITableViewCell {

    var participant1Icon: UIImageView!
    var participant2Icon: UIImageView!
    var participant3Icon: UIImageView!
    
    var participant1Name: UILabel!
    var participant2Name: UILabel!
    var participant3Name: UILabel!
    
    var othersLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        participant1Icon = self.viewWithTag(3) as? UIImageView
        participant2Icon = self.viewWithTag(5) as? UIImageView
        participant3Icon = self.viewWithTag(7) as? UIImageView
        
        round(icon: participant1Icon)
        round(icon: participant2Icon)
        round(icon: participant3Icon)
        
        participant1Name = self.viewWithTag(4) as? UILabel
        participant2Name = self.viewWithTag(6) as? UILabel
        participant3Name = self.viewWithTag(8) as? UILabel
        
        othersLabel = self.viewWithTag(9) as? UILabel
        
        hidden1()
        hidden2()
        hidden3()
        hiddenOthers()
    }

    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    
    func display1() {
        participant1Icon.isHidden = false
        participant1Name.isHidden = false
    }
    
    func hidden1() {
        participant1Icon.isHidden = true
        participant1Name.isHidden = true
    }
    
    
    
    func display2() {
        participant2Icon.isHidden = false
        participant2Name.isHidden = false
    }
    
    func hidden2() {
        participant2Icon.isHidden = true
        participant2Name.isHidden = true
    }
    
    
    
    func display3() {
        participant3Icon.isHidden = false
        participant3Name.isHidden = false
    }
    
    func hidden3() {
        participant3Icon.isHidden = true
        participant3Name.isHidden = true
    }
    
    
    
    func displayOthers() {
        othersLabel.isHidden = false
    }
    
    func hiddenOthers() {
        othersLabel.isHidden = true
    }
    
    
    
    func round(icon: UIImageView) {
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
    }

    
    
}
