//
//  DateAndTimeCell.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/06/16.
//
// datePicker https://qiita.com/ryomaDsakamoto/items/ab4ae031706a8133f193
// CGRectの書き方 https://qiita.com/MilanistaDev/items/fbf5fb890d9a3a7180cd

import UIKit

class DateAndTimeCell: UITableViewCell {
    
    @IBOutlet weak var displayDateAndTimeTextField: UITextField!
    
    var datePicker: UIDatePicker = UIDatePicker()
    var estimatedTime: Date?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // ピッカー設定
        datePicker.datePickerMode = UIDatePicker.Mode.dateAndTime
        datePicker.timeZone = NSTimeZone.local
        datePicker.locale = Locale(identifier: "ja_JP")
            
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        toolbar.sizeToFit()
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spaceItem, doneItem], animated: true)
        
        // UITextFieldをタップしたとき、通常のキーボードではなくUIDatePickerを表示する
        displayDateAndTimeTextField.inputView = datePicker
        displayDateAndTimeTextField.inputAccessoryView = toolbar
    }
    
    @objc func done() {
        displayDateAndTimeTextField.endEditing(true)
        
        // 日付のフォーマット
        let formatter = DateFormatter()
        
        // 現地仕様で日付の出力
        formatter.timeStyle = .short
        formatter.dateStyle = .full
        formatter.timeZone = NSTimeZone.local
        formatter.locale = Locale(identifier: "ja_JP")

        // UIDatePickerで指定した日時が表示される
        displayDateAndTimeTextField.text = "\(formatter.string(from: datePicker.date))"
        
        // 指定した日時の秒を0にして変数に代入
        estimatedTime = resetTime(date: datePicker.date)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // 秒を0にする
    func resetTime(date: Date) -> Date {
        let calendar: Calendar = Calendar(identifier: .japanese)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        components.second = 0

        return calendar.date(from: components)!
    }
}
