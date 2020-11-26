//
//  ReFriendsViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/06/06.
//
// Label受け渡し参考 https://qiita.com/azuma317/items/6b800bfca423e8fe2cf6

import UIKit
import CloudKit

class FriendsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var friendsTableView: UITableView!
    
    var giveName: String = ""
    var giveID: String = ""
    var giveBio: String = ""
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var friendIDs = [String]()
    var friendNames = [String]()
    var friendBios = [String]()
    
    var timer: Timer!
    var check = [Bool?]()
    
    var friendFriends = [String]()
    
    var indicator = UIActivityIndicatorView()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readFriends()
    }
    

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let workingTimer = timer {
            workingTimer.invalidate()
        }
    }
    
    
    
    @IBAction func refresh(_ sender: Any) {
        
        if let workingTimer = timer {
            workingTimer.invalidate()
        }
        
        readFriends()
    }
    
    
    
    func readFriends() {
        
        friendIDs.removeAll()
        friendNames.removeAll()
        friendBios.removeAll()
        check.removeAll()
        
        friendsTableView.reloadData()
        
        // indicatorの表示位置
        indicator.center = view.center
        // indicatorのスタイル
        indicator.style = .whiteLarge
        // indicatorの色
        indicator.color = UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0)
        // indicatorをviewに追加
        view.addSubview(indicator)
        // indicatorを表示 & アニメーション開始
        indicator.startAnimating()
        
        // タイマースタート
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingFriends), userInfo: nil, repeats: true)
        
        fetchFriends(completion: {
            // 友だち一覧を取得し終えたら名前とbioに初期値（ID）を代入
            if self.friendIDs.isEmpty == false {
                
                for i in 0...(self.friendIDs.count - 1) {
                    self.friendNames.append(self.friendIDs[i])
                    self.friendBios.append(self.friendIDs[i])
                    self.check.append(nil)
                }
                
                // 名前とbioを取得
                for i in 0...(self.friendIDs.count - 1) {
                    self.fetchFriendInfo(index: i)
                }
            }
        })
    }
    
    
    
    @objc func fetchingFriends() {
        print("Now fetching my friends...")
        
        if check.isEmpty == false && check.contains(nil) == false {
            print("Completed fetching my friends!")
            
            // タイマーを止める
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            // すべてtrue
            if check.contains(false) == false {
                print("データベースから読み込み")
                
                // UserDefaultsに保存
                userDefaults.set(self.friendIDs, forKey: "friendIDs")
                userDefaults.set(self.friendNames, forKey: "friendNames")
                userDefaults.set(self.friendBios, forKey: "friendBios")
            }
            
            // falseを含む
            else {
                print("ローカルで読み込み")
                
                // ローカルで友だちを読み込む
                readFriendsUserDefaults()
            }
            
            // UI更新
            self.friendsTableView.reloadData()
            // indicatorを非表示 & アニメーション終了
            self.indicator.stopAnimating()
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
                }
                
                completion()
            }
        })
    }
    
    
    
    func fetchFriendInfo(index: Int) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(friendIDs[index])")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だちの情報取得エラー: \(error)")
                self.check[index] = false
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.friendNames[index] = name
                self.check[index] = true
            } else {
                self.check[index] = false
            }
            
            if let bio = record?.value(forKey: "accountBio") as? String {
                self.friendBios[index] = bio
            } else {
                self.friendBios[index] = "自己紹介が未入力です"
            }
        })
    }
    
    
    
    func fetchFriendFriends(friendID: String, completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(friendID)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だちの友だち取得エラー: \(error)")
                // メインスレッドで処理
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "削除に失敗しました。\n時間をおいてもう一度お試しください。")
                }
                return
            }
            
            if let friendFriends = record?.value(forKey: "friends") as? [String] {
                for friendFriend in friendFriends {
                    self.friendFriends.append(friendFriend)
                }
                completion()
            }
        })
    }
    
    
    
    func modifyFriends(id: String, completion: @escaping () -> ()) {
        
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [id])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("\(id)の友だち更新エラー1: \(error)")
                // メインスレッドで処理
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "削除に失敗しました。\n時間をおいてもう一度お試しください。")
                }
                return
            }
            
            for record in records! {
                
                // 自分の友だちを更新するとき
                if id == myID! {
                    record["friends"] = self.friendIDs as [String]
                }
                // 友だちの友だちを更新するとき
                else {
                    record["friends"] = self.friendFriends as [String]
                }
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("\(id)の友だち更新エラー2: \(error)")
                        // メインスレッドで処理
                        DispatchQueue.main.async {
                            self.alert(title: "エラー", message: "削除に失敗しました。\n時間をおいてもう一度お試しください。")
                        }
                        return
                    }
                    print("\(id)の友だち更新成功")
                    completion()
                })
            }
        })
    }
    
    
    
    func tableView(_ table: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendIDs.count
    }
    
    
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = table.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath)
        
        let icon = cell.viewWithTag(1) as! UIImageView
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
        
        let nameLabel = cell.viewWithTag(2) as! UILabel
        nameLabel.text = friendNames[indexPath.row]
        
        let idLabel = cell.viewWithTag(3) as! UILabel
        idLabel.text = friendIDs[indexPath.row]
        
        return cell
    }
    
    
    
    // Cell の高さを60にする
    func tableView(_ table: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    
    
    func tableView(_ table: UITableView, didSelectRowAt indexPath: IndexPath) {
        table.deselectRow(at: indexPath, animated: true)
    }
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // 消す友だちのID
            let deletedFriendID = friendIDs[indexPath.row]
            
            // 友だちの友だち一覧を取得
            fetchFriendFriends(friendID: deletedFriendID, completion: {
                
                // 友だちの友だち一覧から自分のIDを抜く
                if let myIndex = self.friendFriends.index(of: myID!) {
                    self.friendFriends.remove(at: myIndex)
                }
                // 自分のIDを抜いた友だちの友だち一覧を保存
                // 自分ではなく友だちから処理すれば、万が一友だちのデータベース更新は成功して自分は失敗しても普通にチャレンジできる！
                self.modifyFriends(id: deletedFriendID, completion: {
                    
                    // 自分の友だち一覧から友だちのID・名前・Bioを抜く
                    if let friendIndex = self.friendIDs.index(of: deletedFriendID) {
                        self.friendIDs.remove(at: friendIndex)
                        self.friendNames.remove(at: friendIndex)
                        self.friendBios.remove(at: friendIndex)
                    }
                    // 友だちのIDを抜いた自分の友だち一覧を保存
                    self.modifyFriends(id: myID!, completion: {
                        
                        // メインスレッドで処理
                        DispatchQueue.main.async {
                            // セルを消す
                            tableView.deleteRows(at: [indexPath], with: .fade)
                            // アラートを表示
                            self.alert(title: "削除完了", message: "\(deletedFriendID)と友だちではなくなりました。")
                        }
                    })
                })
            })
        }
    }
    
    
    
    func alert(title: String?, message: String?) {
        
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // OKボタン
        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        // ダイアログを表示
        self.present(dialog, animated: true, completion: nil)
    }
    
    
    
    func readFriendsUserDefaults() {
        
        if userDefaults.object(forKey: "friendIDs") != nil {
            self.friendIDs = userDefaults.stringArray(forKey: "friendIDs")!
        }
        
        if userDefaults.object(forKey: "friendNames") != nil {
            self.friendNames = userDefaults.stringArray(forKey: "friendNames")!
        }
        
        if userDefaults.object(forKey: "friendBios") != nil {
            self.friendBios = userDefaults.stringArray(forKey: "friendBios")!
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "toFriendProfileVC" {
            
            let fpVC = segue.destination as! FriendProfileViewController

            if let selectedIndexPath = friendsTableView.indexPathForSelectedRow {
                
                fpVC.receiveName = friendNames[selectedIndexPath.row]
                fpVC.receiveID = friendIDs[selectedIndexPath.row]
                fpVC.receiveBio = friendBios[selectedIndexPath.row]
            }
        }
    }

    
    
}
