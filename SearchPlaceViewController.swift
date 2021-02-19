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
    
    var searchedFavPlaceArray = [String]()
    var searchedFavAddressArray = [String]()
    var searchedFavLatArray = [Double]()
    var searchedFavLonArray = [Double]()
    
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
        
        self.searchedFavPlaceArray = favPlaces
        self.searchedFavAddressArray = favAddresses
        self.searchedFavLatArray = favLats
        self.searchedFavLonArray = favLons
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        // ------------------------------ ↓ お気に入り ------------------------------
        
        // テキストが空のとき、すべてのお気に入りを表示
        guard searchText.isEmpty == false else {
            
            self.searchedFavPlaceArray = favPlaces
            self.searchedFavAddressArray = favAddresses
            self.searchedFavLatArray = favLats
            self.searchedFavLonArray = favLons
            
            if placeArray.count == addressArray.count
                && searchedFavPlaceArray.count == searchedFavAddressArray.count {
                resultsTableView.reloadData()
            }
            
            return
        }
        
        // 前回の検索結果の配列を空にする
        searchedFavPlaceArray.removeAll()
        searchedFavAddressArray.removeAll()
        searchedFavLatArray.removeAll()
        searchedFavLonArray.removeAll()
        
        // テキストを入力したとき、テキストを含むお気に入りの場所名を[searchedFavPlaceArray]に格納
        searchedFavPlaceArray = favPlaces.filter({ item -> Bool in
            item.contains(searchText)
        })
        
        // 場所名をもとに住所・緯度・経度を格納
        for result in self.searchedFavPlaceArray {
            if let index = favPlaces.index(of: result) {
                self.searchedFavAddressArray.append(favAddresses[index])
                self.searchedFavLatArray.append(favLats[index])
                self.searchedFavLonArray.append(favLons[index])
            }
        }
        
        // ------------------------------ ↓ その他 ------------------------------
        
        // 前回の検索結果の配列を空にする
        placeArray.removeAll()
        addressArray.removeAll()
        latArray.removeAll()
        lonArray.removeAll()
        
        if placeArray.count == addressArray.count
            && searchedFavPlaceArray.count == searchedFavAddressArray.count {
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
        
        if self.placeArray.count == self.addressArray.count
            && self.searchedFavPlaceArray.count == self.searchedFavAddressArray.count {
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
                        if self.placeArray.count == self.addressArray.count
                            && self.searchedFavPlaceArray.count == self.searchedFavAddressArray.count {
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
                                if self.placeArray.count == self.addressArray.count
                                    && self.searchedFavPlaceArray.count == self.searchedFavAddressArray.count {
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
        self.searchedFavPlaceArray = favPlaces
        self.searchedFavAddressArray = favAddresses
        self.searchedFavLatArray = favLats
        self.searchedFavLonArray = favLons
        self.placeArray.removeAll()
        self.addressArray.removeAll()
        self.lonArray.removeAll()
        self.latArray.removeAll()
        
        self.resultsTableView.reloadData()
        
        // テキストを空にする
        self.placeSearchBar.text = ""
        // キーボードをとじる
        self.view.endEditing(true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionTitle = ["お気に入り", "その他"]
        return sectionTitle[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // お気に入り
        if section == 0 {
            return self.searchedFavPlaceArray.count
        }
        
        // その他
        else {
            return self.placeArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for:indexPath)
        
        // お気に入り
        if indexPath.section == 0 {
            
            cell.textLabel?.text = self.searchedFavPlaceArray[indexPath.row]
            
            if #available(iOS 13.0, *) {
                cell.detailTextLabel?.textColor = .secondaryLabel
            } else {
                cell.detailTextLabel?.textColor = .gray
            }
            cell.detailTextLabel?.text = self.searchedFavAddressArray[indexPath.row]
        }
        
        // その他
        else {
            
            cell.textLabel?.text = self.placeArray[indexPath.row]
            
            if #available(iOS 13.0, *) {
                cell.detailTextLabel?.textColor = .secondaryLabel
            } else {
                cell.detailTextLabel?.textColor = .gray
            }
            cell.detailTextLabel?.text = self.addressArray[indexPath.row]
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // お気に入り
        if resultsTableView.indexPathForSelectedRow?.section == 0 {
            self.place = searchedFavPlaceArray[(resultsTableView.indexPathForSelectedRow?.row)!]
            self.lat = searchedFavLatArray[(resultsTableView.indexPathForSelectedRow?.row)!].description
            self.lon = searchedFavLonArray[(resultsTableView.indexPathForSelectedRow?.row)!].description
        }
        
        // その他
        else {
            place = placeArray[(resultsTableView.indexPathForSelectedRow?.row)!]
            lat = latArray[(resultsTableView.indexPathForSelectedRow?.row)!]
            lon = lonArray[(resultsTableView.indexPathForSelectedRow?.row)!]
        }
    }
    
    
    
}
