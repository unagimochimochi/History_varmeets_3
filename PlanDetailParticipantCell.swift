//
//  PlanDetailParticipantCell.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/10/09.
//
// AutoLayout 参考 https://blog.personal-factory.com/2016/01/11/make-auto-layout-via-code/
//

import UIKit

class PlanDetailParticipantCell: UITableViewCell {

    var participant1View: UIView!
    var participant1ViewWidth: NSLayoutConstraint!
    var participant1ViewRight: NSLayoutConstraint!
    var participant2View: UIView!
    var participant2ViewWidth: NSLayoutConstraint!
    var participant2ViewRight: NSLayoutConstraint!
    var participant3View: UIView!
    var participant3ViewWidth: NSLayoutConstraint!
    var participant3ViewRight: NSLayoutConstraint!
    var othersView: UIView!
    var othersViewWidth: NSLayoutConstraint!
    
    var participant1Icon: UIButton!
    var participant2Icon: UIButton!
    var participant3Icon: UIButton!
    
    var participant1Name: UILabel!
    var participant2Name: UILabel!
    var participant3Name: UILabel!
    
    var othersLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        participant1View = self.viewWithTag(1)
        participant1View.translatesAutoresizingMaskIntoConstraints = false
        participant1Icon = self.viewWithTag(2) as? UIButton
        participant1Name = self.viewWithTag(3) as? UILabel
        
        participant2View = self.viewWithTag(4)
        participant2View.translatesAutoresizingMaskIntoConstraints = false
        participant2Icon = self.viewWithTag(5) as? UIButton
        participant2Name = self.viewWithTag(6) as? UILabel
        
        participant3View = self.viewWithTag(7)
        participant3View.translatesAutoresizingMaskIntoConstraints = false
        participant3Icon = self.viewWithTag(8) as? UIButton
        participant3Name = self.viewWithTag(9) as? UILabel
        
        othersView = self.viewWithTag(10)
        othersView.translatesAutoresizingMaskIntoConstraints = false
        othersLabel = self.viewWithTag(11) as? UILabel
        
        participant1ViewWidth = NSLayoutConstraint(
            item: participant1View,
            attribute: .width,
            relatedBy: .equal,
            toItem: participant1View,
            attribute: .width,
            multiplier: 0,
            constant: 0)
        self.contentView.addConstraint(participant1ViewWidth)
        
        participant1ViewRight = NSLayoutConstraint(
            item: participant1View,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: participant2View,
            attribute: .leading,
            multiplier: 1.0,
            constant: 0)
        self.contentView.addConstraint(participant1ViewRight)
        
        participant2ViewWidth = NSLayoutConstraint(
            item: participant2View,
            attribute: .width,
            relatedBy: .equal,
            toItem: participant2View,
            attribute: .width,
            multiplier: 0,
            constant: 0)
        self.contentView.addConstraint(participant2ViewWidth)
        
        participant2ViewRight = NSLayoutConstraint(
            item: participant2View,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: participant3View,
            attribute: .leading,
            multiplier: 1.0,
            constant: 0)
        self.contentView.addConstraint(participant2ViewRight)
        
        participant3ViewWidth = NSLayoutConstraint(
            item: participant3View,
            attribute: .width,
            relatedBy: .equal,
            toItem: participant3View,
            attribute: .width,
            multiplier: 0,
            constant: 0)
        self.contentView.addConstraint(participant3ViewWidth)
        
        participant3ViewRight = NSLayoutConstraint(
            item: participant3View,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: othersView,
            attribute: .leading,
            multiplier: 1.0,
            constant: 0)
        self.contentView.addConstraint(participant3ViewRight)
        
        othersViewWidth = NSLayoutConstraint(
            item: othersView,
            attribute: .width,
            relatedBy: .equal,
            toItem: othersView,
            attribute: .width,
            multiplier: 0,
            constant: 0)
        self.contentView.addConstraint(othersViewWidth)
        
        round(icon: participant1Icon)
        round(icon: participant2Icon)
        round(icon: participant3Icon)
    }
    
    
    
    func display1() {
        participant1ViewWidth.constant = self.contentView.bounds.width * 0.12
        participant1ViewRight.constant = -8
        participant1Icon.isHidden = false
        participant1Name.isHidden = false
    }
    
    func hidden1() {
        participant1ViewWidth.constant = 0
        participant1ViewRight.constant = 0
        participant1Icon.isHidden = true
        participant1Name.isHidden = true
    }
    
    
    
    func display2() {
        participant2ViewWidth.constant = self.contentView.bounds.width * 0.12
        participant2ViewRight.constant = -8
        participant2Icon.isHidden = false
        participant2Name.isHidden = false
    }
    
    func hidden2() {
        participant2ViewWidth.constant = 0
        participant2ViewRight.constant = 0
        participant2Icon.isHidden = true
        participant2Name.isHidden = true
    }
    
    
    
    func display3() {
        participant3ViewWidth.constant = self.contentView.bounds.width * 0.12
        participant3ViewRight.constant = -8
        participant3Icon.isHidden = false
        participant3Name.isHidden = false
    }
    
    func hidden3() {
        participant3ViewWidth.constant = 0
        participant3ViewRight.constant = 0
        participant3Icon.isHidden = true
        participant3Name.isHidden = true
    }
    
    
    
    func displayOthers() {
        othersViewWidth.constant = self.contentView.bounds.width * 0.15
        othersLabel.isHidden = false
    }
    
    func hiddenOthers() {
        othersViewWidth.constant = 0
        othersLabel.isHidden = true
    }
    
    
    
    func round(icon: UIButton) {
        
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
    }
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    
}
