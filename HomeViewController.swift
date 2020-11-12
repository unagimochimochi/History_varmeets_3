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
    var participantIDs = [String]()    // 起動時にデータベースから取得
    var participantNames = [String]()
    var numberOfParticipants = [Int]()
    var places = [String]()
    var lons = [String]()
    var lats = [String]()
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var planIDsOnDatabase = [[String]]()    // 予定作成時・編集時にデータベースから取得
    
    var fetchedRequests = ["NO", "NO", "NO"]
    var friendIDs = [String]()    // 起動時の自分の友だち一覧
    var friendIDsToMe = [String]()    // friendIDs配列に申請許可者を追加した一覧
    var requestedIDs = [String]()
    var fetchedApplicantFriendIDs = [[String]]()
    var fetchedPreparedPlanIDs = [String]()    // 起動時にデータベースから取得する自分の予定候補ID
    
    var timer: Timer!
    
    var fetchRequestsTimer: Timer!
    var fetchRequestsCheck = false
    
    var fetchPlansTimer: Timer!
    var fetchPlansTimerCount = 0.0
    var fetchPlansCheck = [Bool]()
    var noPlansOnDatabase: Bool?
    
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
            
            myID = id
            myName = name
            
            userDefaults.set(id, forKey: "myID")
            userDefaults.set(name, forKey: "myName")
            
            let recordID = CKRecord.ID(recordName: "accountID-\(id)")
            let record = CKRecord(recordType: "Accounts", recordID: recordID)
            
            record["accountID"] = id as NSString
            record["accountName"] = name as NSString
            record["password"] = password as NSString
            record["requestedAccountID_01"] = "NO" as NSString
            record["requestedAccountID_02"] = "NO" as NSString
            record["requestedAccountID_03"] = "NO" as NSString
            record["favPlaceNames"] = ["東京タワー（お気に入りサンプル）"] as [String]
            record["favPlaceLocations"] = [CLLocation(latitude: 35.658584, longitude: 139.7454316)] as [CLLocation]
            
            // レコードを保存
            publicDatabase.save(record, completionHandler: {(record, error) in
                
                if let error = error {
                    print("新規レコード保存エラー: \(error)")
                    return
                }
                print("アカウント作成成功")
            })
            
            var existingIDs = firstVC.existingIDs
            
            // 検索条件を作成
            let predicate = NSPredicate(format: "toSearch IN %@", ["all-varmeetsIDs"])
            let query = CKQuery(recordType: "AccountsList", predicate: predicate)
            
            existingIDs.append("accountID-\(id)")
            
            // 検索したレコードの値を更新
            publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                
                if let error = error {
                    print("アカウントリスト追加エラー1: \(error)")
                    return
                }
                
                for record in records! {
                    record["accounts"] = existingIDs as [String]
                    self.publicDatabase.save(record, completionHandler: {(record, error) in
                        if let error = error {
                            print("アカウントリスト追加エラー2: \(error)")
                            return
                        }
                    })
                }
                print("アカウントリスト追加成功")
            })
        }
    }
    
    
    
    @IBAction func becameFriends(sender: UIStoryboardSegue) {
        
        if let requestedVC = sender.source as? RequestedViewController {
            
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
                alert(title: "エラー", message: "予定を承認できませんでした。")
                return
            }
            
            let predicate1 = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
            let query1 = CKQuery(recordType: "Accounts", predicate: predicate1)
            
            publicDatabase.perform(query1, inZoneWith: nil, completionHandler: {(records, error) in
                
                if let error = error {
                    print("予定承認（Accounts）エラー1: \(error)")
                    return
                }
                
                for record in records! {
                    
                    // 予定を承認する場合
                    if approvedPlanVC.approval == true {
                        myPlanIDs.append(approvedPlanID)
                        self.planTitles.append(approvedPlanVC.planTitle!)
                        estimatedTimes.append(approvedPlanVC.estimatedTime!)
                        self.dateAndTimes.append(approvedPlanVC.dateAndTime!)
                        self.participantIDs.append(approvedPlanVC.authorID!)
                        self.participantNames.append(approvedPlanVC.authorName!)
                        self.numberOfParticipants.append(approvedPlanVC.everyoneIDsExceptAuthor.count + 1)
                        self.places.append(approvedPlanVC.place!)
                        self.lats.append((approvedPlanVC.location?.coordinate.latitude.description)!)
                        self.lons.append((approvedPlanVC.location?.coordinate.longitude.description)!)
                    }
                    record["planIDs"] = myPlanIDs as [String]
                    
                    // 起動時に取得した予定候補ID一覧から承認／非承認する予定IDを抜く
                    if let index = self.fetchedPreparedPlanIDs.index(of: approvedPlanID) {
                        self.fetchedPreparedPlanIDs.remove(at: index)
                    }
                    record["preparedPlanIDs"] = self.fetchedPreparedPlanIDs as [String]
                    
                    self.publicDatabase.save(record, completionHandler: {(record, error) in
                        
                        if let error = error {
                            print("予定承認（Accounts）エラー2: \(error)")
                            return
                        }
                        print("予定承認（Accounts）成功")
                    })
                }
            })
            
            let predicate2 = NSPredicate(format: "planID == %@", argumentArray: [approvedPlanID])
            let query2 = CKQuery(recordType: "Plans", predicate: predicate2)
            
            publicDatabase.perform(query2, inZoneWith: nil, completionHandler: {(records, error) in
                
                if let error = error {
                    print("予定承認（Plans）エラー1: \(error)")
                    return
                }
                
                for record in records! {
                    
                    var newParticipantIDs = [String]()
                    newParticipantIDs = approvedPlanVC.participantIDs
                    // 予定を承認する場合、参加者に自分のIDを追加
                    if approvedPlanVC.approval == true {
                        newParticipantIDs.append(myID!)
                    }
                    record["participantIDs"] = newParticipantIDs as [String]
                    
                    var newPreparedParticipantIDs = [String]()
                    newPreparedParticipantIDs = approvedPlanVC.preparedParticipantIDs
                    // 当初の予定参加候補者ID一覧から自分のIDを抜く
                    if let index = newPreparedParticipantIDs.index(of: myID!) {
                        newPreparedParticipantIDs.remove(at: index)
                    }
                    record["preparedParticipantIDs"] = newPreparedParticipantIDs as [String]
                    
                    self.publicDatabase.save(record, completionHandler: {(record, error) in
                        
                        if let error = error {
                            print("予定承認（Plans）エラー2: \(error)")
                            return
                        }
                        print("予定承認（Plans）成功")
                    })
                }
            })
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.planTable.reloadData()
            }
        }
    }
    
    
    
    @IBAction func unwindtoHomeVC(sender: UIStoryboardSegue) {
        
        guard let addPlanVC = sender.source as? AddPlanViewController else {
            return
        }
        
        planIDsOnDatabase.removeAll()
        
        // 日時
        var toSaveEstimatedTime: Date?
        
        if let dateAndTime = addPlanVC.dateAndTime {
            
            toSaveEstimatedTime = addPlanVC.estimatedTime!
            
            if let selectedIndexPath = planTable.indexPathForSelectedRow {
                dateAndTimes[selectedIndexPath.row] = dateAndTime
                estimatedTimes[selectedIndexPath.row] = toSaveEstimatedTime!
                
            } else {
                dateAndTimes.append(dateAndTime)
                estimatedTimes.append(toSaveEstimatedTime!)
            }
            
            userDefaults.set(dateAndTimes, forKey: "DateAndTimes")
            userDefaults.set(estimatedTimes, forKey: "EstimatedTimes")
        }
        
        // 予定タイトル
        var toSavePlanTitle: String?
        
        if let planTitle = addPlanVC.planTitle {
            
            toSavePlanTitle = planTitle
            
            if let selectedIndexPath = planTable.indexPathForSelectedRow {
                planTitles[selectedIndexPath.row] = planTitle
                
            } else {
                planTitles.append(planTitle)
            }
            
            userDefaults.set(planTitles, forKey: "PlanTitles")
        }
        
        // 参加者（参加候補者です！ややこしい）
        var toSaveParticipantIDs = [String]()
        
        if addPlanVC.everyoneNamesExceptAuthor.isEmpty == false {
            
            toSaveParticipantIDs = addPlanVC.participantIDs
            
            let rep = addPlanVC.everyoneNamesExceptAuthor[0]
            let number = addPlanVC.everyoneNamesExceptAuthor.count
            
            if let selectedIndexPath = planTable.indexPathForSelectedRow {
                participantNames[selectedIndexPath.row] = rep
                numberOfParticipants[selectedIndexPath.row] = number + 1
                
            } else {
                participantNames.append(rep)
                numberOfParticipants.append(number + 1)
            }
            
            userDefaults.set(participantNames, forKey: "ParticipantNames")
            userDefaults.set(numberOfParticipants, forKey: "NumberOfParticipants")
        }
        
        // 場所
        var toSavePlaceName: String?
        var toSaveLocation: CLLocation?
        
        if let place = addPlanVC.place {

            let lat = addPlanVC.lat
            let lon = addPlanVC.lon
            
            toSavePlaceName = place
            toSaveLocation = CLLocation(latitude: Double(lat)!, longitude: Double(lon)!)
            
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
            
            let planID = myPlanIDs[selectedIndexPath.row]
            
            // 検索条件を作成
            let predicate = NSPredicate(format: "planID == %@", argumentArray: [planID])
            let query = CKQuery(recordType: "Plans", predicate: predicate)
            
            // 検索した予定の中身を更新
            publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                
                if let error = error {
                    print("予定更新エラー1: \(error)")
                    return
                }
                
                for record in records! {
                    
                    if let savePlanTitle = toSavePlanTitle {
                        record["planTitle"] = savePlanTitle as NSString
                    }
                        
                    if let saveEstimatedTime = toSaveEstimatedTime {
                        record["estimatedTime"] = saveEstimatedTime as Date
                    }
                        
                    if toSaveParticipantIDs.isEmpty == false {
                        record["preparedParticipantIDs"] = toSaveParticipantIDs as [String]
                    }
                        
                    if let savePlaceName = toSavePlaceName {
                        record["placeName"] = savePlaceName as NSString
                    }
                        
                    if let saveLocation = toSaveLocation {
                        record["placeLatAndLon"] = saveLocation
                    }
                    
                    self.publicDatabase.save(record, completionHandler: {(record, error) in
                        
                        if let error = error {
                            print("予定更新エラー2: \(error)")
                            return
                        }
                        
                        print("予定更新成功")
                    })
                }
            })
            
            // 新たに追加した参加候補者
            // まず新旧参加候補者を代入
            var newParticipantIDs = toSaveParticipantIDs
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
            
            if newParticipantIDs.isEmpty == false {
                
                // 人数分の空の配列を入れる
                // planIDsOnDatabase = [[String](), [String](), ...]
                for _ in 0...(newParticipantIDs.count - 1) {
                    planIDsOnDatabase.append([String]())
                }
                
                for i in 0...(newParticipantIDs.count - 1) {
                    fetchNewParticipantsPlanIDs(accountID: newParticipantIDs[i], index: i, completion: {
                        // データベースの予定ID取得後に編集した予定のIDを追加
                        self.planIDsOnDatabase[i].append(addPlanVC.planID!)
                        
                        // 次の処理
                        self.addNewParticipantsPlanIDToDatabase(accountID: newParticipantIDs[i], index: i)
                    })
                }
            }
        }
        
        // 新たに予定を作成したとき
        else {
            print("予定を生成")
            // 10桁の予定ID生成
            let planID = generatePlanID(length: 10)
            myPlanIDs.append(planID)
            
            userDefaults.set(myPlanIDs, forKey: "PlanIDs")
            
            let recordID = CKRecord.ID(recordName: "planID-\(planID)")
            let record = CKRecord(recordType: "Plans", recordID: recordID)
                
            record["planID"] = planID as NSString
            record["authorID"] = myID! as NSString
                
            if let savePlanTitle = toSavePlanTitle {
                record["planTitle"] = savePlanTitle as NSString
            }
                
            if let saveEstimatedTime = toSaveEstimatedTime {
                record["estimatedTime"] = saveEstimatedTime as Date
            }
                
            if toSaveParticipantIDs.isEmpty == false {
                record["preparedParticipantIDs"] = toSaveParticipantIDs as [String]
            }
                
            if let savePlaceName = toSavePlaceName {
                record["placeName"] = savePlaceName as NSString
            }
                
            if let saveLocation = toSaveLocation {
                record["placeLatAndLon"] = saveLocation
            }
                
            // レコードを保存
            publicDatabase.save(record, completionHandler: {(record, error) in
                if let error = error {
                    print("Plansタイプ予定保存エラー: \(error)")
                    return
                }
                print("Plansタイプ予定保存成功")
            })
            
            // 作成者・参加者のIDを格納した配列
            var everyone = [myID!]
            for participantID in toSaveParticipantIDs {
                everyone.append(participantID)
            }
            
            // 人数分の空の配列を入れる
            // planIDsOnDatabase = [[String](), [String](), ...]
            for _ in 0...(everyone.count - 1) {
                planIDsOnDatabase.append([String]())
            }
            
            for i in 0...(everyone.count - 1) {
                fetchPlanIDs(accountID: everyone[i], index: i, completion: {
                    // データベースの予定ID取得後に新たなIDを追加
                    self.planIDsOnDatabase[i].append(planID)
                    
                    // 次の処理
                    self.addPlanIDToDatabase(accountID: everyone[i], index: i, newPlanID: planID)
                })
            }
        }
        
        self.planTable.reloadData()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if userDefaults.object(forKey: "myID") != nil {
            myID = userDefaults.string(forKey: "myID")
            print("myID: \(myID!)")
        } else {
            self.performSegue(withIdentifier: "toFirstVC", sender: nil)
        }

        if userDefaults.object(forKey: "myName") != nil {
            myName = userDefaults.string(forKey: "myName")
            print("myName: \(myName!)")
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let indexPath = planTable.indexPathForSelectedRow {
            print("deselect")
            planTable.deselectRow(at: indexPath, animated: true)
        }
        
        hiddenCountdown()
        estimatedTimesSort.removeAll()
        
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
        
        if myID != nil {
            firstWork()
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
        
        if numberOfParticipants[indexPath.row] <= 1 {
            participantLabel.text = self.participantNames[indexPath.row]
        } else {
            participantLabel.text = "\(self.participantNames[indexPath.row]) 他"
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
            remove(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    
    @objc func update() {
        
        let now = Date()
        let calendar = Calendar(identifier: .japanese)
        
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
            
            // カウントダウンを非表示
            self.hiddenCountdown()
            
            // 並べ替え用の配列に予定時刻をセット
            estimatedTimesSort = estimatedTimes
            // 並べ替え用の配列で並べ替え
            estimatedTimesSort.sort { $0 < $1 }
            
            // 一番近い予定のindexを取得
            if let index = estimatedTimes.index(of: estimatedTimesSort[0]) {
                // index番目の配列とuserDefaultsを削除
                self.remove(index: index)
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
                }
            }
            
            if let preparedParticipantIDs = record?.value(forKey: "preparedParticipantIDs") as? [String] {
                for preparedParticipantID in preparedParticipantIDs {
                    everyone.append(preparedParticipantID)
                }
            }
            
            self.numberOfParticipants[index] = everyone.count
            
            if let myIndex = everyone.index(of: myID!) {
                everyone.remove(at: myIndex)
                self.participantIDs[index] = everyone[0]    // 代表参加者（0番目）のID
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
    
    
    
    func fetchParticipantName(index: Int, completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(participantIDs[index])")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("参加者（\(self.participantIDs[index])）の名前取得エラー: \(error)")
                return
            }
            
            if let participantName = record?.value(forKey: "accountName") as? String {
                self.participantNames[index] = participantName
            }
            
            completion()
        })
    }
    
    
    
    @objc func fetchingPlans() {
        print("Now fetching plans")
        
        fetchPlansTimerCount += 0.5
        
        // データベースの予定取得に5秒以上かかったとき
        if fetchPlansTimerCount >= 5.0 {
            
            // タイマーを止める
            if let workingTimer = fetchPlansTimer {
                workingTimer.invalidate()
            }
            
            // ローカルで予定を読み込む
            readUserDefaults()
        }
        
        else if fetchPlansCheck.isEmpty == false && fetchPlansCheck.contains(false) == false {
            
            print("Completed fetching plans!")
            
            // タイマーを止める
            if let workingTimer = fetchPlansTimer {
                workingTimer.invalidate()
            }
            
            // UI更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.planTable.reloadData()
            })
        }
        
        else if noPlansOnDatabase == true {
            print("There are no plans on database!")
            
            // タイマーを止める
            if let workingTimer = fetchPlansTimer {
                workingTimer.invalidate()
            }
            
            // UI更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.planTable.reloadData()
            })
        }
    }
    
    
    
    // 予定作成時
    func fetchPlanIDs(accountID: String, index: Int, completion: @escaping () -> ()) {
        print("\(accountID)の予定一覧取得開始")
        
        let recordID = CKRecord.ID(recordName: "accountID-\(accountID)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("予定取得エラー: \(error)")
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
                        return
                    }
                    print("\(accountID)のデータベースの予定ID追加成功")
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
                return
            }
            
            for record in records! {
                
                record["preparedPlanIDs"] = self.planIDsOnDatabase[index] as [String]
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("\(accountID)のデータベースの予定ID追加エラー2: \(error)")
                        return
                    }
                    print("\(accountID)のデータベースの予定ID追加成功")
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
            self.participantIDs.removeAll()
            self.participantNames.removeAll()
            self.numberOfParticipants.removeAll()
            self.places.removeAll()
            self.lats.removeAll()
            self.lons.removeAll()
            
            if myPlanIDs.isEmpty == false {
                
                for _ in 0...(myPlanIDs.count - 1) {
                    self.dateAndTimes.append("日時")
                    estimatedTimes.append(Date(timeIntervalSinceReferenceDate: 0.0))
                    self.planTitles.append("予定サンプル")
                    self.participantIDs.append("participantID")
                    self.participantNames.append("参加者")
                    self.numberOfParticipants.append(0)
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
                        
                        // 参加代表者のIDから名前を取得
                        self.fetchParticipantName(index: i, completion: {
                            
                            // 完了チェック
                            self.fetchPlansCheck[i] = true
                            
                            // UserDefaultsに保存
                            userDefaults.set(myPlanIDs, forKey: "PlanIDs")
                            userDefaults.set(self.dateAndTimes, forKey: "DateAndTimes")
                            userDefaults.set(estimatedTimes, forKey: "EstimatedTimes")
                            userDefaults.set(self.planTitles, forKey: "PlanTitles")
                            userDefaults.set(self.participantNames, forKey: "ParticipantNames")
                            userDefaults.set(self.numberOfParticipants, forKey: "NumberOfParticipants")
                            userDefaults.set(self.places, forKey: "Places")
                            userDefaults.set(self.lats, forKey: "lats")
                            userDefaults.set(self.lons, forKey: "lons")
                        })
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
        
        if userDefaults.object(forKey: "ParticipantNames") != nil {
            self.participantNames = userDefaults.stringArray(forKey: "ParticipantNames")!
        }
        
        if userDefaults.object(forKey: "NumberOfParticipants") != nil {
            self.numberOfParticipants = userDefaults.array(forKey: "NumberOfParticipants") as! [Int]
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
    
    
    
    func remove(index: Int) {
        
        myPlanIDs.remove(at: index)
        userDefaults.set(myPlanIDs, forKey: "PlanIDs")
        
        dateAndTimes.remove(at: index)
        userDefaults.set(dateAndTimes, forKey: "DateAndTimes")
        
        estimatedTimes.remove(at: index)
        userDefaults.set(estimatedTimes, forKey: "EstimatedTimes")
        
        self.planTitles.remove(at: index)
        userDefaults.set(self.planTitles, forKey: "PlanTitles")
        
        self.participantNames.remove(at: index)
        userDefaults.set(self.participantNames, forKey: "ParticipantNames")
        
        self.numberOfParticipants.remove(at: index)
        userDefaults.set(self.numberOfParticipants, forKey: "NumberOfParticipants")
        
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
                return
            }
            
            for record in records! {
                
                record["planIDs"] = myPlanIDs as [String]
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("データベースの予定ID削除エラー2: \(error)")
                        return
                    }
                    
                    print("データベースの予定ID削除成功")
                })
            }
        })
        
        planTable.reloadData()
    }
    
    
    
    func alert(title: String?, message: String?) {
        
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // OKボタン
        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        // ダイアログを表示
        self.present(dialog, animated: true, completion: nil)
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

