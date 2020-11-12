//
//  RequestFriendViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/09/22.
//

import UIKit
import CloudKit

class RequestFriendViewController: UIViewController {
    
    var friendID: String?
    var friendName: String?
    var friendBio: String?
    
    var requestedAccounts = [String]()
    var existingFriendIDs = [String]()
    
    let publicDatabase = CKContainer.default().publicCloudDatabase

    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var header: UIImageView!
    @IBOutlet weak var bioLabel: UILabel!
    
    @IBOutlet weak var requestButton: UIButton!
    
    var requestSuccess: Bool?
    var full = false
    
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let id = friendID, let name = friendName {
            idLabel.text = id
            nameLabel.text = name
        }
        
        if let bio = friendBio {
            bioLabel.text = bio
            if bio == "自己紹介が未入力です" {
                bioLabel.textColor = .systemGray
            } else {
                bioLabel.textColor = .black
            }
        }
        
        // アイコン
        icon.layer.borderColor = UIColor.gray.cgColor
        icon.layer.borderWidth = 0.5
        icon.layer.cornerRadius = icon.bounds.width / 2
        icon.layer.masksToBounds = true
        
        // 友だち申請ボタン
        requestButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        requestButton.layer.cornerRadius = 8
        requestButton.layer.masksToBounds = true
        
        // すでに申請済みのとき
        if requestedAccounts.contains(myID!) {
            requestButton.setTitle("申請をキャンセル", for: .normal)
            requestButton.setTitleColor(.white, for: .normal)
            requestButton.backgroundColor = UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0)
        } else {
            // すでに友だちのとき
            if existingFriendIDs.contains(friendID!) {
                requestButton.setTitle("すでに友だちです", for: .normal)
                requestButton.setTitleColor(.systemGray, for: .normal)
                requestButton.layer.borderColor = UIColor.gray.cgColor
                requestButton.layer.borderWidth = 1
                requestButton.isEnabled = false
            } else {
                requestButton.setTitle("友だち申請", for: .normal)
                requestButton.setTitleColor(UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0), for: .normal)
                requestButton.layer.borderColor = UIColor.orange.cgColor
                requestButton.layer.borderWidth = 1
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let workingTimer = timer {
            workingTimer.invalidate()
        }
    }

    @IBAction func request(_ sender: Any) {
        
        reloadFriendRecord()
        
        // タイマースタート
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(requesting), userInfo: nil, repeats: true)
    }
    
    @objc func requesting() {
        print("requesting")
        
        if let workingTimer = timer {
            
            if self.requestSuccess == true && self.full == false {
                
                workingTimer.invalidate()
                
                // 申請キャンセルボタンクリック後
                if self.requestedAccounts.contains(myID!) {
                    // 01~03のうち何番目に申請されているか
                    if let index = self.requestedAccounts.index(of: myID!) {
                        // 自分のIDがあるところにNOを挿入
                        self.requestedAccounts[index] = "NO"
                    }
                    
                    // 申請キャンセル成功ダイアログ
                    let dialog = UIAlertController(title: "申請キャンセル成功", message: "\(self.friendName!)さんへの申請をキャンセルしました。", preferredStyle: .alert)
                    // OKボタン
                    dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    // ダイアログを表示
                    self.present(dialog, animated: true, completion: nil)
                    
                    // ボタンの見た目をスイッチ
                    self.requestButton.setTitle("友だち申請", for: .normal)
                    self.requestButton.setTitleColor(UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0), for: .normal)
                    self.requestButton.backgroundColor = .white
                    self.requestButton.layer.borderColor = UIColor.orange.cgColor
                    self.requestButton.layer.borderWidth = 1
                }
                
                // 友だち申請ボタンクリック後
                else {
                    // 01~03のうち、NOのところに自分のIDを挿入
                    if self.requestedAccounts[0] == "NO" {
                        self.requestedAccounts[0] = myID!
                    } else if self.requestedAccounts[1] == "NO" {
                        self.requestedAccounts[1] = myID!
                    } else if self.requestedAccounts[2] == "NO" {
                        self.requestedAccounts[2] = myID!
                    }
                    
                    // 友だち申請成功ダイアログ
                    let dialog = UIAlertController(title: "友だち申請成功", message: "\(self.friendName!)さんに友だち申請しました。", preferredStyle: .alert)
                    // OKボタン
                    dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    // ダイアログを表示
                    self.present(dialog, animated: true, completion: nil)
                    
                    // ボタンの見た目をスイッチ
                    self.requestButton.setTitle("申請をキャンセル", for: .normal)
                    self.requestButton.setTitleColor(.white, for: .normal)
                    self.requestButton.backgroundColor = UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0)
                }
            }
            
            // 相手が3人以上の申請を抱えているとき
            else if self.full == true {
                
                workingTimer.invalidate()
                
                let dialog = UIAlertController(title: "友だち申請失敗", message: "\(self.friendName!)さんは、現在3人から同時に友だち申請されている人気者です。\n申し訳ございませんが、これ以上の申請は受け付けられません。", preferredStyle: .alert)
                // OKボタン
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // ダイアログを表示
                self.present(dialog, animated: true, completion: nil)
            }
            
            // エラー
            else if requestSuccess == false {
                
                workingTimer.invalidate()
                
                let dialog = UIAlertController(title: "エラー", message: "処理に失敗しました。\n申し訳ございませんが、時間をおいて再度お試しください。", preferredStyle: .alert)
                // OKボタン
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // ダイアログを表示
                self.present(dialog, animated: true, completion: nil)
            }
        }
    }
    
    func reloadFriendRecord() {
        
        // 検索条件を作成
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [friendID!])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        // 検索したレコードの値を更新
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("申請エラー1: \(error)")
                self.requestSuccess = false
                return
            }
            
            for record in records! {
                // すでに申請済みのとき
                if self.requestedAccounts.contains(myID!) {
                    // 01~03のうち何番目に申請されているか
                    if let index = self.requestedAccounts.index(of: myID!) {
                        // 自分のIDがあるところにNOを挿入
                        record["requestedAccountID_0\((index + 1).description)"] = "NO"
                    }
                }
                
                // これから申請するとき
                else {
                    // 01~03のうち、NOのところに申請する
                    if self.requestedAccounts[0] == "NO" {
                        record["requestedAccountID_01"] = myID!
                    } else if self.requestedAccounts[1] == "NO" {
                        record["requestedAccountID_02"] = myID!
                    } else if self.requestedAccounts[2] == "NO" {
                        record["requestedAccountID_03"] = myID!
                    }
                    
                    // NOがないとき
                    else {
                        print("相手の申請数の上限を超えています")
                        self.full = true
                        return
                    }
                }
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("申請エラー2: \(error)")
                        self.requestSuccess = false
                        return
                    }
                    print("友だち申請／キャンセル成功")
                    self.requestSuccess = true
                })
            }
        })
    }
    
}
