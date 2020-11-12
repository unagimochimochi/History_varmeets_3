//
//  AddPlanViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/05/15.
//
// TableView 基礎 https://qiita.com/pe-ta/items/cafa8e20029047993025
// セルごとアクションを変える https://tech.pjin.jp/blog/2016/09/24/tableview-14/

import UIKit

class AddPlanViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var planID: String?
    
    var planTitle: String?
    var dateAndTime: String!
    var authorID: String?
    var authorName: String?
    var everyoneIDsExceptAuthor = [String]()    // UITableViewに表示する参加者（編集時）と参加候補者
    var everyoneNamesExceptAuthor = [String]()  // 同上
    var participantIDs = [String]()            // データベースのpreparedParticipantIDsに入れる配列
    var place: String?
    var lon: String = ""
    var lat: String = ""
    
    var existingParticipantIDs = [String]()
    var existingPreparedParticipantIDs = [String]()
    
    @IBOutlet weak var addPlanTable: UITableView!
    
    @IBOutlet weak var planTitleTextField: UITextField!
    
    // キャンセルボタン
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 保存ボタン
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var planItem = ["日時", "予定作成者", "参加者", "場所"]
    
    var inputTimer: Timer!
    var inputCheck = [false, false, false, false]    // タイトル、日時、参加者、場所
    var estimatedTime: Date?    // チェック用
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        planTitleTextField.delegate = self
        
        addPlanTable.dataSource = self
        
        if let planTitle = self.planTitle {
            self.planTitleTextField.text = planTitle
        }
        
        if authorID == nil {
            authorID = myID
            authorName = myName
        }

        // 保存ボタンをデフォルトで無効にする
        saveButton.isEnabled = false
        saveButton.image = UIImage(named: "SaveButton_gray")
        
        // タイマースタート
        inputTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(completedInputing), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // タイマーを止める
        if let workingTimer = inputTimer {
            workingTimer.invalidate()
        }
    }
    
    // 参加者を選択画面からの巻き戻し
    @IBAction func unwindToAddPlanVCFromSearchParticipantVC(sender: UIStoryboardSegue) {
        
        if let sourceVC = sender.source as? SearchParticipantViewController {
            
            // 予定IDがあるとき（編集時）
            if let planID = sourceVC.planID {
                self.planID = planID
            }
            
            // 日時をすでに出力していたとき
            if let dateAndTime = sourceVC.dateAndTime {
                self.dateAndTime = dateAndTime
            }
            
            // 場所をすでに出力していたとき
            if let place = sourceVC.place, let lat = sourceVC.lat, let lon = sourceVC.lon {
                self.place = place
                self.lat = lat
                self.lon = lon
            }
            
            for i in 0...(sourceVC.friendIDs.count - 1) {
                // i番目の友だちを参加者に指定したとき
                if sourceVC.checkmark[i] == true {
                    self.everyoneIDsExceptAuthor.append(sourceVC.friendIDs[i])
                    self.everyoneNamesExceptAuthor.append(sourceVC.friendNames[i])
                    self.participantIDs.append(sourceVC.friendIDs[i])
                }
            }
            
            for i in 0...(participantIDs.count - 1) {
                // i番目の参加者がすでに承認済みだったとき
                if existingParticipantIDs.contains(participantIDs[i]) {
                    participantIDs[i] = "NO"
                }
            }
            
            if let i = participantIDs.index(of: authorID!) {
                participantIDs[i] = "NO"
            }
            
            //  NOを取り除く
            while participantIDs.contains("NO") {
                if let index = participantIDs.index(of: "NO") {
                    self.participantIDs.remove(at: index)
                }
            }
            
            addPlanTable.reloadData()
        }
    }
    
    // 場所を選択画面からの巻き戻し
    @IBAction func unwindToAddPlanVCFromSearchPlaceVC(sender: UIStoryboardSegue) {
        
        if let sourceVC = sender.source as? SearchPlaceViewController {
            
            // 予定IDがあるとき（編集時）
            if let planID = sourceVC.planID {
                self.planID = planID
            }
            
            // 日時をすでに出力していたとき
            if let dateAndTime = sourceVC.dateAndTime {
                self.dateAndTime = dateAndTime
            }
            
            if let place = sourceVC.place, let lat = sourceVC.lat, let lon = sourceVC.lon {
                self.place = place
                self.lat = lat
                self.lon = lon
            }
            
            addPlanTable.reloadData()
        }
    }
    
    @objc func completedInputing() {
        print("Check input")
        
        // タイトル（0）
        if let titleText = planTitleTextField.text {
            if titleText.count >= 1 {
                inputCheck[0] = true
            } else {
                inputCheck[0] = false
            }
        }
        
        // 日時（1）
        if estimatedTime != nil {
            inputCheck[1] = true
        } else {
            inputCheck[1] = false
        }
        
        // 参加者（2）
        if everyoneIDsExceptAuthor.isEmpty == false {
            inputCheck[2] = true
        } else {
            inputCheck[2] = false
        }
        
        // 場所（3）
        if place != nil {
            inputCheck[3] = true
        } else {
            inputCheck[3] = false
        }
        
        if inputCheck.contains(false) == false {
            // 保存ボタンを有効にする
            saveButton.isEnabled = true
            saveButton.image = UIImage(named: "SaveButton")
            
        } else {
            // 保存ボタンを無効にする
            saveButton.isEnabled = false
            saveButton.image = UIImage(named: "SaveButton_gray")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "DateAndTimeCell", for:indexPath) as! DateAndTimeCell
            
            cell.textLabel?.text = planItem[indexPath.row]
            
            cell.displayDateAndTimeTextField.delegate = self
            
            if let usedDatePicker = cell.estimatedTime {
                estimatedTime = usedDatePicker    // 入力チェック用
            } else {
                // UIDatePickerを使ったときのUITextFieldへの出力はDateAndTimeCell.Swiftに記載
                cell.displayDateAndTimeTextField.text = dateAndTime
            }
            
            return cell
            
        }
        
        else if indexPath.row == 1 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "AuthorCell", for: indexPath)
            
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
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as! ParticipantCell
            
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
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for:indexPath) as! PlaceCell
            
            cell.textLabel?.text = planItem[indexPath.row]

            if let place = self.place {
                print("place: \(place)")
                cell.displayPlaceTextField.text = place
            } else {
                print("nil")
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section:Int) -> Int {
        return planItem.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // print("\(indexPath.row)番セルをタップ")
        tableView.deselectRow(at: indexPath, animated: true) // セルの選択を解除
        
        if indexPath.row == 0 {
            if let cell = tableView.cellForRow(at: indexPath) as? DateAndTimeCell {
                cell.displayDateAndTimeTextField.becomeFirstResponder()
            }
        } else {
            // 0番セル以外をクリックしたらキーボードを閉じる
            view.endEditing(true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        self.view.endEditing(true)
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        // DateAndTimeCellのUITextField編集終了時にUITableViewを更新することで、cellForRowAtのestimatedTime代入をおこなう（めんどくさ！）
        addPlanTable.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if let identifier = segue.identifier {
            
            if identifier == "toSearchPlaceVC" {
                let searchPlaceVC = segue.destination as! SearchPlaceViewController
                searchPlaceVC.planID = self.planID
                self.dateAndTime = (addPlanTable.cellForRow(at: IndexPath(row: 0, section: 0)) as? DateAndTimeCell)?.displayDateAndTimeTextField.text ?? ""
                searchPlaceVC.dateAndTime = self.dateAndTime
            }
            
            if identifier == "toSearchParticipantVC" {
                let searchParticipantVC = segue.destination as! SearchParticipantViewController
                searchParticipantVC.planID = self.planID
                self.dateAndTime = (addPlanTable.cellForRow(at: IndexPath(row: 0, section: 0)) as? DateAndTimeCell)?.displayDateAndTimeTextField.text ?? ""
                searchParticipantVC.dateAndTime = self.dateAndTime
                searchParticipantVC.place = self.place
                searchParticipantVC.lat = self.lat
                searchParticipantVC.lon = self.lon
                
                // すでに選択済みだった際に重複してしまうため取り除く
                everyoneIDsExceptAuthor.removeAll()
                everyoneNamesExceptAuthor.removeAll()
                participantIDs.removeAll()
                
                // 既存の予定作成者・参加者・参加予定者
                var everyoneIDs = existingParticipantIDs
                for existingPreparedParticipantID in existingPreparedParticipantIDs {
                    everyoneIDs.append(existingPreparedParticipantID)
                }
                everyoneIDs.append(authorID!)
                searchParticipantVC.receivedEveryoneIDs = everyoneIDs
            }
        }
        
        guard let button = sender as? UIBarButtonItem, button === self.saveButton else {
            return
        }
        self.planTitle = self.planTitleTextField.text!
    }
    
}
