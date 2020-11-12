//
//  DeleteMyAccountViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/10/24.
//

import UIKit
import CloudKit

class DeleteMyAccountViewController: UIViewController, UITextFieldDelegate {
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var inputPassword: String?
    var fetchedPassword: String?
    
    var fetchedFriendIDs = [String]()
    var fetchedFriendFriendIDs = [[String]]()
    
    var existingIDs = [String]()
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var continueButton: UIBarButtonItem!
    
    var timer1: Timer!
    var timer2: Timer!
    var deleteCheck = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passwordTextField.delegate = self
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 入力中は続行ボタンを無効にする
    func textFieldDidBeginEditing(_ textField: UITextField) {
        continueButton.isEnabled = false
        continueButton.image = UIImage(named: "ContinueButton_gray")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.endEditing(true)
        
        inputPassword = textField.text
        
        // UITextFieldが空でなければ続行ボタンを有効にする
        if let text = textField.text, !text.isEmpty {
            continueButton.isEnabled = true
            continueButton.image = UIImage(named: "ContinueButton")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        
        inputPassword = textField.text
        
        // UITextFieldが空でなければ続行ボタンを有効にする
        if let text = textField.text, !text.isEmpty {
            continueButton.isEnabled = true
            continueButton.image = UIImage(named: "ContinueButton")
        }
        
        return true
    }
    
    // 続行ボタンタップ時
    @IBAction func deleteMyAccount(_ sender: Any) {
        
        // タイマースタート
        timer1 = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingPassword), userInfo: nil, repeats: true)
        
        fetchPassword()
    }
    
    @objc func fetchingPassword() {
        print("Fetching my password")
        
        if let correctPassword = fetchedPassword {
            print("Completed fetching my password!")
            
            // タイマーを止める
            if let workingTimer = timer1 {
                workingTimer.invalidate()
            }
            
            // 入力したパスワードと取得したパスワードが一致したとき
            if self.inputPassword == correctPassword {
                let dialog = UIAlertController(title: "最終確認", message: "アカウントを削除すると復元できません。\n本当に削除しますか？", preferredStyle: .alert)
                
                // キャンセルボタン
                let cancel = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                
                // 削除ボタン
                let delete = UIAlertAction(title: "削除", style: .destructive, handler: { action in
                    
                    // タイマースタート
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        self.timer2 = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.deletingMyAccount), userInfo: nil, repeats: true)
                    }
                    // アカウントのレコード削除前に友だち一覧を取得
                    self.fetchFriendIDs(completion: {
                        // アカウントのレコード削除
                        self.deleteMyAccount()
                    })
                })
                
                // Actionを追加
                dialog.addAction(cancel)
                dialog.addAction(delete)
                // ダイアログを表示
                self.present(dialog, animated: true, completion: nil)
            }
            
            // パスワードが間違っていたとき
            else {
                let dialog = UIAlertController(title: "削除失敗", message: "パスワードが違います。", preferredStyle: .alert)
                // もう一度挑戦ボタン
                dialog.addAction(UIAlertAction(title: "もう一度挑戦", style: .default, handler: nil))
                // ダイアログを表示
                self.present(dialog, animated: true, completion: nil)
            }
        }
    }
    
    @objc func deletingMyAccount() {
        print("Deleting my account")
        
        if deleteCheck != 0 {
            // タイマーを止める
            if let workingTimer = timer2 {
                workingTimer.invalidate()
            }
            
            if deleteCheck == 1 {
                let dialog = UIAlertController(title: "削除失敗", message: "おそらく通信環境が悪いです。\n時間をおいてもう一度お試しください。", preferredStyle: .alert)
                // OKボタン
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // ダイアログを表示
                self.present(dialog, animated: true, completion: nil)
            }
            
            else if deleteCheck == 2 {
                let dialog = UIAlertController(title: "削除完了", message: "アカウントをインターネット上から完全に削除しました。\nアプリ削除して終了してください。", preferredStyle: .alert)
                // OKボタン
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // ダイアログを表示
                self.present(dialog, animated: true, completion: nil)
                
                if fetchedFriendIDs.isEmpty == false {
                    for i in 0...(self.fetchedFriendIDs.count - 1) {
                        // 友だちの友だち一覧から自分のIDを削除（メンバ変数）
                        self.deleteMyIDByFriendFriendIDs(count: i, completion: {
                            // 友だちの友だち一覧を更新
                            self.reloadFriendFriendIDs(count: i)
                        })
                    }
                }
                
                // アカウントリストから自分のIDを削除
                // アカウントリストを取得
                fetchExistingIDs(completion: {
                    // アカウントリストから自分のIDを削除（メンバ変数）
                    if let index = self.existingIDs.index(of: "accountID-\(myID!)") {
                        self.existingIDs.remove(at: index)
                    }
                    // アカウントリストを更新
                    self.reloadExistingIDs()
                })
            }
        }
    }
    
    func fetchPassword() {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("パスワード取得エラー: \(error)")
                return
            }
            
            if let password = record?.value(forKey: "password") as? String {
                self.fetchedPassword = password
            }
        })
    }
    
    func deleteMyAccount() {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.delete(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("アカウント削除エラー: \(error)")
                self.deleteCheck = 1
                return
            }
            print("アカウント削除成功")
            self.deleteCheck = 2
        })
    }
    
    func fetchFriendIDs(completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だち取得エラー: \(error)")
                return
            }
            
            if let friendIDs = record?.value(forKey: "friends") as? [String] {
                for friendID in friendIDs {
                    self.fetchedFriendIDs.append(friendID)
                }
                completion()
            } else {
                completion()
            }
        })
    }
    
    func deleteMyIDByFriendFriendIDs(count: Int, completion: @escaping () -> ()) {
        
        // 初期値に空の配列を代入
        for _ in 0...(fetchedFriendIDs.count - 1) {
            fetchedFriendFriendIDs.append([String]())
        }
        
        let friendRecordID = CKRecord.ID(recordName: "accountID-\(fetchedFriendIDs[count])")
        
        publicDatabase.fetch(withRecordID: friendRecordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("\(self.fetchedFriendIDs[count])の友だち一覧取得エラー: \(error)")
                return
            }
            
            if let friendFriendIDs = record?.value(forKey: "friends") as? [String] {
                
                for friendFriendID in friendFriendIDs {
                    self.fetchedFriendFriendIDs[count].append(friendFriendID)
                }
                
                // 友だちの友だち一覧から自分のIDを削除
                if let index = self.fetchedFriendFriendIDs[count].index(of: myID!) {
                    self.fetchedFriendFriendIDs[count].remove(at: index)
                }
                completion()
            }
        })
    }
    
    func reloadFriendFriendIDs(count: Int) {
        
        // 友だちの検索条件を作成
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [fetchedFriendIDs[count]])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("\(self.fetchedFriendIDs[count])の友だち一覧更新エラー1: \(error)")
                return
            }
            
            for record in records! {
                
                record["friends"] = self.fetchedFriendFriendIDs[count] as [String]
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("\(self.fetchedFriendIDs[count])の友だち一覧更新エラー2: \(error)")
                        return
                    }
                    print("\(self.fetchedFriendIDs[count])の友だち一覧更新成功")
                })
            }
        })
    }
    
    func fetchExistingIDs(completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "all-varmeetsIDsList")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("アカウントリスト取得エラー: \(error)")
                return
            }
            
            if let allIDs = record?.value(forKey: "accounts") as? [String] {
                for existingID in allIDs {
                    self.existingIDs.append(existingID)
                }
                print("アカウントリスト取得成功")
                completion()
            }
        })
    }
    
    func reloadExistingIDs() {
        
        // アカウントリストの検索条件を作成
        let predicate = NSPredicate(format: "toSearch == %@", argumentArray: ["all-varmeetsIDs"])
        let query = CKQuery(recordType: "AccountsList", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("アカウントリスト更新エラー1: \(error)")
                return
            }
            
            for record in records! {
                
                record["accounts"] = self.existingIDs as [String]
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("アカウントリスト更新エラー2: \(error)")
                        return
                    }
                    print("アカウントリスト更新成功")
                })
            }
        })
    }
    
}
