//
//  MapViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/02/26.
//  https://developer.apple.com/documentation/corelocation/
//  https://qiita.com/yuta-sasaki/items/3151b3faf2303fe78312
//

import UIKit
import CoreLocation
import MapKit
import CloudKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate {
        
    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var annotation: MKPointAnnotation = MKPointAnnotation()
    let geocoder = CLGeocoder()
    
    var lat: String = ""
    var lon: String = ""
    
    var searchAnnotationArray = [MKPointAnnotation]()
    
    @IBOutlet var tapGesRec: UITapGestureRecognizer!
    @IBOutlet var longPressGesRec: UILongPressGestureRecognizer!
    
    @IBOutlet weak var addPlanButton: UIButton!    // オレンジの丸いボタン
    @IBOutlet weak var focusOnMyselfButton: UIButton!
    
    @IBOutlet weak var placeSearchBar: UISearchBar!
    
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var detailsViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var placeAddressLabel: UILabel!
    @IBOutlet weak var addFavButton: UIButton!
    @IBOutlet weak var addPlanButtonD: UIButton!    // DetailsView内のボタン
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var meetingTimer: Timer!
    var meetingPlace: String?
    var meetingLocation: CLLocation?
    var meetingAnnotation = ArrangeAnnotation()
    var participantIDs = [String]()
    var participantLocations = [CLLocation]()
    var participantAnnotations = [MKPointAnnotation]()
    
    var favLocations = [CLLocation]()    // データベース保存用
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        hiddenDetailsView()
        
        // 詳細ビュー
        detailsView.layer.masksToBounds = true
        detailsView.layer.cornerRadius = 20
        
        // 詳細ビューのお気に入りボタン
        addFavButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        addFavButton.layer.masksToBounds = true
        addFavButton.layer.cornerRadius = 8
        
        // 詳細ビューの予定を追加ボタン
        addPlanButtonD.setTitleColor(UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0), for: .normal)
        addPlanButtonD.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        addPlanButtonD.backgroundColor = .white
        addPlanButtonD.layer.borderColor = UIColor.orange.cgColor
        addPlanButtonD.layer.borderWidth = 1
        addPlanButtonD.layer.masksToBounds = true
        addPlanButtonD.layer.cornerRadius = 8
        
        mapView.delegate = self
        
        locationManager = CLLocationManager()
        guard let locationManager = locationManager else {
            return
        }
        locationManager.delegate = self
        
        // 位置情報取得の許可を得る
        locationManager.requestAlwaysAuthorization()
        // 位置情報の更新を指示
        locationManager.startUpdatingLocation()
        // バックグラウンドでの位置情報更新を許可
        locationManager.allowsBackgroundLocationUpdates = true
        
        initMap()

        placeSearchBar.delegate = self
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.removeAnnotations(participantAnnotations)
        participantIDs.removeAll()
        participantLocations.removeAll()
        participantAnnotations.removeAll()
        
        let now = Date()
        let calendar = Calendar(identifier: .japanese)
        
        if estimatedTimesSort.isEmpty == false {
            
            let components = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: now, to: estimatedTimesSort[0])
            
            // 一番近い予定のindexを取得
            if let index = estimatedTimes.index(of: estimatedTimesSort[0]) {
                // 1時間未満のとき（過ぎた場合も含む）
                if components.month! <= 0 && components.day! <= 0 && components.hour! <= 0 &&
                    components.minute! <= 59 &&
                    components.second! <= 59 {
                    
                    // その予定の参加者を取得
                    fetchParticipantIDs(planID: myPlanIDs[index], completion: {
                        // 参加者の中から自分のIDのindexを取得
                        if let myIndex = self.participantIDs.index(of: myID!) {
                            // 自分のIDを抜く
                            self.participantIDs.remove(at: myIndex)
                            
                            // それぞれの位置情報の初期値に適当な値を入れる（東京駅）
                            for i in 0...(self.participantIDs.count - 1) {
                                
                                let first = CLLocation(latitude: 35.6809591, longitude: 139.7673068)
                                self.participantLocations.append(first)
                                
                                self.participantAnnotations.append(MKPointAnnotation())
                                let first2D = CLLocationCoordinate2D(latitude: 35.6809591, longitude: 139.7673068)
                                self.participantAnnotations[i].coordinate = first2D
                                self.participantAnnotations[i].title = self.participantIDs[i]
                                self.mapView.addAnnotation(self.participantAnnotations[i])
                            }
                            
                            // タイマースタート
                            DispatchQueue.main.async { [weak self] in
                                guard let `self` = self else { return }
                                self.meetingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.meeting), userInfo: nil, repeats: true)
                            }
                        }
                        
                        // 待ち合わせ場所にピンを立てる
                        let loc2D = self.meetingLocation?.coordinate
                        self.meetingAnnotation.coordinate = loc2D!
                        self.meetingAnnotation.title = self.meetingPlace
                        self.meetingAnnotation.pinImage = "Destination"
                        self.mapView.addAnnotation(self.meetingAnnotation)
                        
                        // メインスレッドで処理
                        DispatchQueue.main.async { [weak self] in
                            guard let `self` = self else { return }
                            // ピンを最初から選択状態にする
                            self.mapView.selectAnnotation(self.meetingAnnotation, animated: true)
                            // ピンを中心に表示
                            self.mapView.setCenter(loc2D!, animated: true)
                        }
                    })
                }
            }
        }
        // estimatedTimesSort配列が空のとき（待ち合わせを完了したあとに地図を開いたとき）
        else {
            // タイマーを止める
            if let workingTimer = meetingTimer {
                workingTimer.invalidate()
            }
            
            mapView.removeAnnotation(meetingAnnotation)
            meetingPlace = nil
            meetingLocation = nil
            
            initMap()
        }
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let workingTimer = meetingTimer {
            workingTimer.invalidate()
        }
    }
    
    
    
    // タップ検出
    @IBAction func mapViewDiDTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            print("タップ")
            mapView.removeAnnotation(annotation)
            hiddenDetailsView()
        }
    }
    
    
    
    // ロングタップ検出
    @IBAction func mapViewDidLongPress(_ sender: UILongPressGestureRecognizer) {
        // ロングタップ開始
        if sender.state == .began {
            print("ロングタップ開始")
            
            // ロングタップ開始時に古いピンを削除する
            mapView.removeAnnotation(annotation)
            mapView.removeAnnotations(searchAnnotationArray)
            
            hiddenDetailsView()
        }
            
        // ロングタップ終了（手を離した）
        else if sender.state == .ended {
            print("ロングタップ終了")
            
            // prepare(for:sender:) で場合分けするため配列を空にする
            searchAnnotationArray.removeAll()
            
            // タップした位置(CGPoint)を指定してMKMapView上の緯度経度を取得する
            let tapPoint = sender.location(in: view)
            let center = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            
            let latStr = center.latitude.description
            let lonStr = center.longitude.description
            
            print("lat: " + latStr)
            print("lon: " + lonStr)
            
            // 変数にタップした位置の緯度と経度をセット
            lat = latStr
            lon = lonStr
            
            // 緯度と経度をString型からDouble型に変換
            let latNum = Double(latStr)!
            let lonNum = Double(lonStr)!
            
            let location = CLLocation(latitude: latNum, longitude: lonNum)
            
            // 緯度と経度から住所を取得（逆ジオコーディング）
            geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: GeocodeCompHandler(placemarks:error:))
            
            let distance = calcDistance(mapView.userLocation.coordinate, center)
            print("distance: " + distance.description)
            
            // ロングタップを検出した位置にピンを立てる
            annotation.coordinate = center
            mapView.addAnnotation(annotation)
            // ピンを最初から選択状態にする
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    
    
    @IBAction func focusOnMyself(_ sender: Any) {
        mapView.setCenter(mapView.userLocation.coordinate, animated: true)
        mapView.showsUserLocation = true
    }
    
    
    
    // 地図の初期化関数
    func initMap() {
        var region: MKCoordinateRegion = mapView.region
        region.span.latitudeDelta = 0.02
        region.span.longitudeDelta = 0.02
        mapView.setRegion(region, animated: true)
        
        mapView.showsUserLocation = true // 現在位置表示の有効化
        mapView.userTrackingMode = .follow // 現在位置のみ更新する
    }
    
    
    
    // 2点間の距離(m)を算出する
    func calcDistance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        let aLoc: CLLocation = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let bLoc: CLLocation = CLLocation(latitude: b.latitude, longitude: b.longitude)
        let dist = bLoc.distance(from: aLoc)
        return dist
    }
    
    
    
    // 位置情報更新時
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        // 待ち合わせ中のみデータベースの位置情報を更新
        if meetingTimer != nil {
            recordLocation()
        }
    }
    
    // reverseGeocodeLocation(_:preferredLocale:completionHandler:)の第3引数
    func GeocodeCompHandler(placemarks: [CLPlacemark]?, error: Error?) {
        guard let placemark = placemarks?.first, error == nil,
            let administrativeArea = placemark.administrativeArea, //県
            let locality = placemark.locality, // 市区町村
            let throughfare = placemark.thoroughfare, // 丁目を含む地名
            let subThoroughfare = placemark.subThoroughfare // 番地
            else {
                return
        }
        
        self.annotation.title = administrativeArea + locality + throughfare + subThoroughfare
        placeAddressLabel.text = administrativeArea + locality + throughfare + subThoroughfare
    }
    
    // ピンの詳細設定
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 現在地にはピンを立てない
        if annotation is MKUserLocation {
            return nil
        }
        
        // 吹き出し内の･･･ボタン
        let detailsButton = UIButton()
        detailsButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        detailsButton.setTitle("･･･", for: .normal)
        detailsButton.setTitleColor(.orange, for: .normal)
        detailsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        // 待ち合わせ中の目的地
        if let arrangedAnnotation = annotation as? ArrangeAnnotation {
            
            if arrangedAnnotation.pinImage != nil {
                let destinationAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
                destinationAnnotationView.image = UIImage(named: arrangedAnnotation.pinImage)
                
                // 吹き出しを表示
                destinationAnnotationView.canShowCallout = true
                
                return destinationAnnotationView
            }
        }
        // 配列が空のとき（ロングタップでピンを立てたとき）
        if searchAnnotationArray.isEmpty == true && self.annotation.title != nil {
            
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            
            // 吹き出しを表示
            annotationView.canShowCallout = true
            // 吹き出しの右側にボタンをセット
            annotationView.rightCalloutAccessoryView = detailsButton
            
            return annotationView
        }
        
        // 配列が空ではないとき（検索でピンを立てたとき）
        else if searchAnnotationArray.isEmpty == false {
            
            let searchAnnotationView = MKPinAnnotationView(annotation: searchAnnotationArray as? MKAnnotation, reuseIdentifier: nil)

            // 吹き出しを表示
            searchAnnotationView.canShowCallout = true
            // 吹き出しの右側にボタンをセット
            searchAnnotationView.rightCalloutAccessoryView = detailsButton
            
            return searchAnnotationView
        }
        
        // その他（参加者のピン？）
        else {
            let participantAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            // 吹き出しを表示
            participantAnnotationView.canShowCallout = true
            
            return participantAnnotationView
        }
        
        
    }
    
    // 吹き出しアクセサリー押下時
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // ･･･ボタンで詳細ビューを表示
        if control == view.rightCalloutAccessoryView {
            displayDetailsView()
        }
        
        // 配列が空のとき（ロングタップでピンを立てたとき）
        if searchAnnotationArray.isEmpty == true {
            placeNameLabel.text = annotation.title
            
            // すでにお気に入りに登録されているとき
            if favAddresses.contains(annotation.title!) {
                addFavButton.setTitle("お気に入り解除", for: .normal)
                addFavButton.setTitleColor(.white, for: .normal)
                addFavButton.backgroundColor = .orange
            }
            
            // お気に入り登録
            else {
                addFavButton.setTitle("お気に入り登録", for: .normal)
                addFavButton.setTitleColor(UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0), for: .normal)
                addFavButton.backgroundColor = .white
                addFavButton.layer.borderColor = UIColor.orange.cgColor
                addFavButton.layer.borderWidth = 1
            }
        }
        
        // 配列が空ではないとき（検索でピンを立てたとき）
        else if searchAnnotationArray.isEmpty == false {
            // 選択されているピンを新たな配列に格納
            let selectedSearchAnnotationArray = mapView.selectedAnnotations
            
            // 選択されているピンは1つのため、0番目を取り出す
            let selectedSearchAnnotation = selectedSearchAnnotationArray[0]
            
            // ピンの緯度と経度を取得
            let latNum = selectedSearchAnnotation.coordinate.latitude
            let lonNum = selectedSearchAnnotation.coordinate.longitude
            
            let location = CLLocation(latitude: latNum, longitude: lonNum)
            geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: GeocodeCompHandler(placemarks:error:))
            
            if let selectedSearchAnnotationTitle = selectedSearchAnnotation.title! {
                placeNameLabel.text = selectedSearchAnnotationTitle
                
                // すでにお気に入り登録されているとき
                if favPlaces.contains(selectedSearchAnnotationTitle) {
                    addFavButton.setTitle("お気に入り解除", for: .normal)
                    addFavButton.setTitleColor(.white, for: .normal)
                    addFavButton.backgroundColor = .orange
                }
                
                // お気に入り登録
                else {
                    addFavButton.setTitle("お気に入り登録", for: .normal)
                    addFavButton.setTitleColor(UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0), for: .normal)
                    addFavButton.backgroundColor = .white
                    addFavButton.layer.borderColor = UIColor.orange.cgColor
                    addFavButton.layer.borderWidth = 1
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("検索")
        mapView.removeAnnotation(annotation)
        mapView.removeAnnotations(searchAnnotationArray)
        hiddenDetailsView()
        
        // 前回の検索結果の配列を空にする
        searchAnnotationArray.removeAll()
        
        // キーボードをとじる
        self.view.endEditing(true)
        
        // 検索条件を作成
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = placeSearchBar.text
        
        // 検索範囲はMKMapViewと同じ
        request.region = mapView.region
        
        let localSearch = MKLocalSearch(request: request)
        localSearch.start(completionHandler: LocalSearchCompHandler(response:error:))
    }
    
    // start(completionHandler:)の引数
    func LocalSearchCompHandler(response: MKLocalSearch.Response?, error: Error?) -> Void {
        // 検索がヒットしたとき
        if let response = response {
            for searchLocation in (response.mapItems) {
                if error == nil {
                    let searchAnnotation = MKPointAnnotation()
                    // ピンの座標
                    let center = CLLocationCoordinate2DMake(searchLocation.placemark.coordinate.latitude, searchLocation.placemark.coordinate.longitude)
                    searchAnnotation.coordinate = center
                    
                    // タイトルに場所の名前を表示
                    searchAnnotation.title = searchLocation.placemark.name
                    // ピンを立てる
                    mapView.addAnnotation(searchAnnotation)
                    
                    // searchAnnotation配列にピンをセット
                    searchAnnotationArray.append(searchAnnotation)
                    
                } else {
                    print("error")
                }
            }
        }
        
        // 検索がヒットしなかったとき
        else {
            let dialog = UIAlertController(title: "検索結果なし", message: "ご迷惑をおかけします。\nどうしてもヒットしない場合は住所を入力してみてください！", preferredStyle: .alert)
            // OKボタン
            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            // ダイアログを表示
            self.present(dialog, animated: true, completion: nil)
        }
        
        // 0番目のピンを中心に表示
        if searchAnnotationArray.isEmpty == false {
            let searchAnnotation = searchAnnotationArray[0]
            let center = CLLocationCoordinate2D(latitude: searchAnnotation.coordinate.latitude, longitude: searchAnnotation.coordinate.longitude)
            mapView.setCenter(center, animated: true)
            
        } else {
            print("配列が空")
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("検索キャンセル")
        
        // テキストを空にする
        placeSearchBar.text = ""
        // キーボードをとじる
        self.view.endEditing(true)
    }
    
    @IBAction func tappedFavButton(_ sender: Any) {
        
        // 配列が空のとき（ロングタップでピンを立てたとき）
        if searchAnnotationArray.isEmpty == true {
            // すでにお気に入り登録されているとき
            if favAddresses.contains(annotation.title ?? "") {
                
                if let index = favAddresses.index(of: annotation.title ?? "") {
                    
                    favPlaces.remove(at: index)
                    userDefaults.set(favPlaces, forKey: "favPlaces")
                    
                    favAddresses.remove(at: index)
                    userDefaults.set(favAddresses, forKey: "favAddresses")
                    
                    favLats.remove(at: index)
                    userDefaults.set(favLats, forKey: "favLats")
                    
                    favLons.remove(at: index)
                    userDefaults.set(favLons, forKey: "favLons")
                    
                    let dialog = UIAlertController(title: "お気に入り解除", message: "\(annotation.title ?? "")をお気に入りから削除しました。", preferredStyle: .alert)
                    // OKボタン
                    dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    // ダイアログを表示
                    self.present(dialog, animated: true, completion: nil)
                    
                    // ボタンの見た目をスイッチ
                    addFavButton.setTitle("お気に入り登録", for: .normal)
                    addFavButton.setTitleColor(UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0), for: .normal)
                    addFavButton.backgroundColor = .white
                    addFavButton.layer.borderColor = UIColor.orange.cgColor
                    addFavButton.layer.borderWidth = 1
                    
                    // データベースに保存
                    favLocations.removeAll()
                    for i in 0...(favPlaces.count - 1) {
                        favLocations.append(CLLocation(latitude: favLats[i], longitude: favLons[i]))
                    }
                    reloadFavorites()
                }
            }
            
            // お気に入り登録
            else {
                favPlaces.append(annotation.title ?? "")
                userDefaults.set(favPlaces, forKey: "favPlaces")
                
                favAddresses.append(placeAddressLabel.text ?? "")
                userDefaults.set(favAddresses, forKey: "favAddresses")
                
                favLats.append(annotation.coordinate.latitude)
                userDefaults.set(favLats, forKey: "favLats")
                
                favLons.append(annotation.coordinate.longitude)
                userDefaults.set(favLons, forKey: "favLons")
                
                let dialog = UIAlertController(title: "お気に入り登録", message: "\(annotation.title ?? "")をお気に入りに追加しました。", preferredStyle: .alert)
                // OKボタン
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // ダイアログを表示
                self.present(dialog, animated: true, completion: nil)
                
                // ボタンの見た目をスイッチ
                addFavButton.setTitle("お気に入り解除", for: .normal)
                addFavButton.setTitleColor(.white, for: .normal)
                addFavButton.backgroundColor = .orange
                
                // データベースに保存
                favLocations.removeAll()
                for i in 0...(favPlaces.count - 1) {
                    favLocations.append(CLLocation(latitude: favLats[i], longitude: favLons[i]))
                }
                reloadFavorites()
            }
        }
            
        // 配列が空ではないとき（検索でピンを立てたとき）
        else {
            // 選択されているピンを新たな配列に格納
            let selectedSearchAnnotationArray = mapView.selectedAnnotations
            
            // 選択されているピンは1つのため、0番目を取り出す
            let selectedSearchAnnotation = selectedSearchAnnotationArray[0]
            
            if let selectedSearchAnnotationTitle = selectedSearchAnnotation.title ?? "" {
                // すでにお気に入りに登録されているとき
                if favPlaces.contains(selectedSearchAnnotationTitle) {
                    
                    if let index = favPlaces.index(of: selectedSearchAnnotationTitle) {
                        
                        favPlaces.remove(at: index)
                        userDefaults.set(favPlaces, forKey: "favPlaces")
                        
                        favAddresses.remove(at: index)
                        userDefaults.set(favAddresses, forKey: "favAddresses")
                        
                        favLats.remove(at: index)
                        userDefaults.set(favLats, forKey: "favLats")
                        
                        favLons.remove(at: index)
                        userDefaults.set(favLons, forKey: "favLons")
                        
                        let dialog = UIAlertController(title: "お気に入り解除", message: "\(selectedSearchAnnotationTitle)をお気に入りから削除しました。", preferredStyle: .alert)
                        // OKボタン
                        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        // ダイアログを表示
                        self.present(dialog, animated: true, completion: nil)
                        
                        // ボタンの見た目をスイッチ
                        addFavButton.setTitle("お気に入り登録", for: .normal)
                        addFavButton.setTitleColor(UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0), for: .normal)
                        addFavButton.backgroundColor = .white
                        addFavButton.layer.borderColor = UIColor.orange.cgColor
                        addFavButton.layer.borderWidth = 1
                        
                        // データベースに保存
                        favLocations.removeAll()
                        for i in 0...(favPlaces.count - 1) {
                            favLocations.append(CLLocation(latitude: favLats[i], longitude: favLons[i]))
                        }
                        reloadFavorites()
                    }
                }
                
                // お気に入り登録
                else {
                    favPlaces.append(selectedSearchAnnotationTitle)
                    userDefaults.set(favPlaces, forKey: "favPlaces")
                    
                    favAddresses.append(placeAddressLabel.text ?? "")
                    userDefaults.set(favAddresses, forKey: "favAddresses")
                    
                    favLats.append(selectedSearchAnnotation.coordinate.latitude)
                    userDefaults.set(favLats, forKey: "favLats")
                    
                    favLons.append(selectedSearchAnnotation.coordinate.longitude)
                    userDefaults.set(favLons, forKey: "favLons")
                    
                    let dialog = UIAlertController(title: "お気に入り登録", message: "\(annotation.title ?? "")をお気に入りに追加しました。", preferredStyle: .alert)
                    // OKボタン
                    dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    // ダイアログを表示
                    self.present(dialog, animated: true, completion: nil)
                    
                    // ボタンの見た目をスイッチ
                    addFavButton.setTitle("お気に入り解除", for: .normal)
                    addFavButton.setTitleColor(.white, for: .normal)
                    addFavButton.backgroundColor = .orange
                    
                    // データベースに保存
                    favLocations.removeAll()
                    for i in 0...(favPlaces.count - 1) {
                        favLocations.append(CLLocation(latitude: favLats[i], longitude: favLons[i]))
                    }
                    reloadFavorites()
                }
            }
        }
    }
    
    func recordLocation() {
        
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        // 検索したレコードの値を更新
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            if let error = error {
                print("レコードの位置情報更新エラー1: \(error)")
                return
            }
            for record in records! {
                record["currentLocation"] = self.mapView.userLocation.location
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
    
    func fetchParticipantIDs(planID: String, completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "planID-\(planID)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("予定参加者取得エラー: \(error)")
                return
            }
            
            if let placeName = record?.value(forKey: "placeName") as? String {
                self.meetingPlace = placeName
            }
            
            if let location = record?.value(forKey: "placeLatAndLon") as? CLLocation {
                self.meetingLocation = location
            }
            
            if let authorID = record?.value(forKey: "authorID") as? String {
                self.participantIDs.append(authorID)
            }
            
            if let participantIDs = record?.value(forKey: "participantIDs") as? [String] {
                for participantID in participantIDs {
                    self.participantIDs.append(participantID)
                }
                completion()
            }
        })
    }
    
    func fetchLocation(accountID: String, count: Int, completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(accountID)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("\(accountID)の位置情報取得エラー: \(error)")
                return
            }
            
            if let location = record?.value(forKey: "currentLocation") as? CLLocation {
                self.participantLocations[count] = location
                print("\(accountID)の位置: \(self.participantLocations[count])")
                completion()
            }
        })
    }
    
    func reloadFavorites() {
        
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
            
            if let error = error {
                print("データベースのお気に入り更新エラー1: \(error)")
                return
            }
            
            for record in records! {
                
                record["favPlaceNames"] = favPlaces as [String]
                record["favPlaceLocations"] = self.favLocations as [CLLocation]
                
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                    
                    if let error = error {
                        print("データベースのお気に入り更新エラー2: \(error)")
                        return
                    }
                    print("データベースのお気に入り更新成功")
                })
            }
        })
    }
    
    @objc func meeting() {
        print("meeting")
        
        for i in 0...(participantIDs.count - 1) {
            // 位置情報取得
            fetchLocation(accountID: participantIDs[i], count: i, completion: {
                // メインスレッドで処理
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    // ピンをアニメーションで移動
                    UIView.animate(withDuration: 1, animations: {
                        // ピンの座標を取得した位置情報に指定
                        self.participantAnnotations[i].coordinate = self.participantLocations[i].coordinate
                    }, completion: nil)
                }
            })
        }
    }
    
    func displayDetailsView() {
        detailsViewHeight.constant = 150
        addPlanButton.isHidden = true
        focusOnMyselfButton.isHidden = true
        placeNameLabel.isHidden = false
        placeAddressLabel.isHidden = false
        addFavButton.isHidden = false
        addPlanButtonD.isHidden = false
    }
    
    func hiddenDetailsView() {
        detailsViewHeight.constant = 0
        addPlanButton.isHidden = false
        focusOnMyselfButton.isHidden = false
        placeNameLabel.isHidden = true
        placeAddressLabel.isHidden = true
        addFavButton.isHidden = true
        addPlanButtonD.isHidden = true
    }
    
    // 遷移時に住所と緯度と経度を渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "toAddPlanVC" {
            let addPlanVC = segue.destination as! AddPlanViewController
            
            // 配列が空のとき（ロングタップでピンを立てたとき）
            if searchAnnotationArray.isEmpty == true {
                addPlanVC.place = self.annotation.title ?? ""
                addPlanVC.lat = self.lat
                addPlanVC.lon = self.lon
            }
            
            // 配列が空ではないとき（検索でピンを立てたとき）
            else {
                // 選択されているピンを新たな配列に格納
                let selectedSearchAnnotationArray = mapView.selectedAnnotations
                
                // 選択されているピンは1つのため、0番目を取り出す
                let selectedSearchAnnotation = selectedSearchAnnotationArray[0]
                
                // ピンの緯度と経度を取得
                let latStr = selectedSearchAnnotation.coordinate.latitude.description
                let lonStr = selectedSearchAnnotation.coordinate.longitude.description
                
                // 選択されているピンからタイトルを取得
                if let selectedSearchAnnotationTitle = selectedSearchAnnotation.title {
                    addPlanVC.place = selectedSearchAnnotationTitle ?? ""
                    addPlanVC.lat = latStr
                    addPlanVC.lon = lonStr
                }
            }
        }
    }
    
}

