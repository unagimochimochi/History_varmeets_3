//
//  HomeViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/02/26.
//

import UIKit
import MapKit
import CloudKit

var myID: String?
var myName: String?

var myPlanIDs = [String]()
var estimatedTimes = [Date]()
var estimatedTimesSort = [Date]()

let userDefaults = UserDefaults.standard

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var dateAndTimes = [String]()
    var planTitles = [String]()
    var everyoneIDsExceptMe = [[String]]()          // 起動時にデータベースから取得する自分以外の作成者・参加者・参加候補者ID
    var participantIDs = [[String]]()
    var preparedParticipantIDs = [[String]]()
    var places = [String]()
    var lons = [String]()
    var lats = [String]()
    
    var addOrEdit: String?
    
    var indicator = UIActivityIndicatorView()
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var planIDsOnDatabase = [[String]]()           // 予定作成時・編集時にデータベースから取得
    var planIDsModifySuccess = [Bool?]()
    var toSavePreparedParticipantIDs = [String]()   // 予定作成時・編集時にデータベースに保存する予定参加候補者ID
    var everyoneIDs = [String]()                  // 予定作成時にチェックする作成者・参加者・参加候補者ID
    var newParticipantIDs = [String]()             // 予定編集時にチェックする新たに追加した参加候補者ID
    
    var savePlanRecordTimer: Timer!
    
    var selectedIndexPath: Int?
    
    var fetchedRequests = ["NO", "NO", "NO"]
    var friendIDs = [String]()                    // 起動時の自分の友だち一覧
    var friendIDsToMe = [String]()                // friendIDs配列に申請許可者を追加した一覧
    var requestedIDs = [String]()
    var fetchedApplicantFriendIDs = [[String]]()
    var fetchedPreparedPlanIDs = [String]()        // 起動時にデータベースから取得する自分の予定候補ID
    
    var timer: Timer!
    
    var fetchRequestsTimer: Timer!
    var fetchRequestsCheck = false
    
    var fetchPlansTimer: Timer!
    var fetchPlansTimerCount = 0.0
    var fetchPlansCheck = [Bool]()
    var noPlansOnDatabase: Bool?
    
    var existingIDs = [String]()
    var firstLaunch = false
    
    @IBOutlet weak var planTable: UITableView!
    
    @IBOutlet weak var countdownView: UIView!
    @IBOutlet weak var countdownViewHeight: NSLayoutConstraint!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var countdownDateAndTimeLabel: UILabel!
    @IBOutlet weak var countdownPlanTitleLabel: UILabel!
    @IBOutlet weak var completeButton: UIButton!
    
    
    
    @IBAction func createdAccount(sender: UIStoryboardSegue) {
        
        if let firstVC = sender.source as? FirstViewController,
            let id = firstVC.id,
            let name = firstVC.name,
            let password = firstVC.password {
            
            // アカウントのレコード作成
            self.createAccountRecord(id: id, name: name, password: password, completion: {
                // 通知のレコード作成
                self.createNotificationRecord(id: id, completion: {
                    
                    myID = id
                    myName = name
                    userDefaults.set(myID, forKey: "myID")
                    userDefaults.set(myName, forKey: "myName")
                    
                    // もう一度登録されているIDを取得（前画面入力中に新たなIDが追加されているかもしれないため）
                    self.fetchExistingIDs(completion: {
                        // 取得し終えたら自分のIDを追加
                        self.existingIDs.append("accountID-\(id)")
                        
                        let predicate = NSPredicate(format: "toSearch IN %@", ["all-varmeetsIDs"])
                        let query = CKQuery(recordType: "AccountsList", predicate: predicate)
                        
                        self.publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                            
                            if let error = error {
                                print("アカウントリスト追加エラー1: \(error)")
                                DispatchQueue.main.async {
                                    self.alert(title: "微妙にエラー", message: "アカウントの作成は成功しましたが、varmeets ID 一覧に \(id) を追加できませんでした。\nお手数ですが、Webサイトのお問い合わせフォームよりご連絡していただけると大変助かります🥺\nあなたの利用に支障はありませんので、任意です！")
                                }
                                return
                            }
                            
                            for record in records! {
                                
                                record["accounts"] = self.existingIDs as [String]
                                
                                self.publicDatabase.save(record, completionHandler: {(record, error) in
                                    
                                    if let error = error {
                                        print("アカウントリスト追加エラー2: \(error)")
                                        DispatchQueue.main.async {
                                            self.alert(title: "微妙にエラー", message: "アカウントの作成は成功しましたが、varmeets ID 一覧に \(id) を追加できませんでした。\nお手数ですが、Webサイトのお問い合わせフォームよりご連絡していただけると大変助かります🥺\nあなたの利用に支障はありませんので、任意です！")
                                        }
                                        return
                                    }
                                })
                            }
                            print("アカウントリスト追加成功")
                        })
                    })
                })
            })
        }
    }
    
    
    
    @IBAction func becameFriends(sender: UIStoryboardSegue) {
        
        if let requestedVC = sender.source as? RequestedViewController {
            
            // 通知の許可を求める
            requestNotifications()
            
            requestedIDs = requestedVC.requestedIDs
            
            // 新たな配列に現在の友だち一覧を代入
            friendIDsToMe = friendIDs
            
            var count = 0
            while count < requestedIDs.count {
                
                if (requestedVC.requestedTableView.cellForRow(at: IndexPath(row: count, section: 0)) as? RequestedCell)!.approval == true {
                    // 友だち一覧に申請者を追加
                    friendIDsToMe.append(requestedIDs[count])
                }
                
                count += 1
            }
                
            // 自分のレコードの検索条件を作成
            let predicate1 = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
            let query1 = CKQuery(recordType: "Accounts", predicate: predicate1)
                
            // 検索したレコードの値を更新
            publicDatabase.perform(query1, inZoneWith: nil, completionHandler: {(records, error) in
                if let error = error {
                    print("友だち一覧更新エラー1: \(error)")
                    return
                }
                        
                for record in records! {
                    
                    record["friends"] = self.friendIDsToMe as [String]
                    record["requestedAccountID_01"] = "NO" as NSString
                    record["requestedAccountID_02"] = "NO" as NSString
                    record["requestedAccountID_03"] = "NO" as NSString
                    
                    self.publicDatabase.save(record, completionHandler: {(record, error) in
                        if let error = error {
                            print("友だち一覧更新エラー2: \(error)")
                            return
                        }
                        print("友だち一覧更新成功")
                    })
                }
            })
            
            // 初期値に空の配列を代入
            for _ in 0...(requestedIDs.count - 1) {
                fetchedApplicantFriendIDs.append([String]())
            }
            
            // 友だちの友だち一覧を更新
            for i in 0...(requestedIDs.count - 1) {
                
                // 友だち（申請者）の友だち一覧を取得し終えたら
                fetchApplicantFriendIDs(count: i, completion: {
                    // メインスレッドで処理
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        // 申請を許可する場合
                        if (requestedVC.requestedTableView.cellForRow(at: IndexPath(row: i, section: 0)) as? RequestedCell)!.approval == true {
                            // 友だち（申請者）の友だち一覧に自分のIDを追加
                            self.fetchedApplicantFriendIDs[i].append(myID!)
                        }
                    }
                    
                    // 友だち（申請者）の友だち一覧を更新
                    self.reloadApplicantFriendIDs(count: i)
                })
            }
        }
    }
    
    
    
    @IBAction func approvedPlan(sender: UIStoryboardSegue) {
        
        if let approvedPlanVC = sender.source as? ApprovePlanViewController {
            
            guard let approvedPlanID = approvedPlanVC.planID else {
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "予定を承認できませんでした。")
                }
                return
            }
            
            // 通知の許可を求める
            requestNotifications()
            
            // 予定を承認する場合
            if approvedPlanVC.approval == true {
                myPlanIDs.append(approvedPlanID)
                self.planTitles.append(approvedPlanVC.planTitle!)
                estimatedTimes.append(approvedPlanVC.estimatedTime!)
                self.dateAndTimes.append(approvedPlanVC.dateAndTime!)
                
                // まず予定作成者以外を代入
                var everyoneIDsExceptMe = approvedPlanVC.everyoneIDsExceptAuthor
                // 予定作成者を追加
                everyoneIDsExceptMe.append(approvedPlanVC.authorID!)
                // 自分のIDを抜く
                if let index = everyoneIDsExceptMe.index(of: myID!) {
                    everyoneIDsExceptMe.remove(at: index)
                }
                // メンバ変数に追加
                self.everyoneIDsExceptMe.append(everyoneIDsExceptMe)
                
                // まずApprovedPlanVC起動時に取得した参加者を代入
                var participantIDsOfApprovedPlan = approvedPlanVC.participantIDs
                // 自分のIDを追加
                participantIDsOfApprovedPlan.append(myID!)
                // メンバ変数に追加
                self.participantIDs.append(participantIDsOfApprovedPlan)
                
                // まずApprovedPlanVC起動時に取得した参加候補者を代入
                var preparedParticipantIDsOfApprovedPlan = approvedPlanVC.participantIDs
                // 自分のIDを抜く
                if let index = preparedParticipantIDsOfApprovedPlan.index(of: myID!) {
                    preparedParticipantIDsOfApprovedPlan.remove(at: index)
                }
                // メンバ変数に追加
                self.preparedParticipantIDs.append(preparedParticipantIDsOfApprovedPlan)
                
                self.places.append(approvedPlanVC.place!)
                self.lats.append((approvedPlanVC.location?.coordinate.latitude.description)!)
                self.lons.append((approvedPlanVC.location?.coordinate.longitude.description)!)
            }
            
            // 起動時に取得した予定候補ID一覧から承認／非承認する予定IDを抜く
            if let index = self.fetchedPreparedPlanIDs.index(of: approvedPlanID) {
                self.fetchedPreparedPlanIDs.remove(at: index)
            }
            
            // 自分のレコードのplanIDsに許可した予定のIDを追加
            addApprovedPlanID(completion: {
                
                // 予定のレコードのparticipantIDsに自分のIDを追加
                
                var newParticipantIDs = approvedPlanVC.participantIDs
                // 予定を承認する場合、参加者に自分のIDを追加
                if approvedPlanVC.approval == true {
                    newParticipantIDs.append(myID!)
                }
                
                var newPreparedParticipantIDs = approvedPlanVC.preparedParticipantIDs
                // 当初の予定参加候補者ID一覧から自分のIDを抜く
                if let index = newPreparedParticipantIDs.index(of: myID!) {
                    newPreparedParticipantIDs.remove(at: index)
                }
                
                let predicate = NSPredicate(format: "planID == %@", argumentArray: [approvedPlanID])
                let query = CKQuery(recordType: "Plans", predicate: predicate)
                
                self.publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                    
                    if let error = error {
                        print("予定承認（Plans）エラー1: \(error)")
                        DispatchQueue.main.async {
                            self.alert(title: "エラー", message: "予定を承認できませんでした。\n他の参加者と同じタイミングで承認しようとした場合、このエラーが発生することがあります。\n時間をおいて右上の更新ボタンを押すと、再び予定承認可否の画面が出てきます。")
                            // 承認しようとした予定のindexを取得（要素数 - 1）
                            let indexOfApprovedPlan = myPlanIDs.count - 1
                            // 予定を削除（変数・データベース）
                            self.remove(index: indexOfApprovedPlan, completion: {
                                // 削除後メインスレッドで処理
                                DispatchQueue.main.async {
                                    self.planTable.reloadData()
                                }
                            })
                        }
                        return
                    }
                    
                    for record in records! {
                        
                        record["participantIDs"] = newParticipantIDs as [String]
                        record["preparedParticipantIDs"] = newPreparedParticipantIDs as [String]
                        
                        self.publicDatabase.save(record, completionHandler: {(record, error) in
                            
                            if let error = error {
                                print("予定承認（Plans）エラー2: \(error)")
                                DispatchQueue.main.async {
                                    self.alert(title: "エラー", message: "予定を承認できませんでした。\n他の参加者と同じタイミングで承認しようとした場合、このエラーが発生することがあります。\n時間をおいて右上の更新ボタンを押すと、再び予定承認可否の画面が出てきます。")
                                    // 承認しようとした予定のindexを取得（要素数 - 1）
                                    let indexOfApprovedPlan = myPlanIDs.count - 1
                                    // 予定を削除（変数・データベース）
                                    self.remove(index: indexOfApprovedPlan, completion: {
                                        // 削除後メインスレッドで処理
                                        DispatchQueue.main.async {
                                            self.planTable.reloadData()
                                        }
                                    })
                                }
                                return
                            }
                            print("予定承認（Plans）成功")
                        })
                    }
                })
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    self.planTable.reloadData()
                }
            })
        }
    }
    
    
    
    @IBAction func unwindtoHomeVC(sender: UIStoryboardSegue) {
        
        guard let addPlanVC = sender.source as? AddPlanViewController else {
            return
        }
        
        planIDsOnDatabase.removeAll()
        planIDsModifySuccess.removeAll()
        
        // 通知の許可を求める
        requestNotifications()
        
        // 日時
        if let dateAndTime = addPlanVC.dateAndTime {
            
            if let selectedIndexPath = planTable.indexPathForSelectedRow {
                
                dateAndTimes[selectedIndexPath.row] = dateAndTime
                estimatedTimes[selectedIndexPath.row] = addPlanVC.estimatedTime!
                
            } else {
                dateAndTimes.append(dateAndTime)
                estimatedTimes.append(addPlanVC.estimatedTime!)
            }
            
            userDefaults.set(dateAndTimes, forKey: "DateAndTimes")
            userDefaults.set(estimatedTimes, forKey: "EstimatedTimes")
        }
        
        // 予定タイトル
        if let planTitle = addPlanVC.planTitle {
            
            if let selectedIndexPath = planTable.indexPathForSelectedRow {
                planTitles[selectedIndexPath.row] = planTitle
                
            } else {
                planTitles.append(planTitle)
            }
            
            userDefaults.set(planTitles, forKey: "PlanTitles")
        }
        
        // 参加者・参加候補者
        if addPlanVC.everyoneNamesExceptAuthor.isEmpty == false {
            
            self.toSavePreparedParticipantIDs = addPlanVC.participantIDs
            
            if let selectedIndexPath = planTable.indexPathForSelectedRow {
                self.preparedParticipantIDs[selectedIndexPath.row] = addPlanVC.participantIDs
                self.everyoneIDsExceptMe[selectedIndexPath.row] = addPlanVC.everyoneIDsExceptAuthor
            } else {
                self.participantIDs.append([String]())
                self.preparedParticipantIDs.append(addPlanVC.participantIDs)
                self.everyoneIDsExceptMe.append(addPlanVC.everyoneIDsExceptAuthor)
            }
            
            userDefaults.set(self.everyoneIDsExceptMe, forKey: "everyoneIDsExceptMe")
        }
        
        // 場所
        if let place = addPlanVC.place {

            let lat = addPlanVC.lat
            let lon = addPlanVC.lon
            
            if let selectedIndexPath = planTable.indexPathForSelectedRow {
                places[selectedIndexPath.row] = place
                lons[selectedIndexPath.row] = lon
                lats[selectedIndexPath.row] = lat
                
            } else {
                places.append(place)
                lons.append(lon)
                lats.append(lat)
            }
            
            userDefaults.set(places, forKey: "Places")
            userDefaults.set(lons, forKey: "lons")
            userDefaults.set(lats, forKey: "lats")
        }
        
        if let selectedIndexPath = planTable.indexPathForSelectedRow {
            
            print("予定を編集")
            addOrEdit = "edit"
            
            self.selectedIndexPath = selectedIndexPath.row
            
            // 新たに追加した参加候補者
            // まず新旧参加候補者を代入
            var newParticipantIDs = self.toSavePreparedParticipantIDs
            // 旧参加者・旧参加候補者
            var existingIDs = addPlanVC.existingParticipantIDs
            for existingPreparedParticipantID in addPlanVC.existingPreparedParticipantIDs {
                existingIDs.append(existingPreparedParticipantID)
            }
            
            for i in 0...(existingIDs.count - 1) {
                if let index = newParticipantIDs.index(of: existingIDs[i]) {
                    newParticipantIDs[index] = "NO"
                }
            }
            
            while newParticipantIDs.contains("NO") {
                if let index = newParticipantIDs.index(of: "NO") {
                    newParticipantIDs.remove(at: index)
                }
            }
            self.newParticipantIDs = newParticipantIDs
            
            if newParticipantIDs.isEmpty == false {
                
                // 人数分の初期値を入れる
                // planIDsOnDatabase = [[String](), [String](), ...]
                for _ in 0...(newParticipantIDs.count - 1) {
                    planIDsOnDatabase.append([String]())
                    planIDsModifySuccess.append(nil)
                }
                
                // タイマースタート
                savePlanRecordTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(savePlanRecord), userInfo: nil, repeats: true)
                
                for i in 0...(newParticipantIDs.count - 1) {
                    fetchNewParticipantsPlanIDs(accountID: newParticipantIDs[i], index: i, completion: {
                        // データベースの予定ID取得後に編集した予定のIDを追加
                        self.planIDsOnDatabase[i].append(addPlanVC.planID!)
                        
                        // 次の処理
                        self.addNewParticipantsPlanIDToDatabase(accountID: newParticipantIDs[i], index: i)
                    })
                }
            }
            
            // 新たな参加候補者がいないとき
            else {
                // 検索条件を作成
                let predicate = NSPredicate(format: "planID == %@", argumentArray: [myPlanIDs[selectedIndexPath.row]])
                let query = CKQuery(recordType: "Plans", predicate: predicate)
                
                self.publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                    
                    if let error = error {
                        print("予定更新エラー1: \(error)")
                        return
                    }
                    
                    for record in records! {
                        
                        record["planTitle"] = self.planTitles[selectedIndexPath.row] as String
                        record["estimatedTime"] = estimatedTimes[selectedIndexPath.row] as Date
                        record["placeName"] = self.places[selectedIndexPath.row] as String
                        record["placeLatAndLon"] = CLLocation(latitude: Double(self.lats[selectedIndexPath.row])!, longitude: Double(self.lons[selectedIndexPath.row])!)
                        
                        self.publicDatabase.save(record, completionHandler: {(record, error) in
                            
                            if let error = error {
                                print("予定更新エラー2: \(error)")
                                return
                            }
                            print("予定更新成功")
                        })
                    }
                })
                
                planTable.reloadData()
            }
        }
        
        // 新たに予定を作成したとき
        else {
            print("予定を作成")
            addOrEdit = "add"
            
            // 10桁の予定ID生成
            let planID = generatePlanID(length: 10)
            myPlanIDs.append(planID)
            
            userDefaults.set(myPlanIDs, forKey: "PlanIDs")
            
            // 作成者・参加者のIDを格納した配列
            var everyone = [myID!]
            for participantID in self.toSavePreparedParticipantIDs {
                everyone.append(participantID)
            }
            self.everyoneIDs = everyone
            
            // 人数分の初期値を入れる
            // planIDsOnDatabase = [[String](), [String](), ...]
            for _ in 0...(everyone.count - 1) {
                planIDsOnDatabase.append([String]())
                planIDsModifySuccess.append(nil)
            }
            
            // タイマースタート
            savePlanRecordTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(savePlanRecord), userInfo: nil, repeats: true)
            
            for i in 0...(everyone.count - 1) {
                fetchPlanIDs(accountID: everyone[i], index: i, completion: {
                    // データベースの予定ID取得後に新たなIDを追加
                    self.planIDsOnDatabase[i].append(planID)
                    
                    // 次の処理
                    self.addPlanIDToDatabase(accountID: everyone[i], index: i, newPlanID: planID)
                })
            }
            
            planTable.reloadData()
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if userDefaults.object(forKey: "myID") != nil {
            
            myID = userDefaults.string(forKey: "myID")
            print("myID: \(myID!)")
            
            firstWork()
            
            let randomInt = Int.random(in: 0...2)
            
            if randomInt == 0 {
                let applePark = CLLocation(latitude: 37.3349, longitude: -122.00902)
                recordLocation(location: applePark)
            } else if randomInt == 1 {
                let statueOfLiberty = CLLocation(latitude: 40.6907941, longitude: -74.0459015)
                recordLocation(location: statueOfLiberty)
            } else {
                let grandCanyon = CLLocation(latitude: 36.2368592, longitude: -112.1914682)
                recordLocation(location: grandCanyon)
            }
        }
        
        else {
            self.performSegue(withIdentifier: "toFirstVC", sender: nil)
        }

        if userDefaults.object(forKey: "myName") != nil {
            myName = userDefaults.string(forKey: "myName")
            print("myName: \(myName!)")
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        hiddenCountdown()
        estimatedTimesSort.removeAll()
        
        if let indexPath = planTable.indexPathForSelectedRow {
            print("deselect")
            planTable.deselectRow(at: indexPath, animated: true)
        }
        
        // 1秒ごとに処理
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
        // 初回起動時のみFirstVCに遷移
        let firstUserDefaults = UserDefaults.standard
        let firstLaunchKey = "firstLaunch"
        
        if firstUserDefaults.bool(forKey: firstLaunchKey) {
            firstUserDefaults.set(false, forKey: firstLaunchKey)
            firstUserDefaults.synchronize()
            
            self.performSegue(withIdentifier: "toFirstVC", sender: nil)
        }
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let workingTimer = timer {
            workingTimer.invalidate()
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    @IBAction func refresh(_ sender: Any) {
        
        if myID != nil {
            firstWork()
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlanCell", for: indexPath)
        // let img = UIImage(named: participantImgs[indexPath.row] as! String)
        
        let dateAndTimeLabel = cell.viewWithTag(1) as! UILabel
        dateAndTimeLabel.text = self.dateAndTimes[indexPath.row]
        
        let planTitleLabel = cell.viewWithTag(2) as! UILabel
        planTitleLabel.text = self.planTitles[indexPath.row]
        
        let participantIcon = cell.viewWithTag(3) as! UIImageView
        participantIcon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        participantIcon.layer.borderWidth = 1 // 枠線の太さ
        participantIcon.layer.cornerRadius = participantIcon.bounds.width / 2 // 丸くする
        participantIcon.layer.masksToBounds = true // 丸の外側を消す
        
        let participantLabel = cell.viewWithTag(4) as! UILabel
        
        if self.everyoneIDsExceptMe[indexPath.row].count == 0 {
            participantLabel.text = "参加者なし"
        } else if self.everyoneIDsExceptMe[indexPath.row].count == 1 {
            participantLabel.text = self.everyoneIDsExceptMe[indexPath.row][0]
        } else {
            participantLabel.text = "\(self.everyoneIDsExceptMe[indexPath.row][0]) 他"
        }
        
        let placeLabel = cell.viewWithTag(5) as! UILabel
        placeLabel.text = self.places[indexPath.row]
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myPlanIDs.count
    }
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // indicatorの表示位置
            self.indicator.center = self.view.center
            // indicatorのスタイル
            self.indicator.style = .whiteLarge
            // indicatorの色
            self.indicator.color = UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0)
            // indicatorをviewに追加
            self.view.addSubview(self.indicator)
            // indicatorを表示 & アニメーション開始
            self.indicator.startAnimating()
            
            // Plansタイプのレコードから自分のIDを削除
            self.deleteMyIDByPlansRecord(index: indexPath.row, completion: {
                
                // index番目の配列とuserDefaultsを削除
                self.remove(index: indexPath.row, completion: {
                    // 削除後メインスレッドで処理
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        // カウントダウンを非表示
                        self.hiddenCountdown()
                        // セルを削除
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        // indicatorを非表示 & アニメーション終了
                        self.indicator.stopAnimating()
                    }
                })
            })
        }
    }
    
    
    
    @objc func update() {
        
        let now = Date()
        let calendar = Calendar(identifier: .japanese)
        
        estimatedTimesSort.removeAll()
        
        // 予定が登録されているとき
        if estimatedTimes.isEmpty == false {
            // 並べ替え用の配列に予定時刻をセット
            estimatedTimesSort = estimatedTimes
            // 並べ替え用の配列で並べ替え
            estimatedTimesSort.sort { $0 < $1 }
            
            let components = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: now, to: estimatedTimesSort[0])
            
            // 一番近い予定のindexを取得
            if let index = estimatedTimes.index(of: estimatedTimesSort[0]) {
                // 1時間未満のとき
                if components.month! == 0 && components.day! == 0 && components.hour! == 0 &&
                    components.minute! >= 0 && components.minute! <= 59 &&
                    components.second! >= 0 && components.second! <= 59 {
                    // カウントダウンを表示
                    displayCountdown()
                    
                    // 背景をオレンジにする
                    countdownView.backgroundColor = UIColor.init(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0)
                    
                    countdownLabel.text = String(format: "%02d:%02d", components.minute!, components.second!)
                    countdownDateAndTimeLabel.text = dateAndTimes[index]
                    countdownPlanTitleLabel.text = planTitles[index]
                }
                
                // 予定時刻を過ぎたとき
                else if components.month! <= 0 && components.day! <= 0 && components.hour! <= 0 && components.minute! <= 0 && components.second! <= 0 {
                    print("予定時刻を過ぎた")
                    
                    displayCountdown()
                    
                    if countdownView.isHidden == false {
                        // 背景を赤にする
                        countdownView.backgroundColor = UIColor.init(hue: 0.03, saturation: 0.9, brightness: 0.9, alpha: 1.0)
                        
                        countdownLabel.text = "00:00"
                        countdownDateAndTimeLabel.text = dateAndTimes[index]
                        countdownPlanTitleLabel.text = planTitles[index]
                    }
                }
                
                else {
                    // カウントダウンを非表示
                    hiddenCountdown()
                }
            }
        }
        
        // 予定がひとつも登録されていないとき
        else {
            print("予定なし")
            // カウントダウンを非表示
            hiddenCountdown()
        }
    }
    
    
    
    @IBAction func tappedCompleteButton(_ sender: Any) {
        
        let dialog = UIAlertController(title: "待ち合わせ完了", message: "待ち合わせはできましたか？\n予定を削除します。", preferredStyle: .alert)
        
        // キャンセルボタン
        let cancel = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        // 削除ボタン
        let delete = UIAlertAction(title: "削除", style: .destructive, handler: { action in
            
            // 並べ替え用の配列に予定時刻をセット
            estimatedTimesSort = estimatedTimes
            // 並べ替え用の配列で並べ替え
            estimatedTimesSort.sort { $0 < $1 }
            
            // 一番近い予定のindexを取得
            if let index = estimatedTimes.index(of: estimatedTimesSort[0]) {
                
                // indicatorの表示位置
                self.indicator.center = self.view.center
                // indicatorのスタイル
                self.indicator.style = .whiteLarge
                // indicatorの色
                self.indicator.color = UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0)
                // indicatorをviewに追加
                self.view.addSubview(self.indicator)
                // indicatorを表示 & アニメーション開始
                self.indicator.startAnimating()
                
                // Plansタイプのレコードから自分のIDを削除
                self.deleteMyIDByPlansRecord(index: index, completion: {
                    
                    // index番目の配列とuserDefaultsを削除
                    self.remove(index: index, completion: {
                        // 削除後メインスレッドで処理
                        DispatchQueue.main.async { [weak self] in
                            guard let `self` = self else { return }
                            // カウントダウンを非表示
                            self.hiddenCountdown()
                            // UI更新
                            self.planTable.reloadData()
                            // indicatorを非表示 & アニメーション終了
                            self.indicator.stopAnimating()
                        }
                    })
                })
            }
        })
        
        // Actionを追加
        dialog.addAction(cancel)
        dialog.addAction(delete)
        // ダイアログを表示
        self.present(dialog, animated: true, completion: nil)
    }
    
    
    
    // ついでに予定候補IDも取得
    func fetchRequests() {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だち申請取得エラー: \(error)")
                return
            }
            
            if let request01 = record?.value(forKey: "requestedAccountID_01") as? String {
                self.fetchedRequests[0] = request01
            }
            if let request02 = record?.value(forKey: "requestedAccountID_02") as? String {
                self.fetchedRequests[1] = request02
            }
            if let request03 = record?.value(forKey: "requestedAccountID_03") as? String {
                self.fetchedRequests[2] = request03
            }
            print("友だち申請: \(self.fetchedRequests)")
            
            // 申請者のIDのみ配列に残す
            while self.fetchedRequests.contains("NO") {
                if let index = self.fetchedRequests.index(of: "NO") {
                    self.fetchedRequests.remove(at: index)
                }
            }
            
            self.fetchRequestsCheck = true
            
            if let preparedPlanIDs = record?.value(forKey: "preparedPlanIDs") as? [String] {
                for preparedPlanID in preparedPlanIDs {
                    self.fetchedPreparedPlanIDs.append(preparedPlanID)
                }
            }
        })
    }
    
    
    
    @objc func fetchingRequests() {
        print("Now fetching requests")
        
        if fetchRequestsCheck == true {
            
            print("Completed fetching requests!")
            
            // タイマーを止める
            if let workingTimer = fetchRequestsTimer {
                workingTimer.invalidate()
            }
            
            // 予定候補がある・友だち申請されている場合は遷移
            if fetchedPreparedPlanIDs.isEmpty == false {
                self.performSegue(withIdentifier: "toApprovePlanVC", sender: nil)
            } else if fetchedRequests.isEmpty == false {
                self.performSegue(withIdentifier: "toRequestedVC", sender: nil)
            } else {
                print("友だち申請・予定候補なし")
            }
        }
    }
    
    
    
    func fetchFriendIDs(id: String) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(id)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("友だち一覧取得エラー: \(error)")
                return
            }
            
            if let friendIDs = record?.value(forKey: "friends") as? [String] {
                for friendID in friendIDs {
                    self.friendIDs.append(friendID)
                }
                print("友だち: \(self.friendIDs)")
            } else {
                print("友だち0人")
            }
        })
    }
    
    
    
    // ついでにお気に入りも取得
    func fetchMyPlanIDs(completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(myID!)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("自分の予定一覧取得エラー: \(error)")
                return
            }
            
            if let planIDs = record?.value(forKey: "planIDs") as? [String] {
                
                myPlanIDs.removeAll()
                
                for myPlanID in planIDs {
                    myPlanIDs.append(myPlanID)
                }
                
                completion()
                
            } else {
                print("データベースの予定なし")
                self.noPlansOnDatabase = true
            }
            
            if let favPlaceNames = record?.value(forKey: "favPlaceNames") as? [String],
               let favPlaceLocations = record?.value(forKey: "favPlaceLocations") as? [CLLocation] {
                
                favPlaces.removeAll()
                favAddresses.removeAll()
                favLats.removeAll()
                favLons.removeAll()
                
                for favPlace in favPlaceNames {
                    favPlaces.append(favPlace)
                }
                
                var favLocations = [CLLocation]()    // 逆ジオコーディング用
                for favLocation in favPlaceLocations {
                    favAddresses.append("住所が取得できません")
                    favLats.append(favLocation.coordinate.latitude)
                    favLons.append(favLocation.coordinate.longitude)
                    favLocations.append(favLocation)
                }
                
                // CLLocationから住所を特定
                if favLocations.isEmpty == false {
                    
                    for i in 0...(favLocations.count - 1) {
                        
                        let geocoder = CLGeocoder()
                        
                        geocoder.reverseGeocodeLocation(favLocations[i], preferredLocale: nil, completionHandler: {(placemarks, error) in
                            
                            if let error = error {
                                print("お気に入りの住所取得エラー: \(error)")
                                return
                            }
                            
                            if let placemark = placemarks?.first,
                               let administrativeArea = placemark.administrativeArea,    //県
                               let locality = placemark.locality,    // 市区町村
                               let throughfare = placemark.thoroughfare,    // 丁目を含む地名
                               let subThoroughfare = placemark.subThoroughfare {    // 番地
                                
                                favAddresses[i] = administrativeArea + locality + throughfare + subThoroughfare
                            }
                        })
                    }
                }
                
                userDefaults.set(favPlaces, forKey: "favPlaces")
                userDefaults.set(favAddresses, forKey: "favAddresses")
                userDefaults.set(favLats, forKey: "favLats")
                userDefaults.set(favLons, forKey: "favLons")
            }
        })
    }
    
    
    
    func fetchMyPlanDetails(index: Int, completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "planID-\(myPlanIDs[index])")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("自分の\(index)番目の予定取得エラー: \(error)")
                return
            }
            
            if let estimatedTime = record?.value(forKey: "estimatedTime") as? Date {
                estimatedTimes[index] = estimatedTime
            }
            
            if let planTitle = record?.value(forKey: "planTitle") as? String {
                self.planTitles[index] = planTitle
            }
            
            var everyone = [String]()
            
            if let authorID = record?.value(forKey: "authorID") as? String {
                everyone.append(authorID)
            }
            
            if let participantIDs = record?.value(forKey: "participantIDs") as? [String] {
                for participantID in participantIDs {
                    everyone.append(participantID)
                    self.participantIDs[index].append(participantID)
                }
            }
            
            if let preparedParticipantIDs = record?.value(forKey: "preparedParticipantIDs") as? [String] {
                for preparedParticipantID in preparedParticipantIDs {
                    everyone.append(preparedParticipantID)
                    self.preparedParticipantIDs[index].append(preparedParticipantID)
                }
            }
            
            if let myIndex = everyone.index(of: myID!) {
                everyone.remove(at: myIndex)
                self.everyoneIDsExceptMe[index] = everyone
            }
            
            if let place = record?.value(forKey: "placeName") as? String {
                self.places[index] = place
            }
            
            if let location = record?.value(forKey: "placeLatAndLon") as? CLLocation {
                self.lats[index] = location.coordinate.latitude.description
                self.lons[index] = location.coordinate.longitude.description
            }
            
            completion()
        })
    }
    
    
    
    @objc func fetchingPlans() {
        print("Now fetching plans...")
        
        fetchPlansTimerCount += 0.5
        
        // データベースの予定取得に20秒以上かかったとき
        if fetchPlansTimerCount >= 20.0 {
            print("Failed fetching plans!")
            
            // タイマーを止める
            if let workingTimer = fetchPlansTimer {
                workingTimer.invalidate()
            }
            
            // ローカルで予定を読み込む
            readUserDefaults()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                // UI更新
                self.planTable.reloadData()
                // indicatorを非表示 & アニメーション終了
                self.indicator.stopAnimating()
            })
        }
        
        else if fetchPlansCheck.isEmpty == false && fetchPlansCheck.contains(false) == false {
            print("Completed fetching plans!")
            
            // タイマーを止める
            if let workingTimer = fetchPlansTimer {
                workingTimer.invalidate()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                // UI更新
                self.planTable.reloadData()
                // indicatorを非表示 & アニメーション終了
                self.indicator.stopAnimating()
            })
        }
        
        else if noPlansOnDatabase == true {
            print("There are no plans on database!")
            
            // タイマーを止める
            if let workingTimer = fetchPlansTimer {
                workingTimer.invalidate()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                // UI更新
                self.planTable.reloadData()
                // indicatorを非表示 & アニメーション終了
                self.indicator.stopAnimating()
            })
        }
    }
    
    
    // 予定作成・編集時に参加者のレコードを編集したあと予定のレコードを追加（編集）する
    @objc func savePlanRecord() {
        print("Now saving user's record...")
        
        // すべてにtrueかfalseが入ったら
        if self.planIDsModifySuccess.contains(nil) == false {
            
            if let workingTimer = self.savePlanRecordTimer {
                workingTimer.invalidate()
            }
            
            // 予定を作成
            if self.addOrEdit == "add" {
                
                print("add!")
                
                if let newPlanID = myPlanIDs.last,
                   let newPlanTitle = self.planTitles.last,
                   let newEstimatedTime = estimatedTimes.last,
                   let newPlaceName = self.places.last,
                   let newLat = self.lats.last,
                   let newLon = self.lons.last {
                    
                    let recordID = CKRecord.ID(recordName: "planID-\(newPlanID)")
                    let record = CKRecord(recordType: "Plans", recordID: recordID)
                    
                    record["planID"] = newPlanID as String
                    record["planTitle"] = newPlanTitle as String
                    record["estimatedTime"] = newEstimatedTime as Date
                    record["authorID"] = myID! as String
                    record["placeName"] = newPlaceName as String
                    record["placeLatAndLon"] = CLLocation(latitude: Double(newLat)!, longitude: Double(newLon)!)
                    
                    // planIDsModifySuccess[0]は予定作成者なので無視
                    for i in 1...(self.planIDsModifySuccess.count - 1) {
                        if self.planIDsModifySuccess[i] == false {
                            if let index = self.toSavePreparedParticipantIDs.index(of: self.everyoneIDs[i]) {
                                self.toSavePreparedParticipantIDs.remove(at: index)
                                print("\(everyoneIDs[index])をremove")
                                self.alert(title: "参加者のエラー", message: "\(everyoneIDs[i])を参加者に指定することができませんでした。\n相手が待ち合わせ中の場合、このエラーが発生することがあります。時間をおいて、予定を編集する際にもう一度参加者に指定してみてください。")
                            }
                        }
                    }
                    record["preparedParticipantIDs"] = toSavePreparedParticipantIDs as [String]
                    
                    // レコードを保存
                    self.publicDatabase.save(record, completionHandler: {(record, error) in
                        
                        if let error = error {
                            print("Plansタイプ予定保存エラー: \(error)")
                            return
                        }
                        print("Plansタイプ予定保存成功")
                    })
                    
                    // 日付のフォーマット
                    let formatter = DateFormatter()
                    // 現地仕様で日付の出力
                    formatter.timeStyle = .short
                    formatter.dateStyle = .medium
                    formatter.timeZone = NSTimeZone.local
                    formatter.locale = Locale(identifier: "ja_JP")
                    
                    // 参加候補者に通知
                    for participant in toSavePreparedParticipantIDs {
                        
                        let predicate = NSPredicate(format: "destination == %@", argumentArray: [participant])
                        let query = CKQuery(recordType: "Notifications", predicate: predicate)
                        
                        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(nRecords, error) in
                            
                            if let error = error {
                                print("通知エラー1: \(error)")
                                return
                            }
                            
                            for nRecord in nRecords! {
                                
                                nRecord["notificationTitle"] = "\(myID!) が〈\(newPlanTitle)〉への参加を求めています" as String
                                nRecord["notificationContent"] = "\(formatter.string(from: newEstimatedTime)) \(newPlaceName)"
                                
                                self.publicDatabase.save(nRecord, completionHandler: {(record, error) in
                                    
                                    if let error = error {
                                        print("通知エラー2: \(error)")
                                        return
                                    }
                                    print("通知レコード更新成功")
                                })
                            }
                        })
                    }
                }
            }
            
            // 予定を編集
            else if self.addOrEdit == "edit" {
                
                let editedPlanID = myPlanIDs[selectedIndexPath!]
                let editedPlanTitle = self.planTitles[selectedIndexPath!]
                let editedEstimatedTime = estimatedTimes[selectedIndexPath!]
                let editedPlaceName = self.places[selectedIndexPath!]
                let editedLat = self.lats[selectedIndexPath!]
                let editedLon = self.lons[selectedIndexPath!]
                
                print(editedEstimatedTime)
                    
                let predicate = NSPredicate(format: "planID == %@", argumentArray: [editedPlanID])
                let query = CKQuery(recordType: "Plans", predicate: predicate)
                
                self.publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                    
                    if let error = error {
                        print("予定更新エラー1: \(error)")
                        return
                    }
                    
                    for record in records! {
                        
                        record["planTitle"] = editedPlanTitle as String
                        record["estimatedTime"] = editedEstimatedTime as Date
                        record["placeName"] = editedPlaceName as String
                        record["placeLatAndLon"] = CLLocation(latitude: Double(editedLat)!, longitude: Double(editedLon)!)
                        
                        for i in 0...(self.planIDsModifySuccess.count - 1) {
                            if self.planIDsModifySuccess[i] == false {
                                if let index = self.toSavePreparedParticipantIDs.index(of: self.newParticipantIDs[i]) {
                                    self.toSavePreparedParticipantIDs.remove(at: index)
                                    print("\(self.newParticipantIDs[index])をremove")
                                    // メインスレッドで処理
                                    DispatchQueue.main.async { [weak self] in
                                        guard let `self` = self else { return }
                                        self.alert(title: "参加者のエラー", message: "\(self.newParticipantIDs[i])を参加者に指定することができませんでした。\n相手が待ち合わせ中の場合、このエラーが発生することがあります。時間をおいて、予定を編集する際にもう一度参加者に指定してみてください。")
                                    }
                                }
                            }
                        }
                        record["preparedParticipantIDs"] = self.toSavePreparedParticipantIDs as [String]
                        
                        self.publicDatabase.save(record, completionHandler: {(record, error) in
                            
                            if let error = error {
                                print("予定更新エラー2: \(error)")
                                return
                            }
                            print("予定更新成功")
                        })
                    }
                })
                
                // 日付のフォーマット
                let formatter = DateFormatter()
                // 現地仕様で日付の出力
                formatter.timeStyle = .short
                formatter.dateStyle = .medium
                formatter.timeZone = NSTimeZone.local
                formatter.locale = Locale(identifier: "ja_JP")
                
                // 参加候補者に通知
                for participant in toSavePreparedParticipantIDs {
                    
                    let predicate = NSPredicate(format: "destination == %@", argumentArray: [participant])
                    let query = CKQuery(recordType: "Notifications", predicate: predicate)
                    
                    publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(nRecords, error) in
                        
                        if let error = error {
                            print("通知エラー1: \(error)")
                            return
                        }
                        
                        for nRecord in nRecords! {
                            
                            nRecord["notificationTitle"] = "\(myName!) が〈\(editedPlanTitle)〉への参加を求めています" as String
                            nRecord["notificationContent"] = "\(formatter.string(from: editedEstimatedTime))　\(editedPlaceName)"
                            
                            self.publicDatabase.save(nRecord, completionHandler: {(record, error) in
                                
                                if let error = error {
                                    print("通知エラー2: \(error)")
                                    return
                                }
                                print("通知レコード更新成功")
                            })
                        }
                    })
                }
                
                planTable.reloadData()
            }
        }
    }
    
    
    
    // 予定作成時
    func fetchPlanIDs(accountID: String, index: Int, completion: @escaping () -> ()) {
        print("\(accountID)の予定一覧取得開始")
        
        let recordID = CKRecord.ID(recordName: "accountID-\(accountID)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("予定取得エラー: \(error)")
                self.planIDsModifySuccess[index] = false
                return
            }
            
            // 作成者
            if index == 0 {
                
                if let planIDs = record?.value(forKey: "planIDs") as? [String] {
                    
                    for planID in planIDs {
                        self.planIDsOnDatabase[index].append(planID)
                    }
                } else {
                    print("\(accountID)のデータベースの予定なし")
                }
            }
            
            // 参加候補者
            else {
                
                if let preparedPlanIDs = record?.value(forKey: "preparedPlanIDs") as? [String] {
                    
                    for preparedPlanID in preparedPlanIDs {
                        self.planIDsOnDatabase[index].append(preparedPlanID)
                    }
                } else {
                    print("\(accountID)のデータベースの予定予備軍なし")
                }
            }
            
            print("\(accountID)の予定一覧取得完了")
            completion()
        })
    }
    
    
    
    // 予定編集時
    func fetchNewParticipantsPlanIDs(accountID: String, index: Int, completion: @escaping () -> ()) {
        print("\(accountID)の予定一覧取得開始")
        
        let recordID = CKRecord.ID(recordName: "accountID-\(accountID)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("\(accountID)の予定取得エラー: \(error)")
                self.planIDsModifySuccess[index] = false
                return
            }
            
            if let preparedPlanIDs = record?.value(forKey: "preparedPlanIDs") as? [String] {
                
                for preparedPlanID in preparedPlanIDs {
                    self.planIDsOnDatabase[index].append(preparedPlanID)
                }
            } else {
                print("\(accountID)のデータベースの予定予備軍なし")
            }
            
            print("\(accountID)の予定一覧取得完了")
            completion()
        })
    }
    
    
    
    // 予定作成時
    func addPlanIDToDatabase(accountID: String, index: Int, newPlanID: String) {
        print("\(accountID)の予定一覧保存開始")
        
        // 検索条件を作成
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [accountID])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        // データベースの予定一覧にIDを追加
        self.publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("\(accountID)のデータベースの予定ID追加エラー1: \(error)")
                self.planIDsModifySuccess[index] = false
                return
            }
            
            for record in records! {
                
                // 作成者
                if index == 0 {
                    record["planIDs"] = self.planIDsOnDatabase[index] as [String]
                }
                
                // 参加候補者
                else {
                    record["preparedPlanIDs"] = self.planIDsOnDatabase[index] as [String]
                }
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("\(accountID)のデータベースの予定ID追加エラー2: \(error)")
                        self.planIDsModifySuccess[index] = false
                        return
                    }
                    print("\(accountID)のデータベースの予定ID追加成功")
                    self.planIDsModifySuccess[index] = true
                })
            }
        })
    }
    
    
    
    // 予定編集時
    func addNewParticipantsPlanIDToDatabase(accountID: String, index: Int) {
        print("\(accountID)の予定一覧保存開始")
        
        // 検索条件を作成
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [accountID])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        self.publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("\(accountID)のデータベースの予定ID追加エラー1: \(error)")
                self.planIDsModifySuccess[index] = false
                return
            }
            
            for record in records! {
                
                record["preparedPlanIDs"] = self.planIDsOnDatabase[index] as [String]
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("\(accountID)のデータベースの予定ID追加エラー2: \(error)")
                        self.planIDsModifySuccess[index] = false
                        return
                    }
                    print("\(accountID)のデータベースの予定ID追加成功")
                    self.planIDsModifySuccess[index] = true
                })
            }
        })
    }
    
    
    
    // 友だち（申請者）の友だち一覧を取得
    func fetchApplicantFriendIDs(count: Int, completion: @escaping () -> ()) {
        
        let applicantID = CKRecord.ID(recordName: "accountID-\(requestedIDs[count])")
        
        publicDatabase.fetch(withRecordID: applicantID, completionHandler: {(record, error) in
            
            if let error = error {
                print("\(self.requestedIDs[count])の友だち一覧取得エラー: \(error)")
                return
            }
            
            if let applicantFriendIDs = record?.value(forKey: "friends") as? [String] {
                
                for appicantFriendID in applicantFriendIDs {
                    self.fetchedApplicantFriendIDs[count].append(appicantFriendID)
                }
                print("\(self.requestedIDs[count])の友だち一覧取得成功")
                completion()
            }
            
            else {
                print("\(self.requestedIDs[count])の友だち0人")
                completion()
            }
        })
    }
    
    
    
    // 友だち（申請者）の友だち一覧を更新
    func reloadApplicantFriendIDs(count: Int) {
        
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [requestedIDs[count]])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("\(self.requestedIDs[count])の友だち一覧更新エラー1: \(error)")
                return
            }
            
            for record in records! {
                
                record["friends"] = self.fetchedApplicantFriendIDs[count] as [String]
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("\(self.requestedIDs[count])の友だち一覧更新エラー2: \(error)")
                        return
                    }
                    print("\(self.requestedIDs[count])の友だち一覧更新成功")
                })
            }
        })
    }
    
    
    
    // 予定承認・拒否（自分のレコード）
    func addApprovedPlanID(completion: @escaping () -> ()) {
        
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("予定承認（Accounts）エラー1: \(error)")
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "予定を承認できませんでした。\n待ち合わせ中の場合、このエラーが発生することがあります。\n時間をおいて右上の更新ボタンを押すと、再び予定承認可否の画面が出てきます。")
                    self.firstWork()
                }
                return
            }
            
            for record in records! {
                
                record["planIDs"] = myPlanIDs as [String]
                record["preparedPlanIDs"] = self.fetchedPreparedPlanIDs as [String]
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("予定承認（Accounts）エラー2: \(error)")
                        DispatchQueue.main.async {
                            self.alert(title: "エラー", message: "予定を承認できませんでした。\n待ち合わせ中の場合、このエラーが発生することがあります。\n時間をおいて右上の更新ボタンを押すと、再び予定承認可否の画面が出てきます。")
                            self.firstWork()
                        }
                        return
                    }
                    print("予定承認（Accounts）成功")
                    completion()
                })
            }
        })
    }
    
    
    
    // 位置情報をアメリカにする
    func recordLocation(location: CLLocation) {
        
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("レコードの位置情報更新エラー1: \(error)")
                return
            }
            
            for record in records! {
                
                record["currentLocation"] = location as CLLocation
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("レコードの位置情報更新エラー2: \(error)")
                        return
                    }
                    print("レコードの位置情報更新成功")
                })
            }
        })
    }
    
    
    
    // 予定を削除したとき、Plansタイプから自分のIDを削除
    func deleteMyIDByPlansRecord(index: Int, completion: @escaping () -> ()) {
        
        var participantIDsOfRemovedPlan = self.participantIDs[index]
        
        if let i = participantIDsOfRemovedPlan.index(of: myID!) {
            participantIDsOfRemovedPlan.remove(at: i)
        }
        
        let predicate = NSPredicate(format: "planID == %@", argumentArray: [myPlanIDs[index]])
        let query = CKQuery(recordType: "Plans", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("Plansタイプのレコードから自分のID削除エラー: \(error)")
                return
            }
            
            for record in records! {
                
                record["participantIDs"] = participantIDsOfRemovedPlan as [String]
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("Plansタイプのレコードから自分のID削除エラー: \(error)")
                        return
                    }
                    print("Plansタイプのレコードから自分のID削除成功")
                    completion()
                })
            }
        })
    }
    
    
    
    func generatePlanID(length: Int) -> String {
        let characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        return String((0 ..< length).map { _ in characters.randomElement()! })
    }
    
    
    
    func displayCountdown() {
        
        countdownViewHeight.constant = 200
        countdownLabel.isHidden = false
        countdownDateAndTimeLabel.isHidden = false
        countdownPlanTitleLabel.isHidden = false
        completeButton.isHidden = false
        completeButton.isEnabled = true
    }
    
    
    
    func hiddenCountdown() {
        
        countdownViewHeight.constant = 0
        countdownLabel.isHidden = true
        countdownDateAndTimeLabel.isHidden = true
        countdownPlanTitleLabel.isHidden = true
        completeButton.isHidden = true
        completeButton.isEnabled = false
    }
    
    
    
    func firstWork() {
        
        // ------------------------------ ↓ 初期化関連 ------------------------------
        
        // 予定関連初期化
        myPlanIDs.removeAll()
        self.dateAndTimes.removeAll()
        estimatedTimes.removeAll()
        self.planTitles.removeAll()
        self.everyoneIDsExceptMe.removeAll()
        self.places.removeAll()
        self.lats.removeAll()
        self.lons.removeAll()
        
        self.planTable.reloadData()
        
        // 友だち申請関連初期化
        if let workingTimer1 = fetchRequestsTimer {
            workingTimer1.invalidate()
        }
        fetchedRequests = ["NO", "NO", "NO"]
        fetchRequestsCheck = false
        
        // 予定候補ID初期化
        fetchedPreparedPlanIDs.removeAll()
        
        // 友だち一覧初期化
        friendIDs.removeAll()
        
        // 予定取得関連初期化
        if let workingTimer2 = fetchPlansTimer {
            workingTimer2.invalidate()
        }
        fetchPlansTimerCount = 0.0
        fetchPlansCheck.removeAll()
        noPlansOnDatabase = nil
        
        // ------------------------------ ↓ 取得開始 ------------------------------
        
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
        
        // 友だち申請取得監視タイマースタート
        fetchRequestsTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingRequests), userInfo: nil, repeats: true)
        
        // 友だち申請をデータベースから取得
        fetchRequests()
        
        // 友だち一覧をデータベースから取得
        fetchFriendIDs(id: myID!)
        
        // 予定一覧取得監視タイマースタート
        fetchPlansTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fetchingPlans), userInfo: nil, repeats: true)
        
        // 予定一覧をデータベースから取得
        fetchMyPlanIDs(completion: {
            
            // ID取得が終わったら他の配列に適当な初期値を代入
            self.dateAndTimes.removeAll()
            estimatedTimes.removeAll()
            self.planTitles.removeAll()
            self.everyoneIDsExceptMe.removeAll()
            self.places.removeAll()
            self.lats.removeAll()
            self.lons.removeAll()
            
            if myPlanIDs.isEmpty == false {
                
                for _ in 0...(myPlanIDs.count - 1) {
                    self.dateAndTimes.append("日時")
                    estimatedTimes.append(Date(timeIntervalSinceNow: 7200.0))   // 2時間（7200秒）後
                    self.planTitles.append("予定サンプル")
                    self.everyoneIDsExceptMe.append([String]())
                    self.participantIDs.append([String]())
                    self.preparedParticipantIDs.append([String]())
                    self.places.append("場所")
                    self.lats.append("緯度")
                    self.lons.append("経度")
                    self.fetchPlansCheck.append(false)
                }
                
                // 予定の詳細を取得
                for i in 0...(myPlanIDs.count - 1) {
                    self.fetchMyPlanDetails(index: i, completion: {
                        // estimatedTimeから文字列に
                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        formatter.dateStyle = .full
                        formatter.timeZone = NSTimeZone.local
                        formatter.locale = Locale(identifier: "ja_JP")
                        self.dateAndTimes[i] = formatter.string(from: estimatedTimes[i])
                        
                        // UserDefaultsに保存
                        userDefaults.set(myPlanIDs, forKey: "PlanIDs")
                        userDefaults.set(self.dateAndTimes, forKey: "DateAndTimes")
                        userDefaults.set(estimatedTimes, forKey: "EstimatedTimes")
                        userDefaults.set(self.planTitles, forKey: "PlanTitles")
                        userDefaults.set(self.everyoneIDsExceptMe, forKey: "everyoneIDsExceptMe")
                        userDefaults.set(self.places, forKey: "Places")
                        userDefaults.set(self.lats, forKey: "lats")
                        userDefaults.set(self.lons, forKey: "lons")
                        
                        // 完了チェック
                        self.fetchPlansCheck[i] = true
                    })
                }
            }
            
            // データベースの予定IDが空のとき
            else {
                print("データベースに予定なし")
                
                // タイマーを止める
                if let workingTimer = self.fetchPlansTimer {
                    workingTimer.invalidate()
                }
                
                // メインスレッドで処理
                DispatchQueue.main.async {
                    // indicatorを非表示 & アニメーション終了
                    self.indicator.stopAnimating()
                }
            }
        })
    }
    
    
    
    func readUserDefaults() {
        
        if userDefaults.object(forKey: "myName") != nil {
            myName = userDefaults.string(forKey: "myName")
            print("myName: \(myName!)")
        }
        
        if userDefaults.object(forKey: "PlanIDs") != nil {
            myPlanIDs = userDefaults.stringArray(forKey: "PlanIDs")!
        }
        
        if userDefaults.object(forKey: "DateAndTimes") != nil {
            self.dateAndTimes = userDefaults.stringArray(forKey: "DateAndTimes")!
        }
        
        if userDefaults.object(forKey: "EstimatedTimes") != nil {
            estimatedTimes = userDefaults.array(forKey: "EstimatedTimes") as! [Date]
        }
        
        if userDefaults.object(forKey: "PlanTitles") != nil {
            self.planTitles = userDefaults.stringArray(forKey: "PlanTitles")!
        }
        
        if userDefaults.object(forKey: "everyoneIDsExceptMe") != nil {
            self.everyoneIDsExceptMe = userDefaults.array(forKey: "everyoneIDsExceptMe") as! [[String]]
        }
        
        if userDefaults.object(forKey: "Places") != nil {
            self.places = userDefaults.stringArray(forKey: "Places")!
        }
        
        if userDefaults.object(forKey: "lats") != nil, userDefaults.object(forKey: "lons") != nil {
            self.lats = userDefaults.stringArray(forKey: "lats")!
            self.lons = userDefaults.stringArray(forKey: "lons")!
        }
        
        if userDefaults.object(forKey: "favPlaces") != nil {
            favPlaces = userDefaults.stringArray(forKey: "favPlaces")!
        }
        
        if userDefaults.object(forKey: "favAddresses") != nil {
            favAddresses = userDefaults.stringArray(forKey: "favAddresses")!
        }
        
        if userDefaults.object(forKey: "favLats") != nil {
            favLats = userDefaults.array(forKey: "favLats") as! [Double]
        }
        
        if userDefaults.object(forKey: "favLons") != nil {
            favLons = userDefaults.array(forKey: "favLons") as! [Double]
        }
    }
    
    
    
    func remove(index: Int, completion: @escaping () -> ()) {
        
        myPlanIDs.remove(at: index)
        userDefaults.set(myPlanIDs, forKey: "PlanIDs")
        
        dateAndTimes.remove(at: index)
        userDefaults.set(dateAndTimes, forKey: "DateAndTimes")
        
        estimatedTimes.remove(at: index)
        userDefaults.set(estimatedTimes, forKey: "EstimatedTimes")
        
        self.planTitles.remove(at: index)
        userDefaults.set(self.planTitles, forKey: "PlanTitles")
        
        self.everyoneIDsExceptMe.remove(at: index)
        userDefaults.set(self.everyoneIDsExceptMe, forKey: "everyoneIDsExceptMe")
        
        self.places.remove(at: index)
        userDefaults.set(self.places, forKey: "Places")
        
        self.lons.remove(at: index)
        userDefaults.set(self.lons, forKey: "lons")
        
        self.lats.remove(at: index)
        userDefaults.set(self.lats, forKey: "lats")
        
        // 検索条件を作成
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        // データベースの予定一覧からIDを削除
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("データベースの予定ID削除エラー1: \(error)")
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "予定の削除に失敗しました。時間をおいてもう一度お試しください。")
                    self.indicator.stopAnimating()
                }
                return
            }
            
            for record in records! {
                
                record["planIDs"] = myPlanIDs as [String]
                
                let randomInt = Int.random(in: 0...2)
                
                if randomInt == 0 {
                    let applePark = CLLocation(latitude: 37.3349, longitude: -122.00902)
                    record["currentLocation"] = applePark as CLLocation
                } else if randomInt == 1 {
                    let statueOfLiberty = CLLocation(latitude: 40.6907941, longitude: -74.0459015)
                    record["currentLocation"] = statueOfLiberty as CLLocation
                } else {
                    let grandCanyon = CLLocation(latitude: 36.2368592, longitude: -112.1914682)
                    record["currentLocation"] = grandCanyon as CLLocation
                }
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("データベースの予定ID削除エラー2: \(error)")
                        DispatchQueue.main.async {
                            self.alert(title: "エラー", message: "予定の削除に失敗しました。時間をおいてもう一度お試しください。")
                            self.indicator.stopAnimating()
                        }
                        return
                    }
                    print("データベースの予定ID削除成功")
                    completion()
                })
            }
        })
    }
    
    
    
    // アカウントのレコード作成
    func createAccountRecord(id: String, name: String, password: String, completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(id)")
        let record = CKRecord(recordType: "Accounts", recordID: recordID)
        
        record["accountID"] = id as String
        record["accountName"] = name as String
        record["password"] = password as String
        record["currentLocation"] = CLLocation(latitude: 37.3349, longitude: -122.00902)
        record["requestedAccountID_01"] = "NO" as String
        record["requestedAccountID_02"] = "NO" as String
        record["requestedAccountID_03"] = "NO" as String
        record["favPlaceNames"] = ["東京タワー（お気に入りサンプル）"] as [String]
        record["favPlaceLocations"] = [CLLocation(latitude: 35.658584, longitude: 139.7454316)] as [CLLocation]
        
        // レコードを作成
        publicDatabase.save(record, completionHandler: {(record, error) in
            
            if let error = error {
                print("新規レコード保存エラー: \(error)")
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "申し訳ございませんが、アカウント作成に失敗してしまったようです🥺\nアプリを一旦終了（タスクキル）し、再び起動するともう一度挑戦できます。")
                }
                return
            }
            print("新規レコード（アカウント）作成成功")
            completion()
        })
    }
    
    
    
    // 通知のレコード作成
    func createNotificationRecord(id: String, completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "notification-\(id)")
        let record = CKRecord(recordType: "Notifications", recordID: recordID)
        
        record["destination"] = id as String
        
        // レコードを作成
        publicDatabase.save(record, completionHandler: {(record, error) in
            
            if let error = error {
                print("新規レコード（通知）保存エラー: \(error)")
                
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "申し訳ございませんが、アカウント作成に失敗してしまったようです🥺\nアプリを一旦終了（タスクキル）し、再び起動するともう一度挑戦できます。")
                }
                
                // アカウントのレコード削除
                self.deleteAccountRecordInTheCreating(id: id)
                
                return
            }
            print("新規レコード（通知）作成成功")
            completion()
        })
    }
    
    
    
    // アカウントのレコード削除（通知レコード作成で失敗したとき）
    func deleteAccountRecordInTheCreating(id: String) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(id)")
        
        publicDatabase.delete(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("レコード（アカウント）削除エラー: \(error)")
                return
            }
            print("レコード（アカウント）削除成功")
        })
    }
    
    
    
    // アカウント作成時に登録済みID一覧を取得
    func fetchExistingIDs(completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "all-varmeetsIDsList")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(existingIDs, error) in
            
            if let error = error {
                print("アカウントリスト取得エラー: \(error)")
                DispatchQueue.main.async {
                    self.alert(title: "エラー", message: "申し訳ございませんが、アカウント作成に失敗してしまったようです🥺\nアプリを一旦終了（タスクキル）し、再び起動するともう一度挑戦できます。")
                }
                return
            }
            
            if let existingIDs = existingIDs?.value(forKey: "accounts") as? [String] {
                self.existingIDs = existingIDs
                completion()
            }
        })
    }
    
    
    
    func alert(title: String?, message: String?) {
        
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // OKボタン
        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        // ダイアログを表示
        self.present(dialog, animated: true, completion: nil)
    }
    
    
    
    func requestNotifications() {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound], completionHandler: { granted, error in
            
            if let error = error {
                print("通知許可エラー: \(error)")
                return
            }
            
            guard granted else { return }
            
            DispatchQueue.main.async(execute: {
                UIApplication.shared.registerForRemoteNotifications()
            })
        })
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "toPlanDetails" {
            let planDetailsVC = segue.destination as! PlanDetailsViewController
            planDetailsVC.planID = myPlanIDs[(planTable.indexPathForSelectedRow?.row)!]
            planDetailsVC.dateAndTime = dateAndTimes[(planTable.indexPathForSelectedRow?.row)!]
            planDetailsVC.estimatedTime = estimatedTimes[(planTable.indexPathForSelectedRow?.row)!]
            planDetailsVC.planTitle = planTitles[(planTable.indexPathForSelectedRow?.row)!]
            planDetailsVC.place = places[(planTable.indexPathForSelectedRow?.row)!]
            planDetailsVC.lonStr = lons[(planTable.indexPathForSelectedRow?.row)!]
            planDetailsVC.latStr = lats[(planTable.indexPathForSelectedRow?.row)!]
        }
        
        if identifier == "toRequestedVC" {
            let requestedVC = segue.destination as! RequestedViewController
            requestedVC.requestedIDs = self.fetchedRequests
        }
        
        if identifier == "toApprovePlanVC" {
            let approvePlanVC = segue.destination as! ApprovePlanViewController
            approvePlanVC.planID = self.fetchedPreparedPlanIDs[0]
        }
        
        if identifier == "openMenu" {
            let menuVC = segue.destination as! MenuViewController
            // 起動時の友だちの数
            if friendIDsToMe.isEmpty {
                menuVC.numberOfFriends = self.friendIDs.count
            }
            // 申請者追加後の友だちの数
            else {
                menuVC.numberOfFriends = self.friendIDsToMe.count
            }
        }
    }
 
    
    
}

