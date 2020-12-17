//
//  SearchPlaceViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/08/23.
//

import UIKit
import CoreLocation
import MapKit

class SearchPlaceViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var placeSearchBar: UISearchBar!
    @IBOutlet weak var resultsTableView: UITableView!
    
    var place: String?
    var lat: String?
    var lon: String?
    
    var placeArray = [String]()
    var addressArray = [String]()
    var latArray = [String]()
    var lonArray = [String]()
    
    // AddPlanVCで日時が出力されている場合、一時的に保存
    var planID: String?
    var dateAndTime: String?
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placeSearchBar.delegate = self
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 前回の検索結果の配列を空にする
        placeArray.removeAll()
        addressArray.removeAll()
        latArray.removeAll()
        lonArray.removeAll()
        
        if placeArray.count == addressArray.count {
            resultsTableView.reloadData()
        }
        
        // 検索条件を作成
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = placeSearchBar.text
        
        // 検索範囲
        request.region = MKCoordinateRegion.init()
        
        let localSearch = MKLocalSearch(request: request)
        localSearch.start(completionHandler: LocalSearchCompHandler(response:error:))
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードをとじる
        self.view.endEditing(true)
        
        if placeArray.count == addressArray.count {
            resultsTableView.reloadData()
        }
    }
    
    // start(completionHandler:)の引数
    func LocalSearchCompHandler(response: MKLocalSearch.Response?, error: Error?) -> Void {
        // 検索がヒットしたとき
        if let response = response {
            print("\(response.mapItems.count)個ヒット")
            for searchLocation in (response.mapItems) {
                if error == nil {
                    let place = searchLocation.placemark.name
                    let latNum = searchLocation.placemark.coordinate.latitude
                    let lonNum = searchLocation.placemark.coordinate.longitude
                    
                    if let place = place {
                        // 配列に検索結果を追加
                        placeArray.append(place)
                        latArray.append(latNum.description)
                        lonArray.append(lonNum.description)
                    }
                    
                    if let administrativeArea = searchLocation.placemark.administrativeArea, // 県
                       let locality = searchLocation.placemark.locality, // 市区町村
                       let throughfare = searchLocation.placemark.thoroughfare, // 丁目を含む地名
                       let subThoroughfare = searchLocation.placemark.subThoroughfare { // 番地
                        // 配列に住所を追加
                        addressArray.append(administrativeArea + locality + throughfare + subThoroughfare)
                        // UI更新
                        if self.placeArray.count == self.addressArray.count {
                            self.resultsTableView.reloadData()
                        }
                    }
                    
                    // MapItemから住所を取得できない場合、緯度経度から取得
                    else {
                        
                        let geocoder = CLGeocoder()
                        let location = CLLocation(latitude: latNum, longitude: lonNum)
                        
                        geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: {(placemarks, error) in
                            
                            guard let placemark = placemarks?.first, error == nil,
                                  let administrativeArea = placemark.administrativeArea, //県
                                  let locality = placemark.locality, // 市区町村
                                  let throughfare = placemark.thoroughfare, // 丁目を含む地名
                                  let subThoroughfare = placemark.subThoroughfare // 番地
                            else {
                                self.addressArray.append("住所を取得できません")
                                return
                            }
                            // 配列に住所を追加
                            self.addressArray.append(administrativeArea + locality + throughfare + subThoroughfare)
                            // メインスレッドでUI更新
                            DispatchQueue.main.async {
                                if self.placeArray.count == self.addressArray.count {
                                    self.resultsTableView.reloadData()
                                }
                            }
                        })
                    }
                    
                } else {
                    print("error")
                }
            }
        }
        
        // 検索がヒットしなかったとき
        else {
            print("検索結果なし")
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("検索キャンセル")
        
        // 前回の検索結果の配列を空にする
        placeArray.removeAll()
        addressArray.removeAll()
        lonArray.removeAll()
        latArray.removeAll()
        
        resultsTableView.reloadData()
        
        // テキストを空にする
        placeSearchBar.text = ""
        // キーボードをとじる
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for:indexPath)
        cell.textLabel?.text = placeArray[indexPath.row]
        
        if #available(iOS 13.0, *) {
            cell.detailTextLabel?.textColor = .placeholderText
        } else {
            cell.detailTextLabel?.textColor = .gray
        }
        cell.detailTextLabel?.text = addressArray[indexPath.row]
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        place = placeArray[(resultsTableView.indexPathForSelectedRow?.row)!]
        lat = latArray[(resultsTableView.indexPathForSelectedRow?.row)!]
        lon = lonArray[(resultsTableView.indexPathForSelectedRow?.row)!]
    }
    
}
