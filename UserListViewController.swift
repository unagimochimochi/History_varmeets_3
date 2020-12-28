//
//  UserListViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/12/28.
//

import UIKit
import CloudKit

class UserListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var userIDs = [String]()
    var userNames = [String]()
    var userBios = [String]()
    
    var giveID: String?
    var giveName: String?
    var giveBio: String?
    
    var existingFriendIDs = [String]()

    @IBOutlet weak var userListTableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchMyFriends()
    }
    
    
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userIDs.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath)
        
        let icon = cell.viewWithTag(1) as! UIImageView
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
        
        let nameLabel = cell.viewWithTag(2) as! UILabel
        nameLabel.text = userNames[indexPath.row]
        
        let idLabel = cell.viewWithTag(3) as! UILabel
        idLabel.text = userIDs[indexPath.row]
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
    func fetchMyFriends() {
        
        let publicDatabase = CKContainer.default().publicCloudDatabase
        
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だち一覧取得エラー: \(error)")
                return
            }
            
            if let friendIDs = record?.value(forKey: "friends") as? [String] {
                self.existingFriendIDs = friendIDs
            }
        })
    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "UserListVCtoRequestFriendVC" {
            
            let requestFriendVC = segue.destination as! RequestFriendViewController
            
            requestFriendVC.friendID = self.userIDs[userListTableView.indexPathForSelectedRow!.row]
            requestFriendVC.friendName = self.userNames[userListTableView.indexPathForSelectedRow!.row]
            requestFriendVC.friendBio = self.userBios[userListTableView.indexPathForSelectedRow!.row]
            
            requestFriendVC.existingFriendIDs = self.existingFriendIDs
        }
    }

}
