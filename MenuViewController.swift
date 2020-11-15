//
//  MenuViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/10/23.
//

import UIKit
import CloudKit

class MenuViewController: UIViewController {
    
    @IBOutlet weak var menuView: UIView!
    
    @IBOutlet weak var icon: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    
    @IBOutlet weak var numberOfFriendsButton: UIButton!
    @IBOutlet weak var numberOfFavsButton: UIButton!
    
    @IBOutlet weak var bioLabel: UILabel!
    
    var numberOfFriends: Int?
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var fetchedBio: String?
    
    var fetchingBioTimer: Timer!
    var fetchingBioCheck = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
        
        fetchMyBio()
        
        // タイマースタート
        fetchingBioTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingBio), userInfo: nil, repeats: true)
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let id = myID, let name = myName {
            idLabel.text = id
            nameLabel.text = name
        }
        
        if let numberOfFriends = self.numberOfFriends {
            numberOfFriendsButton.setTitle(numberOfFriends.description, for: .normal)
        }
        
        if favPlaces.isEmpty == false {
            if favPlaces[0] == "お気に入り" {
                numberOfFavsButton.setTitle((favPlaces.count - 1).description, for: .normal)
            } else {
                numberOfFavsButton.setTitle(favPlaces.count.description, for: .normal)
            }
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // メニューの位置を取得
        let menuPosition = menuView.layer.position
        // 初期位置を画面の外側にするため、メニューの幅をマイナス
        menuView.layer.position.x = -menuView.frame.width
        
        // 表示時のアニメーション
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: { self.menuView.layer.position.x = menuPosition.x },
                       completion: { bool in })
    }
    
    
    
    // メニューエリア以外タップ時
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        for touch in touches {
            if touch.view?.tag == 1 {
                UIView.animate(withDuration: 0.2,
                               delay: 0,
                               options: .curveEaseIn,
                               animations: { self.menuView.layer.position.x = -self.menuView.frame.width },
                               completion: { bool in
                                self.dismiss(animated: true, completion: nil)
                               })
            }
        }
    }
    
    
    
    @IBAction func resetMyLocation(_ sender: Any) {
        
        let dialog = UIAlertController(title: "位置情報を知られたくないときに", message: "「設定」アプリで位置情報を「なし」に設定してから実行することで、位置情報をアメリカにすることができます。", preferredStyle: .actionSheet)
        
        // キャンセルボタン
        let cancel = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        // 実行ボタン
        let action = UIAlertAction(title: "実行", style: .default, handler: { action in
            self.reloadMyLocation()
        })
        
        // Actionを追加
        dialog.addAction(cancel)
        dialog.addAction(action)
        // ダイアログを表示
        self.present(dialog, animated: true, completion: nil)
    }
    
    
    
    // Safariで使用許諾契約を開く
    @IBAction func openEULA(_ sender: Any) {
        
        let url = URL(string: "https://drive.google.com/file/d/1OhF2qtKDzPRUqdwaoGzNBbLYdWum88YY/view?usp=sharing")!
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    
    
    // Safariでプライバシーポリシーを開く
    @IBAction func openPrivacyPolicy(_ sender: Any) {
        
        let url = URL(string: "https://drive.google.com/file/d/1CSu73HPBuIk0Tqhtvhul-vx-C6_ykUHw/view?usp=sharing")!
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    
    
    func fetchMyBio() {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("Bio取得エラー: \(error)")
                return
            }
            
            if let bio = record?.value(forKey: "accountBio") as? String {
                self.fetchedBio = bio
                self.fetchingBioCheck = 1
            } else {
                print("クラウドのBioが空")
                self.fetchingBioCheck = 2
            }
        })
    }
    
    
    
    @objc func fetchingBio() {
        print("Now fetching my bio...")
        
        if fetchingBioCheck != 0 {
            print("Completed fetching my bio!")
            
            // タイマーを止める
            if let workingTimer = fetchingBioTimer {
                workingTimer.invalidate()
            }
            
            if fetchingBioCheck == 1 {
                // bioを表示
                bioLabel.text = fetchedBio
                if #available(iOS 13.0, *) {
                    bioLabel.textColor = .label
                } else {
                    bioLabel.textColor = .black
                }
            }
            
            else if fetchingBioCheck == 2 {
                // bioが空であることを表示
                bioLabel.text = "自己紹介が未入力です"
                if #available(iOS 13.0, *) {
                    bioLabel.textColor = .placeholderText
                } else {
                    bioLabel.textColor = .systemGray
                }
            }
        }
    }
    
    
    
    func reloadMyLocation() {
        
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("位置情報リセットエラー1: \(error)")
                return
            }
            
            for record in records! {
                
                record["currentLocation"] = CLLocation(latitude: 40.689283, longitude: -74.044368)
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("位置情報リセットエラー2: \(error)")
                        return
                    }
                    print("位置情報リセット成功")
                })
            }
        })
    }

    
    
}
