//
//  RequestedViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/09/27.
//

import UIKit
import CloudKit

class RequestedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var requestedIDs = [String]()
    var requestedNames = [String]()

    @IBOutlet weak var requestedTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestedTableView.delegate = self
        requestedTableView.dataSource = self

        // 名前に初期値（ID）を代入
        for i in 0...(requestedIDs.count - 1) {
            requestedNames.append(requestedIDs[i])
        }
        
        for i in 0...(requestedIDs.count - 1) {
            fetchFriendInfo(friendID: requestedIDs[i], index: i)
        }
        
        // 1秒後
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.requestedTableView.reloadData()
        }
    }
    
    func fetchFriendInfo(friendID: String, index: Int) {
        
        let publicDatabase = CKContainer.default().publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "accountID-\(friendID)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("申請者の情報取得エラー: \(error)")
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.requestedNames[index] = name
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestedIDs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestedCell", for: indexPath) as! RequestedCell
        
        let icon = cell.viewWithTag(1) as! UIImageView
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
        
        let nameLabel = cell.viewWithTag(2) as! UILabel
        if requestedNames.isEmpty {
            nameLabel.text = "名前"
        } else {
            nameLabel.text = requestedNames[indexPath.row]
        }
        
        let idLabel = cell.viewWithTag(3) as! UILabel
        idLabel.text = requestedIDs[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
}
