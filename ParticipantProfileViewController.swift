//
//  ParticipantProfileViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/10/30.
//

import UIKit

class ParticipantProfileViewController: UIViewController {

    var receiveName: String?
    var receiveID: String?
    var receiveBio: String?
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 1 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
        
        if let name = receiveName {
            nameLabel.text = name
            self.navigationItem.title = name
        }
        
        if let id = receiveID {
            idLabel.text = id
        }
        
        if let bio = receiveBio {
            bioLabel.text = bio
            
            if bio == "" {
                bioLabel.text = "自己紹介が未入力です"
            }
            
            if bio != "自己紹介が未入力です" {
                if #available(iOS 13.0, *) {
                    bioLabel.textColor = .label
                } else {
                    bioLabel.textColor = .black
                }
            }
        }
        
    }
    

    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    

}
