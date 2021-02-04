//
//  ApprovePlanViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/11/01.
//

import UIKit
import CloudKit

class ApprovePlanViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let planItem = ["日時", "予定作成者", "参加者", "場所"]
    
    var planID: String?
    var planTitle: String?
    var estimatedTime: Date?
    var dateAndTime: String?
    var authorID: String?
    var authorName: String?
    var participantIDs = [String]()
    var preparedParticipantIDs = [String]()
    var everyoneIDsExceptAuthor = [String]()    // 予定参加者と予定参加候補者
    var everyoneNamesExceptAuthor = [String]()
    var place: String?
    var location: CLLocation?
    
    var approval = true
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    var fetchSuccess = [false, false, false]    // [予定の詳細, 予定作成者, 予定参加者]
    var timer: Timer!
    var timerCount = 0.0
    
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var approvalLabel: UILabel!
    @IBOutlet weak var rejectLabel: UILabel!
    
    @IBOutlet weak var planDetailsTableView: UITableView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingPlan), userInfo: nil, repeats: true)
        
        fetchPlanDetails(completion: {
            
            self.fetchAuthorInfo()
            
            // 参加者と参加候補者を合わせる
            self.everyoneIDsExceptAuthor = self.participantIDs
            for preparedParticipantID in self.preparedParticipantIDs {
                self.everyoneIDsExceptAuthor.append(preparedParticipantID)
            }
            
            // 初期値にIDを代入
            for i in 0...(self.everyoneIDsExceptAuthor.count - 1) {
                self.everyoneNamesExceptAuthor.append(self.everyoneIDsExceptAuthor[i])
            }
            
            for i in 0...(self.everyoneIDsExceptAuthor.count - 1) {
                self.fetchParticipantInfo(index: i)
            }
        })
    }
    
    
    
    @IBAction func tappedSwitch(_ sender: UISwitch) {
        
        if sender.isOn {
            approvalLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
            rejectLabel.font = UIFont.systemFont(ofSize: 14.0)
            
            approval = true
        }
        
        else {
            approvalLabel.font = UIFont.systemFont(ofSize: 14.0)
            rejectLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
            
            approval = false
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return planItem.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ApprovePlanDateAndTimeCell", for: indexPath)
            
            cell.textLabel?.text = planItem[indexPath.row]
            cell.detailTextLabel?.text = dateAndTime
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 15.0)
            
            return cell
        }
        
        else if indexPath.row == 1 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ApprovePlanAuthorCell", for: indexPath)
            
            cell.textLabel?.text = planItem[indexPath.row]
            
            let icon = cell.viewWithTag(1) as! UIButton
            icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
            icon.layer.borderWidth = 1 // 枠線の太さ
            icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
            icon.layer.masksToBounds = true // 丸の外側を消す
            
            let authorNameLabel = cell.viewWithTag(2) as! UILabel
            authorNameLabel.text = authorName
            
            return cell
        }
        
        else if indexPath.row == 2 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ApprovePlanParticipantCell", for: indexPath) as! ApprovePlanParticipantCell
            
            cell.textLabel?.text = planItem[indexPath.row]
            
            if everyoneNamesExceptAuthor.count == 0 {
                cell.hidden1()
                cell.hidden2()
                cell.hidden3()
                cell.hiddenOthers()
            }
            
            else if everyoneNamesExceptAuthor.count == 1 {
                cell.display1()
                cell.hidden2()
                cell.hidden3()
                cell.hiddenOthers()
                
                cell.participant1Name.text = everyoneNamesExceptAuthor[0]
            }
            
            else if everyoneNamesExceptAuthor.count == 2 {
                cell.display1()
                cell.display2()
                cell.hidden3()
                cell.hiddenOthers()
                
                cell.participant1Name.text = everyoneNamesExceptAuthor[0]
                cell.participant2Name.text = everyoneNamesExceptAuthor[1]
            }
            
            else if everyoneNamesExceptAuthor.count == 3 {
                cell.display1()
                cell.display2()
                cell.display3()
                cell.hiddenOthers()
                
                cell.participant1Name.text = everyoneNamesExceptAuthor[0]
                cell.participant2Name.text = everyoneNamesExceptAuthor[1]
                cell.participant3Name.text = everyoneNamesExceptAuthor[2]
            }
            
            else {
                cell.display1()
                cell.display2()
                cell.display3()
                cell.displayOthers()
                
                cell.participant1Name.text = everyoneNamesExceptAuthor[0]
                cell.participant2Name.text = everyoneNamesExceptAuthor[1]
                cell.participant3Name.text = everyoneNamesExceptAuthor[2]
                cell.othersLabel.text = "他\(everyoneNamesExceptAuthor.count - 3)人"
            }
            
            return cell
        }
        
        else if indexPath.row == 3 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ApprovePlanPlaceCell", for: indexPath)
            
            cell.textLabel?.text = planItem[indexPath.row]
            
            let placeLabel = cell.viewWithTag(10) as! UILabel
            placeLabel.text = place
            
            return cell
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ApprovePlanDateAndTimeCell", for: indexPath)
            return cell
        }
    }
    
    
    
    func tableView(_ table: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68.0
    }
    
    
    
    @objc func fetchingPlan() {
        print("Now Fetching Plan")
        
        timerCount += 0.5
        
        // 予定の詳細取得に5秒以上かかったとき
        if timerCount >= 5.0 {
            
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            let dialog = UIAlertController(title: "エラー", message: "予定を取得できませんでした。", preferredStyle: .alert)
            
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
        
        else if fetchSuccess.contains(false) == false {
            
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            print("予定取得成功")
            overviewLabel.text = "\(authorName!) さんが以下の予定への参加を求めています。"
            titleLabel.text = planTitle
            planDetailsTableView.reloadData()
        }
    }
    
    func fetchPlanDetails(completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "planID-\(planID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("予定の詳細取得エラー: \(error)")
                self.fetchSuccess[0] = false
                return
            }
            
            if let participants = record?.value(forKey: "participantIDs") as? [String] {
                for participant in participants {
                    self.participantIDs.append(participant)
                }
            }
            
            if let title = record?.value(forKey: "planTitle") as? String,
               let estimatedTime = record?.value(forKey: "estimatedTime") as? Date,
               let author = record?.value(forKey: "authorID") as? String,
               let preparedParticipants = record?.value(forKey: "preparedParticipantIDs") as? [String],
               let place = record?.value(forKey: "placeName") as? String,
               let location = record?.value(forKey: "placeLatAndLon") as? CLLocation {
                
                self.planTitle = title
                
                self.estimatedTime = estimatedTime
                
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .full
                formatter.timeZone = NSTimeZone.local
                formatter.locale = Locale(identifier: "ja_JP")
                self.dateAndTime = "\(formatter.string(from: estimatedTime))"
                
                self.authorID = author
                
                for preparedParticipant in preparedParticipants {
                    self.preparedParticipantIDs.append(preparedParticipant)
                }
                
                self.place = place
                self.location = location
                
                self.fetchSuccess[0] = true
                completion()
                
            } else {
                self.fetchSuccess[0] = false
            }
        })
    }
    
    
    
    func fetchAuthorInfo() {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(authorID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("予定作成者の情報取得エラー: \(error)")
                self.fetchSuccess[1] = false
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.authorName = name
                self.fetchSuccess[1] = true
            } else {
                self.fetchSuccess[1] = false
            }
        })
    }
    
    
    
    func fetchParticipantInfo(index: Int) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(everyoneIDsExceptAuthor[index])")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("予定参加者の情報取得エラー: \(error)")
                self.fetchSuccess[2] = false
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.everyoneNamesExceptAuthor[index] = name
                if index == (self.everyoneIDsExceptAuthor.count - 1) {
                    self.fetchSuccess[2] = true
                }
            }
        })
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "ApprovePlanVCtoPlaceVC" {
            let placeVC = segue.destination as! PlaceViewController
            placeVC.place = self.place
            placeVC.latStr = self.location?.coordinate.latitude.description
            placeVC.lonStr = self.location?.coordinate.longitude.description
        }
    }

    
    
}
