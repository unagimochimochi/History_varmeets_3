//
//  FavViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/04/10.
//

import UIKit
import CloudKit

var favPlaces = [String]()
var favAddresses = [String]()
var favLats = [Double]()
var favLons = [Double]()

class FavViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var favTableView: UITableView!
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var favLocations = [CLLocation]()    // データベース保存用
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        favTableView.reloadData()
        
        favLocations.removeAll()
        if favPlaces.isEmpty == false {
            for i in 0...(favPlaces.count - 1) {
                favLocations.append(CLLocation(latitude: favLats[i], longitude: favLons[i]))
            }
        }
    }
    
    
    
    // お気に入り追加画面からの巻き戻し
    @IBAction func addedFavPlace(sender: UIStoryboardSegue) {
        
        if let addFavVC = sender.source as? AddFavViewController {
            
            if let newPlace = addFavVC.selectedPlace,
               let newAddress = addFavVC.selectedAddress,
               let newLat = addFavVC.selectedLat,
               let newLon = addFavVC.selectedLon {
                
                favPlaces.append(newPlace)
                favAddresses.append(newAddress)
                favLats.append(newLat)
                favLons.append(newLon)
                favLocations.append(CLLocation(latitude: newLat, longitude: newLon))
                
                self.favTableView.reloadData()
                
                let predicate = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
                let query = CKQuery(recordType: "Accounts", predicate: predicate)
                
                self.publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                    
                    if let error = error {
                        print("データベースのお気に入り更新エラー1: \(error)")
                        return
                    }
                    
                    for record in records! {
                        
                        record["favPlaceNames"] = favPlaces as [String]
                        record["favPlaceLocations"] = self.favLocations as [CLLocation]
                        
                        self.publicDatabase.save(record, completionHandler: {(record,error) in
                            
                            if let error = error {
                                print("データベースのお気に入り更新エラー2: \(error)")
                                return
                            }
                            print("データベースのお気に入り更新成功")
                        })
                    }
                })
            }
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favPlaces.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavCell", for:indexPath)
        
        if favPlaces.isEmpty == false {
            cell.textLabel?.text = favPlaces[indexPath.row]
            cell.detailTextLabel?.text = favAddresses[indexPath.row]

        } else {
            cell.textLabel?.text = "お気に入りはありません"
        }
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルの選択を解除
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            remove(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    
    func remove(index: Int) {
        
        favPlaces.remove(at: index)
        userDefaults.set(favPlaces, forKey: "favPlaces")
        
        favAddresses.remove(at: index)
        userDefaults.set(favAddresses, forKey: "favAddresses")
        
        favLats.remove(at: index)
        userDefaults.set(favLats, forKey: "favLats")
        
        favLons.remove(at: index)
        userDefaults.set(favLons, forKey: "favLons")
        
        favLocations.remove(at: index)
        
        // 検索条件を作成
        let predicate = NSPredicate(format: "accountID == %@", argumentArray: [myID!])
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
                
        // データベースの予定一覧からお気に入りを削除
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: {(records, error) in
                    
            if let error = error {
                print("データベースのお気に入り削除エラー1: \(error)")
                return
            }
                    
            for record in records! {
                
                record["favPlaceNames"] = favPlaces as [String]
                record["favPlaceLocations"] = self.favLocations as [CLLocation]
                        
                self.publicDatabase.save(record, completionHandler: {(record, error) in
                            
                    if let error = error {
                        print("データベースのお気に入り削除エラー2: \(error)")
                        return
                    }
                    print("データベースのお気に入り削除成功")
                })
            }
        })
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "toFavPlaceVC" {
            let favPlaceVC = segue.destination as! FavPlaceViewController
            favPlaceVC.place = favPlaces[(favTableView.indexPathForSelectedRow?.row)!]
            favPlaceVC.lat = favLats[(favTableView.indexPathForSelectedRow?.row)!]
            favPlaceVC.lon = favLons[(favTableView.indexPathForSelectedRow?.row)!]
        }
    }

}
