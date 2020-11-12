//
//  PlaceViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/08/18.
//

import UIKit
import MapKit
import CoreLocation

class PlaceViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var place: String?
    var lonStr: String?
    var latStr: String?
    
    var pointAno: MKPointAnnotation = MKPointAnnotation()
    let geocoder = CLGeocoder()
    
    @IBOutlet weak var mapView: MKMapView!
    var locManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        locManager = CLLocationManager()
        locManager.delegate = self
        
        // 初期化関数を呼び出して縮尺を設定
        initMap()
        
        if let placeName = self.place {
            self.navigationItem.title = placeName
            print(placeName)
        }
        
        if let lonStr = self.lonStr, let latStr = self.latStr {
            // String型からDouble型に変換
            let lonNum = Double(lonStr)!
            let latNum = Double(latStr)!
            
            // ピンの中心に緯度と経度をセット
            let center = CLLocationCoordinate2D(latitude: latNum, longitude: lonNum)
            pointAno.coordinate = center
            // ピンをMKMapViewの中心にする
            mapView.centerCoordinate = center
            // ピンを立てる
            mapView.addAnnotation(pointAno)
            // ピンを最初から選択状態にする
            mapView.selectAnnotation(pointAno, animated: true)
            // タイトルに場所の名前を表示
            pointAno.title = place
            
            // 緯度と経度から住所を特定
            let location = CLLocation(latitude: latNum, longitude: lonNum)
            geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: GeocodeCompHandler(placemarks:error:))
        }
    }
    
    // 地図をとじる
    @IBAction func doneButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 地図の初期化関数
    func initMap() {
        // 縮尺
        var region: MKCoordinateRegion = mapView.region
        region.span.latitudeDelta = 0.02
        region.span.longitudeDelta = 0.02
        mapView.setRegion(region, animated: true)
    }
    
    // ピンの詳細設定
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let anoView = MKPinAnnotationView(annotation: pointAno, reuseIdentifier: nil)
        
        // 吹き出しを表示
        anoView.canShowCallout = true
        
        return anoView
    }
    
    // reverseGeocodeLocation(_:preferredLocale:completionHandler:)の第3引数
    // 何かに使えそう&クロージャに慣れないので外側に関数を作成した
    func GeocodeCompHandler(placemarks: [CLPlacemark]?, error: Error?) {
        guard let placemark = placemarks?.first, error == nil,
            let administrativeArea = placemark.administrativeArea, //県
            let locality = placemark.locality, // 市区町村
            let throughfare = placemark.thoroughfare, // 丁目を含む地名
            let subThoroughfare = placemark.subThoroughfare // 番地
            else {
                return
        }
        
        // サブタイトルに住所を表示
        self.pointAno.subtitle = administrativeArea + locality + throughfare + subThoroughfare
    }
    
}
