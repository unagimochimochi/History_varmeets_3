//
//  ParticipantCell.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/10/07.
//

import UIKit

class ParticipantCell: UITableViewCell {
    
    @IBOutlet weak var participant1ViewWidth: NSLayoutConstraint!
    @IBOutlet weak var participant2ViewWidth: NSLayoutConstraint!
    @IBOutlet weak var participant3ViewWidth: NSLayoutConstraint!
    @IBOutlet weak var othersViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var participant1Icon: UIButton!
    @IBOutlet weak var participant2Icon: UIButton!
    @IBOutlet weak var participant3Icon: UIButton!
    
    @IBOutlet weak var participant1Name: UILabel!
    @IBOutlet weak var participant2Name: UILabel!
    @IBOutlet weak var participant3Name: UILabel!
    
    @IBOutlet weak var othersLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        participant1Icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        participant1Icon.layer.borderWidth = 0.5 // 枠線の太さ
        participant1Icon.layer.cornerRadius = participant1Icon.bounds.width / 2 // 丸くする
        participant1Icon.layer.masksToBounds = true // 丸の外側を消す
        
        participant2Icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        participant2Icon.layer.borderWidth = 0.5 // 枠線の太さ
        participant2Icon.layer.cornerRadius = participant2Icon.bounds.width / 2 // 丸くする
        participant2Icon.layer.masksToBounds = true // 丸の外側を消す
        
        participant3Icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        participant3Icon.layer.borderWidth = 0.5 // 枠線の太さ
        participant3Icon.layer.cornerRadius = participant3Icon.bounds.width / 2 // 丸くする
        participant3Icon.layer.masksToBounds = true // 丸の外側を消す
    }
    
    func display1() {
        participant1ViewWidth.constant = self.contentView.bounds.width * 0.12
        participant1Icon.isHidden = false
        participant1Name.isHidden = false
    }
    
    func hidden1() {
        participant1ViewWidth.constant = 0
        participant1Icon.isHidden = true
        participant1Name.isHidden = true
    }
    
    func display2() {
        participant2ViewWidth.constant = self.contentView.bounds.width * 0.12
        participant2Icon.isHidden = false
        participant2Name.isHidden = false
    }
    
    func hidden2() {
        participant2ViewWidth.constant = 0
        participant2Icon.isHidden = true
        participant2Name.isHidden = true
    }
    
    func display3() {
        participant3ViewWidth.constant = self.contentView.bounds.width * 0.12
        participant3Icon.isHidden = false
        participant3Name.isHidden = false
    }
    
    func hidden3() {
        participant3ViewWidth.constant = 0
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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
