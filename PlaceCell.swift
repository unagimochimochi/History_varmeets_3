//
//  PlaceCell.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/08/17.
//

import UIKit

class PlaceCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var displayPlaceTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        displayPlaceTextField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        self.contentView.endEditing(true) // contentView 不要？
        
        return true
    }
    
}
