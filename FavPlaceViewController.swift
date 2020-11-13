//
//  FavPlaceViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/10/15.
//

import UIKit
import MapKit
import CloudKit

class FavPlaceViewController: UIViewController, MKMapViewDelegate {
    
    var place: String?
    var lat: Double?
    var lon: Double?
    
    var annotation = MKPointAnnotation()
    
    let geocoder = CLGeocoder()
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    var favLocations = [CLLocation]()    // データベース保存用

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var favButton: UIButton!
    @IBOutlet weak var addPlanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self

        initMap()
        
        if let placeName = place {
            
            self.navigationItem.title = placeName
            
            if let lat = self.lat, let lon = self.lon {
                
                // ピンに緯度と経度をセット
                let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                annotation.coordinate = center
                // ピンをMKMapViewの中心にする
                mapView.centerCoordinate = center
                // ピンを立てる
                mapView.addAnnotation(annotation)
                // ピンを最初から選択状態にする
                mapView.selectAnnotation(annotation, animated: true)
                // ピンのタイトルに場所の名前を表示
                annotation.title = placeName
                
                // 緯度と経度から住所を特定
                let location = CLLocation(latitude: lat, longitude: lon)
                
                geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) in
                    
                    if let error = error {
                        print("住所取得エラー: \(error)")
                        return
                    }
                    
                    if let placemark = placemarks?.first,
                       let administrativeArea = placemark.administrativeArea, //県
                       let locality = placemark.locality, // 市区町村
                       let throughfare = placemark.thoroughfare, // 丁目を含む地名
                       let subThoroughfare = placemark.subThoroughfare { // 番地
                        
                        // サブタイトルに住所を表示
                        self.annotation.subtitle = administrativeArea + locality + throughfare + subThoroughfare
                    }
                })
            }
        }
        
        // お気に入りボタン
        favButton.setTitleColor(.white, for: .normal)
        favButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        favButton.backgroundColor = .orange
        favButton.layer.masksToBounds = true
        favButton.layer.cornerRadius = 8
        
        // 予定を追加ボタン
        addPlanButton.setTitleColor(UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0), for: .normal)
        addPlanButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        addPlanButton.backgroundColor = .white
        addPlanButton.layer.borderColor = UIColor.orange.cgColor
        addPlanButton.layer.borderWidth = 1
        addPlanButton.layer.masksToBounds = true
        addPlanButton.layer.cornerRadius = 8
    }
    
    func initMap() {
        // 縮尺
        var region = mapView.region
        region.span.latitudeDelta = 0.02
        region.span.longitudeDelta = 0.02
        mapView.setRegion(region, animated: true)
    }
    
    // ピンの詳細設定
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
        
        // 吹き出しを表示
        annotationView.canShowCallout = true
        
        return annotationView
    }
    
    @IBAction func tappedFavButton(_ sender: Any) {
        
        // すでにお気に入り登録されているとき
        if favAddresses.contains(annotation.subtitle!) {
            
            if let index = favAddresses.index(of: annotation.subtitle!) {
                
                favPlaces.remove(at: index)
                userDefaults.set(favPlaces, forKey: "favPlaces")
                
                favAddresses.remove(at: index)
                userDefaults.set(favAddresses, forKey: "favAddresses")
                
                favLats.remove(at: index)
                userDefaults.set(favLats, forKey: "favLats")
                                    
                favLons.remove(at: index)
                userDefaults.set(favLons, forKey: "favLons")
                
                let dialog = UIAlertController(title: "お気に入り解除", message: "\(annotation.title!)をお気に入りから削除しました。", preferredStyle: .alert)
                // OKボタン
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // ダイアログを表示
                self.present(dialog, animated: true, completion: nil)
                
                // ボタンの見た目をスイッチ
                favButton.setTitle("お気に入り登録", for: .normal)
                favButton.setTitleColor(UIColor(hue: 0.07, saturation: 0.9, brightness: 0.95, alpha: 1.0), for: .normal)
                favButton.backgroundColor = .white
                favButton.layer.borderColor = UIColor.orange.cgColor
                favButton.layer.borderWidth = 1
                
                // データベースに保存
                favLocations.removeAll()
                if favPlaces.isEmpty == false {
                    for i in 0...(favPlaces.count - 1) {
                        favLocations.append(CLLocation(latitude: favLats[i], longitude: favLons[i]))
                    }
                }
                reloadFavorites()
            }
        }
        
        // お気に入り登録
        else {
            favPlaces.append(annotation.title!)
            userDefaults.set(favPlaces, forKey: "favPlaces")
            
            favAddresses.append(annotation.subtitle!)
            userDefaults.set(favAddresses, forKey: "favAddresses")
                            
            favLats.append(annotation.coordinate.latitude)
            userDefaults.set(favLats, forKey: "favLats")
                            
            favLons.append(annotation.coordinate.longitude)
            userDefaults.set(favLons, forKey: "favLons")
                            
            let dialog = UIAlertController(title: "お気に入り登録", message: "\(annotation.title!)をお気に入りに追加しました。", preferredStyle: .alert)
            // OKボタン
            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            // ダイアログを表示
            self.present(dialog, animated: true, completion: nil)
            
            // ボタンの見た目をスイッチ
            favButton.setTitle("お気に入り解除", for: .normal)
            favButton.setTitleColor(.white, for: .normal)
            favButton.backgroundColor = .orange
            
            // データベースに保存
            favLocations.removeAll()
            for i in 0...(favPlaces.count - 1) {
                favLocations.append(CLLocation(latitude: favLats[i], longitude: favLons[i]))
            }
            reloadFavorites()
        }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "FavPlaceVCtoAddPlanVC" {
            let addPlanVC = segue.destination as! AddPlanViewController
            addPlanVC.place = annotation.title!
            addPlanVC.lat = lat!.description
            addPlanVC.lon = lon!.description
        }
    }
}
