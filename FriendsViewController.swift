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
    var check = [Bool]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendIDs.removeAll()
        friendNames.removeAll()
        friendBios.removeAll()
        check.removeAll()
        
        friendsTableView.reloadData()
        
        // タイマースタート
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingFriends), userInfo: nil, repeats: true)
        
        fetchFriends(completion: {
            // 友だち一覧を取得し終えたら名前とbioに初期値（ID）を代入
            if self.friendIDs.isEmpty == false {
                
                for i in 0...(self.friendIDs.count - 1) {
                    self.friendNames.append(self.friendIDs[i])
                    self.friendBios.append(self.friendIDs[i])
                    self.check.append(false)
                }
                
                // 名前とbioを取得
                for i in 0...(self.friendIDs.count - 1) {
                    self.fetchFriendInfo(index: i, completion: {
                        self.check[i] = true
                    })
                }
            }
        })
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
        
        friendIDs.removeAll()
        friendNames.removeAll()
        friendBios.removeAll()
        check.removeAll()
        
        friendsTableView.reloadData()
        
        // タイマースタート
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingFriends), userInfo: nil, repeats: true)
        
        fetchFriends(completion: {
            // 友だち一覧を取得し終えたら名前とbioに初期値（ID）を代入
            if self.friendIDs.isEmpty == false {
                
                for i in 0...(self.friendIDs.count - 1) {
                    self.friendNames.append(self.friendIDs[i])
                    self.friendBios.append(self.friendIDs[i])
                    self.check.append(false)
                }
                
                // 名前とbioを取得
                for i in 0...(self.friendIDs.count - 1) {
                    self.fetchFriendInfo(index: i, completion: {
                        self.check[i] = true
                    })
                }
            }
        })
    }
    
    
    
    @objc func fetchingFriends() {
        print("Now fetching my friends")
        
        if check.contains(false) == false {
            print("Completed fetching my friends!")
            
            // タイマーを止める
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            // UI更新
            friendsTableView.reloadData()
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
    
    
    
    func fetchFriendInfo(index: Int, completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(friendIDs[index])")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だちの情報取得エラー: \(error)")
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.friendNames[index] = name
            }
            
            if let bio = record?.value(forKey: "accountBio") as? String {
                self.friendBios[index] = bio
            } else {
                self.friendBios[index] = "自己紹介が未入力です"
            }
            
            completion()
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
