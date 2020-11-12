//
//  SearchPlaceViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/08/23.
//

import UIKit
import MapKit

class SearchPlaceViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var placeSearchBar: UISearchBar!
    @IBOutlet weak var resultsTableView: UITableView!
    
    let geocoder = CLGeocoder()
    
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
        print(dateAndTime ?? "変数〈dateAndTime〉はnilです")
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 前回の検索結果の配列を空にする
        placeArray.removeAll()
        addressArray.removeAll()
        latArray.removeAll()
        lonArray.removeAll()
        
        resultsTableView.reloadData()
        
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
    }
    
    // start(completionHandler:)の引数
    func LocalSearchCompHandler(response: MKLocalSearch.Response?, error: Error?) -> Void {
        // 検索がヒットしたとき
        if let response = response {
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
                    
                    guard let administrativeArea = searchLocation.placemark.administrativeArea, // 県
                        let locality = searchLocation.placemark.locality, // 市区町村
                        let throughfare = searchLocation.placemark.thoroughfare, // 丁目を含む地名
                        let subThoroughfare = searchLocation.placemark.subThoroughfare // 番地
                        else {
                            return
                    }
                    
                    // 配列に住所を追加
                    addressArray.append(administrativeArea + locality + throughfare + subThoroughfare)
                    
                } else {
                    print("error")
                }
            }
            
            resultsTableView.reloadData()
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
        
        cell.detailTextLabel?.textColor = UIColor.gray
        cell.detailTextLabel?.text = addressArray[indexPath.row]
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        place = placeArray[(resultsTableView.indexPathForSelectedRow?.row)!]
        lat = latArray[(resultsTableView.indexPathForSelectedRow?.row)!]
        lon = lonArray[(resultsTableView.indexPathForSelectedRow?.row)!]
    }
    
}
