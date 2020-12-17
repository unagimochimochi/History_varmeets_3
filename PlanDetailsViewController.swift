//
//  PlanDetailsViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/07/06.
//

import UIKit
import CloudKit

class PlanDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let planItem = ["予定作成者", "参加者", "承認待ち", "場所"]
    
    var planID: String?
    
    var planTitle: String?
    var dateAndTime: String?
    var estimatedTime: Date?
    
    var authorID: String?
    var authorName: String?
    var authorBio: String?
    
    var participantIDs = [String]()
    var participantNames = [String]()
    var preparedParticipantIDs = [String]()
    var preparedParticipantNames = [String]()
    
    var fetchParticipantSuccess = [Bool]()
    var fetchPreparedParticipantSuccess = [Bool]()
    var fetchSuccess = [false, false, false]    // [予定作成者, 予定参加者, 予定参加候補者]
    
    var timer: Timer!
    var timerCount = 0.0
    
    var indicator = UIActivityIndicatorView()
    
    var place: String?
    var lonStr: String?
    var latStr: String?
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    @IBOutlet weak var planDetailsTableView: UITableView!
    @IBOutlet weak var dateAndTimeLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingPlan), userInfo: nil, repeats: true)
        
        fetchParticipants(
            // 予定作成者のID取得後
            completion1: {
                // 予定作成者の名前を取得
                self.fetchAuthorInfo()
            },
            
            // 予定参加者のID取得後
            completion2: {
                // 参加者がいるとき
                if self.participantIDs.isEmpty == false {
                    // 名前に初期値（ID）を代入
                    for i in 0...(self.participantIDs.count - 1) {
                        self.participantNames.append(self.participantIDs[i])
                        self.fetchParticipantSuccess.append(false)
                    }
                    // 名前を取得
                    for i in 0...(self.participantIDs.count - 1) {
                        self.fetchParticipantInfo(index: i)
                    }
                }
                // 参加者がいないとき
                else {
                    self.fetchSuccess[1] = true
                }
            },
            
            // 予定参加候補者のID取得後
            completion3: {
                // 参加候補者がいるとき
                if self.preparedParticipantIDs.isEmpty == false {
                    // 名前に初期値（ID）を代入
                    for i in 0...(self.preparedParticipantIDs.count - 1) {
                        self.preparedParticipantNames.append(self.preparedParticipantIDs[i])
                        self.fetchPreparedParticipantSuccess.append(false)
                    }
                    // 名前を取得
                    for i in 0...(self.preparedParticipantIDs.count - 1) {
                        self.fetchPreparedParticipantInfo(index: i)
                    }
                }
                
                // 参加候補者がいないとき
                else {
                    self.fetchSuccess[2] = true
                }
            })
        
        if let dateAndTime = self.dateAndTime {
            dateAndTimeLabel.text = dateAndTime
        }
        
        if let planTitle = self.planTitle {
            self.navigationItem.title = planTitle
        }
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlanDetailAuthorCell", for: indexPath)
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
        
        else if indexPath.row == 1 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlanDetailParticipantCell", for: indexPath) as! PlanDetailParticipantCell
            
            cell.textLabel?.text = planItem[indexPath.row]
            
            if participantIDs.count == 0 {
                cell.hidden1()
                cell.hidden2()
                cell.hidden3()
                cell.displayOthers()
                
                cell.othersLabel.text = "なし"
            }
            
            else if participantIDs.count == 1 {
                cell.display1()
                cell.hidden2()
                cell.hidden3()
                cell.hiddenOthers()
                
                cell.participant1Name.text = participantNames[0]
            }
            
            else if participantIDs.count == 2 {
                cell.display1()
                cell.display2()
                cell.hidden3()
                cell.hiddenOthers()
                
                cell.participant1Name.text = participantNames[0]
                cell.participant2Name.text = participantNames[1]
            }
            
            else if participantIDs.count == 3 {
                cell.display1()
                cell.display2()
                cell.display3()
                cell.hiddenOthers()
                
                cell.participant1Name.text = participantNames[0]
                cell.participant2Name.text = participantNames[1]
                cell.participant3Name.text = participantNames[2]
            }
            
            else {
                cell.display1()
                cell.display2()
                cell.display3()
                cell.displayOthers()
                
                cell.participant1Name.text = participantNames[0]
                cell.participant2Name.text = participantNames[1]
                cell.participant3Name.text = participantNames[2]
                cell.othersLabel.text = "他\(participantNames.count - 3)人"
            }
            
            return cell
        }
        
        else if indexPath.row == 2 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlanDetailParticipantCell", for: indexPath) as! PlanDetailParticipantCell
            
            cell.textLabel?.text = planItem[indexPath.row]
            
            if preparedParticipantNames.count == 0 {
                cell.hidden1()
                cell.hidden2()
                cell.hidden3()
                cell.displayOthers()
                
                cell.othersLabel.text = "なし"
            }
            
            else if preparedParticipantNames.count == 1 {
                cell.display1()
                cell.hidden2()
                cell.hidden3()
                cell.hiddenOthers()
                
                cell.participant1Name.text = preparedParticipantNames[0]
            }
            
            else if preparedParticipantNames.count == 2 {
                cell.display1()
                cell.display2()
                cell.hidden3()
                cell.hiddenOthers()
                
                cell.participant1Name.text = preparedParticipantNames[0]
                cell.participant2Name.text = preparedParticipantNames[1]
            }
            
            else if preparedParticipantNames.count == 3 {
                cell.display1()
                cell.display2()
                cell.display3()
                cell.hiddenOthers()
                
                cell.participant1Name.text = preparedParticipantNames[0]
                cell.participant2Name.text = preparedParticipantNames[1]
                cell.participant3Name.text = preparedParticipantNames[2]
            }
            
            else {
                cell.display1()
                cell.display2()
                cell.display3()
                cell.displayOthers()
                
                cell.participant1Name.text = preparedParticipantNames[0]
                cell.participant2Name.text = preparedParticipantNames[1]
                cell.participant3Name.text = preparedParticipantNames[2]
                cell.othersLabel.text = "他\(preparedParticipantNames.count - 3)人"
            }
            
            return cell
        }
        
        else if indexPath.row == 3 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlanDetailPlaceCell", for: indexPath)
            
            cell.textLabel?.text = planItem[indexPath.row]
            
            if let place = self.place {
                let placeLabel = cell.viewWithTag(1) as! UILabel
                placeLabel.text = place
            }
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlanDetailsCell", for: indexPath)
            cell.textLabel?.text = planItem[indexPath.row]
            
            return cell
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return planItem.count
    }
    
    
    
    // Cell の高さを68にする
    func tableView(_ table: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68.0
    }

    
    
    @objc func fetchingPlan() {
        print("Now fetching plan...")
        
        timerCount += 0.5
        
        // 参加者取得に5秒以上かかったとき
        if timerCount >= 5.0 {
            
            // タイマーを止める
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            DispatchQueue.main.async {
                // indicatorを非表示 & アニメーション終了
                self.indicator.stopAnimating()
                
                let dialog = UIAlertController(title: "エラー", message: "予定を取得できませんでした。", preferredStyle: .alert)
                // OKボタン
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // ダイアログを表示
                dialog.present(dialog, animated: true, completion: nil)
            }
        }
        
        if fetchParticipantSuccess.isEmpty == false, fetchParticipantSuccess.contains(false) == false {
            fetchSuccess[1] = true
        }
        
        if fetchPreparedParticipantSuccess.isEmpty == false, fetchPreparedParticipantSuccess.contains(false) == false {
            fetchSuccess[2] = true
        }
        
        if fetchSuccess.contains(false) == false {
            print("Completed fetching Plan!")
            
            // タイマーを止める
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            // UI更新
            self.planDetailsTableView.reloadData()
            // indicatorを非表示 & アニメーション終了
            self.indicator.stopAnimating()
            
            // 編集できるようにする
            self.editButton.isEnabled = true
        }
    }
        
    // データベースから作成者と参加者のIDを取得
    func fetchParticipants(completion1: @escaping () -> (), completion2: @escaping () -> (), completion3: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "planID-\(planID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("参加者一覧取得エラー: \(error)")
                return
            }
            
            if let author = record?.value(forKey: "authorID") as? String {
                self.authorID = author
                completion1()
            }
            
            if let participantIDs = record?.value(forKey: "participantIDs") as? [String] {
                
                for participantID in participantIDs {
                    print("success!")
                    self.participantIDs.append(participantID)
                }
                completion2()
            }
            
            // 参加者がいないとき
            else {
                self.fetchSuccess[1] = true
            }
            
            if let preparedParticipantIDs = record?.value(forKey: "preparedParticipantIDs") as? [String] {
                for preparedParticipantID in preparedParticipantIDs {
                    self.preparedParticipantIDs.append(preparedParticipantID)
                }
                completion3()
            }
            
            // 参加候補者がいないとき
            else {
                self.fetchSuccess[2] = true
            }
        })
    }
    
    
    
    func fetchAuthorInfo() {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(authorID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("作成者の情報取得エラー: \(error)")
                self.fetchSuccess[0] = false
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.authorName = name
                self.fetchSuccess[0] = true
            }
            
            if let bio = record?.value(forKey: "accountBio") as? String {
                self.authorBio = bio
            } else {
                self.authorBio = "自己紹介が未入力です"
            }
        })
    }
    
    
    
    func fetchParticipantInfo(index: Int) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(participantIDs[index])")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("参加者〈\(self.participantIDs[index])〉の情報取得エラー: \(error)")
                self.fetchParticipantSuccess[index] = false
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.participantNames[index] = name
                self.fetchParticipantSuccess[index] = true
            }
        })
    }
    
    
    
    func fetchPreparedParticipantInfo(index: Int) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(preparedParticipantIDs[index])")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("参加候補者〈\(self.preparedParticipantIDs[index])〉の情報取得エラー: \(error)")
                self.fetchParticipantSuccess[index] = false
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.preparedParticipantNames[index] = name
                self.fetchPreparedParticipantSuccess[index] = true
            }
        })
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "editPlan" {
            let addPlanVC = segue.destination as! AddPlanViewController
            addPlanVC.planID = self.planID
            addPlanVC.planTitle = self.planTitle
            addPlanVC.dateAndTime = self.dateAndTime
            addPlanVC.estimatedTime = self.estimatedTime
            addPlanVC.place = self.place
            addPlanVC.lon = self.lonStr ?? ""
            addPlanVC.lat = self.latStr ?? ""
            
            addPlanVC.authorID = self.authorID
            addPlanVC.authorName = self.authorName
            addPlanVC.existingParticipantIDs = self.participantIDs
            addPlanVC.existingPreparedParticipantIDs = self.preparedParticipantIDs
            
            var everyoneIDsExceptAuhor = self.participantIDs
            for preparedParticipantID in self.preparedParticipantIDs {
                everyoneIDsExceptAuhor.append(preparedParticipantID)
            }
            addPlanVC.everyoneIDsExceptAuthor = everyoneIDsExceptAuhor
            
            var everyoneNamesExceptAuthor = self.participantNames
            for preparedParticipantName in self.preparedParticipantNames {
                everyoneNamesExceptAuthor.append(preparedParticipantName)
            }
            addPlanVC.everyoneNamesExceptAuthor = everyoneNamesExceptAuthor
        }

        else if identifier == "toPlaceVC" {
            let placeVC = segue.destination as! PlaceViewController
            placeVC.place = self.place
            placeVC.lonStr = self.lonStr
            placeVC.latStr = self.latStr
        }
        
        else if identifier == "PlanDetailsVCtoParticipantProfileVC" {
            let participantProfileVC = segue.destination as! ParticipantProfileViewController
            participantProfileVC.receiveName = self.authorName
            participantProfileVC.receiveID = self.authorID
            participantProfileVC.receiveBio = self.authorBio
        }
    }
    
    
    
}
