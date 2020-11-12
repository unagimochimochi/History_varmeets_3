//
//  AddFriendViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/09/21.
//

import UIKit
import CloudKit

class AddFriendViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var existingFriendIDs = [String]()
    
    var fetchedFriendID: String?
    var fetchedFriendName: String?
    var fetchedFriendBio: String?
    
    var fetchedRequestedAccounts = [String]()
    
    @IBOutlet weak var friendsSearchBar: UISearchBar!
    @IBOutlet weak var resultsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendsSearchBar.delegate = self
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        
        fetchMyFriends()
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        fetchedFriendID = nil
        fetchedFriendName = nil
        fetchedFriendBio = nil
        
        resultsTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードをとじる
        self.view.endEditing(true)
        
        if let text = searchBar.text {
            fetchFriendInfo(friendID: text)
            
            // 1秒後に処理
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let id = self.fetchedFriendID, let name = self.fetchedFriendName {
                    print("ID: \(id), Name: \(name)")
                    
                    self.resultsTableView.reloadData()
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // テキストを空にする
        searchBar.text = ""
        // キーボードをとじる
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fetchedFriendID == nil {
            return 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "foundFriendCell", for: indexPath)
        
        let icon = cell.viewWithTag(1) as! UIImageView
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
        
        if let id = self.fetchedFriendID, let name = self.fetchedFriendName {
            let nameLabel = cell.viewWithTag(2) as! UILabel
            nameLabel.text = name
            
            let idLabel = cell.viewWithTag(3) as! UILabel
            idLabel.text = id
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }

    func fetchFriendInfo(friendID: String) {

        let recordID = CKRecord.ID(recordName: "accountID-\(friendID)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だちの情報取得エラー: \(error)")
                return
            }
            
            if let id = record?.value(forKey: "accountID") as? String, let name = record?.value(forKey: "accountName") as? String {
                self.fetchedFriendID = id
                self.fetchedFriendName = name
            }
            
            if let bio = record?.value(forKey: "accountBio") as? String {
                self.fetchedFriendBio = bio
            } else {
                self.fetchedFriendBio = "自己紹介が未入力です"
            }
            
            if let requested01 = record?.value(forKey: "requestedAccountID_01") as? String,
                let requested02 = record?.value(forKey: "requestedAccountID_02") as? String,
                let requested03 = record?.value(forKey: "requestedAccountID_03") as? String {
                
                self.fetchedRequestedAccounts.append(requested01)
                self.fetchedRequestedAccounts.append(requested02)
                self.fetchedRequestedAccounts.append(requested03)
            }
        })
    }
    
    func fetchMyFriends() {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だち一覧取得エラー: \(error)")
                return
            }
            
            if let friendIDs = record?.value(forKey: "friends") as? [String] {
                
                for friendID in friendIDs {
                    self.existingFriendIDs.append(friendID)
                }
            }
        })
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "toRequestFriendVC" {
            let requestFriendVC = segue.destination as! RequestFriendViewController
            
            requestFriendVC.friendID = fetchedFriendID
            requestFriendVC.friendName = fetchedFriendName
            requestFriendVC.friendBio = fetchedFriendBio
            
            requestFriendVC.requestedAccounts = fetchedRequestedAccounts
            requestFriendVC.existingFriendIDs = existingFriendIDs
        }
        
    }

}
