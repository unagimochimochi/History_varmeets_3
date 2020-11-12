//
//  MyProfileViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/09/19.
//

import UIKit
import CloudKit

class MyProfileViewController: UIViewController {
    
    var fetchedBio: String?
    
    var timer: Timer!
    var check = 0
    
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var header: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
        
        fetchMyBio()
        
        // タイマースタート
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(completeFetchingMyBio), userInfo: nil, repeats: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let id = myID, let name = myName {
            idLabel.text = id
            nameLabel.text = name
        }
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func editedMyProfile(sender: UIStoryboardSegue) {
        if let editMyProfileVC = sender.source as? EditMyProfileViewController,
            let id = myID,
            let name = editMyProfileVC.name,
            let bio = editMyProfileVC.bio {
            
            myName = name
            userDefaults.set(name, forKey: "myName")
            
            nameLabel.text = name
            bioLabel.text = bio
            bioLabel.textColor = .black
            
            // デフォルトコンテナ（iCloud.com.gmail.mokamokayuuyuu.varmeets）のパブリックデータベースにアクセス
            let publicDatabase = CKContainer.default().publicCloudDatabase
            
            // 検索条件を作成
            let predicate = NSPredicate(format: "accountID == %@", argumentArray: [id])
            let query = CKQuery(recordType: "Accounts", predicate: predicate)
            
            // 検索したレコードの値を更新
            publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                if let error = error {
                    print("レコードのプロフィール更新エラー1: \(error)")
                    return
                }
                for record in records! {
                    record["accountName"] = name as NSString
                    record["accountBio"] = bio as NSString
                    publicDatabase.save(record, completionHandler: {(record, error) in
                        if let error = error {
                            print("レコードのプロフィール更新エラー2: \(error)")
                            return
                        }
                        print("レコードのプロフィール更新成功")
                    })
                }
            })
        }
    }

    func fetchMyBio() {
        // デフォルトコンテナ（iCloud.com.gmail.mokamokayuuyuu.varmeets）のパブリックデータベースにアクセス
        let publicDatabase = CKContainer.default().publicCloudDatabase
        
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("Bio取得エラー: \(error)")
                return
            }
            
            if let bio = record?.value(forKey: "accountBio") as? String {
                print("Bio取得成功")
                self.fetchedBio = bio
                self.check = 1
            } else {
                print("クラウドのBioが空")
                self.check = 2
            }
        })
    }
    
    @objc func completeFetchingMyBio() {
        print("fetchingBio")
        
        if check != 0 {
            
            print("completedFetchingMyBio!")
            
            // タイマーを止める
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            if check == 1 {
                // bioを表示
                bioLabel.text = fetchedBio
                bioLabel.textColor = .black
            }
            
            else if check == 2 {
                // bioが空であることを表示
                bioLabel.text = "自己紹介が未入力です"
                bioLabel.textColor = .systemGray
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "toEditMyProfileVC" {
            let editMyProfileVC = segue.destination as! EditMyProfileViewController
            editMyProfileVC.bio = fetchedBio
        }
    }
    
}
