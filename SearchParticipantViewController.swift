//
//  SearchParticipantViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/10/02.
//
//  セルの選択無効 https://qiita.com/takashings/items/36b820f09fb19edd7556

import UIKit
import CloudKit

class SearchParticipantViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var friendsTableView: UITableView!
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var timer: Timer!
    var timerCount = 0.0
    var fetchingCheck = [Bool]()
    
    var friendIDs = [String]()
    var friendNames = [String]()
    
    var receivedEveryoneIDs = [String]()    // 既存の予定作成者と参加者と参加予定者ごっちゃ（予定編集時）
    
    var checkmark = [Bool]()
    
    // AddPlanVCで出力されている場合、一時的に保存
    var planID: String?
    var dateAndTime: String?
    var place: String?
    var lat: String?
    var lon: String?
    
    
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        
        print(receivedEveryoneIDs)
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // タイマースタート
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingFriendInfo), userInfo: nil, repeats: true)
        
        fetchFriends(completion: {
            
            // 名前に初期値（ID）を代入
            for i in 0...(self.friendIDs.count - 1) {
                self.friendNames.append(self.friendIDs[i])
                self.fetchingCheck.append(false)
            }
            
            // 友だちの名前を取得
            for i in 0...(self.friendIDs.count - 1) {
                self.fetchFriendInfo(index: i)
            }
        })
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let workingTimer = timer {
            workingTimer.invalidate()
        }
    }
    
    
    
    func fetchFriends(completion: @escaping () -> ()) {
        
        // 自分のレコードから友だち一覧を取得
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だち一覧取得エラー: \(error)")
                return
            }
            
            if let friendIDs = record?.value(forKey: "friends") as? [String] {
                
                for friendID in friendIDs {
                    self.friendIDs.append(friendID)
                    self.checkmark.append(false)
                }
                completion()
            }
        })
    }
    
    
    
    func fetchFriendInfo(index: Int) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(self.friendIDs[index])")

        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("\(self.friendIDs[index])の情報取得エラー: \(error)")
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.friendNames[index] = name
                self.fetchingCheck[index] = true
            }
        })
    }
    
    
    
    @objc func fetchingFriendInfo() {
        print("Now fetching friend's names...")
        
        timerCount += 0.5
        
        // 友だちの名前取得に5秒以上かかったとき
        if timerCount >= 5.0 {
            
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            let dialog = UIAlertController(title: "エラー", message: "友だちを取得できませんでした。", preferredStyle: .alert)
            
            // OKボタン
            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.dismiss(animated: true, completion: nil)
                }
            }))
            
            // ダイアログを表示
            self.present(dialog, animated: true, completion: nil)
        }
        
        else if fetchingCheck.contains(false) == false {
            print("Completed fetching friend's names!")
            
            if let index = receivedEveryoneIDs.index(of: myID!) {
                receivedEveryoneIDs.remove(at: index)
            }
            
            // すでに参加者に登録している人はチェックをつける
            for existingID in receivedEveryoneIDs {
                if let index = friendIDs.index(of: existingID) {
                    checkmark[index] = true
                }
            }
            
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            // UI更新
            friendsTableView.reloadData()
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendIDs.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for:indexPath)
        
        if checkmark[indexPath.row] == true {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        let icon = cell.viewWithTag(1) as! UIImageView
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
        
        let nameLabel = cell.viewWithTag(2) as! UILabel
        nameLabel.text = friendNames[indexPath.row]
        
        let idLabel = cell.viewWithTag(3) as! UILabel
        idLabel.text = friendIDs[indexPath.row]
        
        // すでに参加者に登録している人のセルは選択できないようにする
        
        for existingID in receivedEveryoneIDs {
            if let index = friendIDs.index(of: existingID) {
                if indexPath.row == index {
                    cell.selectionStyle = .none
                    print("\(index)番目タップ無効")
                }
            }
        }
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        for existingID in receivedEveryoneIDs {
            
            if let index = friendIDs.index(of: existingID) {
                
                switch indexPath.row {
                case index:
                    return nil
                default:
                    return indexPath
                }
            }
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // チェック状態を反転してUI更新
        checkmark[indexPath.row] = !checkmark[indexPath.row]
        friendsTableView.reloadData()
    }
    
    
    
    func tableView(_ table: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }

    
    
}
