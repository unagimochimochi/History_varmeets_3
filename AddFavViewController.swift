//
//  AddFavViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2021/03/03.
//

import UIKit
import MapKit

class AddFavViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultsTableView: UITableView!
    
    var searchedPlaces = [String]()
    var searchedAddresses = [String]()
    var searchedLats = [Double]()
    var searchedLons = [Double]()
    
    var selectedPlace: String?
    var selectedAddress: String?
    var selectedLat: Double?
    var selectedLon: Double?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        // 前回の検索結果の配列を空にする
        self.searchedPlaces.removeAll()
        self.searchedAddresses.removeAll()
        self.searchedLats.removeAll()
        self.searchedLons.removeAll()
        
        // 場所名と住所の数が同じときだけUI更新（異なるとクラッシュするため）
        if self.searchedPlaces.count == self.searchedAddresses.count {
            self.resultsTableView.reloadData()
        }
        
        // 検索条件を作成
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBar.text

        // 検索開始
        let localSearch = MKLocalSearch(request: request)
        localSearch.start(completionHandler: {(response, error) in
            
            // 検索がヒットしたとき
            if let response = response {
                
                for searchedPlace in response.mapItems {
                    
                    if let error = error {
                        print("検索エラー: \(error)")
                        return
                    }
                    
                    let place = searchedPlace.placemark.name
                    let lat = searchedPlace.placemark.coordinate.latitude
                    let lon = searchedPlace.placemark.coordinate.longitude
                    
                    guard place != nil else {
                        return
                    }
                    
                    // 配列に検索結果を追加
                    self.searchedPlaces.append(place!)
                    self.searchedLats.append(lat)
                    self.searchedLons.append(lon)
                    
                    // MapItemから住所を取得できるとき
                    if let administrativeArea = searchedPlace.placemark.administrativeArea, // 県
                       let locality = searchedPlace.placemark.locality, // 市区町村
                       let throughfare = searchedPlace.placemark.thoroughfare, // 丁目を含む地名
                       let subThoroughfare = searchedPlace.placemark.subThoroughfare { // 番地
                        
                        // 配列に住所を追加
                        self.searchedAddresses.append(administrativeArea + locality + throughfare + subThoroughfare)
                        
                        // メインスレッドで処理
                        DispatchQueue.main.async {
                            // 場所名と住所の数が同じときだけUI更新（異なるとクラッシュするため）
                            if self.searchedPlaces.count == self.searchedAddresses.count {
                                self.resultsTableView.reloadData()
                            }
                        }
                    }
                    
                    // MapItemから住所を取得できないとき、緯度経度から取得
                    else {
                        
                        let geocoder = CLGeocoder()
                        let location = CLLocation(latitude: lat, longitude: lon)
                        
                        geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: {(placemarks, error) in
                            
                            if let error = error {
                                print("逆ジオコーディングエラー: \(error)")
                                self.searchedAddresses.append("住所を取得できません")
                                print("場所名数: \(self.searchedPlaces.count), 住所数: \(self.searchedAddresses.count)")
                                return
                            }
                            
                            if let placemark = placemarks?.first,
                               let administrativeArea = placemark.administrativeArea, //県
                               let locality = placemark.locality, // 市区町村
                               let throughfare = placemark.thoroughfare, // 丁目を含む地名
                               let subThoroughfare = placemark.subThoroughfare { // 番地
                               
                                // 配列に住所を追加
                                self.searchedAddresses.append(administrativeArea + locality + throughfare + subThoroughfare)
                                // メインスレッドで処理
                                DispatchQueue.main.async {
                                    // 場所名と住所の数が同じときだけUI更新（異なるとクラッシュするため）
                                    if self.searchedPlaces.count == self.searchedAddresses.count {
                                        self.resultsTableView.reloadData()
                                    }
                                }
                            }
                        })
                    }
                }
            }
            
            // 検索がヒットしなかったとき
            else {
                print("検索結果なし")
            }
        })
    }
    
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードをとじる
        self.view.endEditing(true)
        // UI更新
        if self.searchedPlaces.count == self.searchedAddresses.count {
            self.resultsTableView.reloadData()
        }
    }
    
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        // 前回の検索結果の配列を空にする
        self.searchedPlaces.removeAll()
        self.searchedAddresses.removeAll()
        self.searchedLats.removeAll()
        self.searchedLons.removeAll()
        
        // テキストを空にする
        searchBar.text = ""
        // キーボードをとじる
        self.view.endEditing(true)
        // UI更新
        if self.searchedPlaces.count == self.searchedAddresses.count {
            self.resultsTableView.reloadData()
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchedPlaces.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        
        cell.textLabel?.text = self.searchedPlaces[indexPath.row]
        cell.detailTextLabel?.text = self.searchedAddresses[indexPath.row]
        
        if #available(iOS 13.0, *) {
            cell.detailTextLabel?.textColor = .secondaryLabel
        } else {
            cell.detailTextLabel?.textColor = .gray
        }
        
        return cell
    }

    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.selectedPlace = self.searchedPlaces[(resultsTableView.indexPathForSelectedRow?.row)!]
        self.selectedAddress = self.searchedAddresses[(resultsTableView.indexPathForSelectedRow?.row)!]
        self.selectedLat = self.searchedLats[(resultsTableView.indexPathForSelectedRow?.row)!]
        self.selectedLon = self.searchedLons[(resultsTableView.indexPathForSelectedRow?.row)!]
    }
}
