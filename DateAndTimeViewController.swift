//
//  DateAndTimeViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/05/24.
//

import UIKit

class DateAndTimeViewController: UIViewController {
    
    @IBOutlet weak var TextField: UITextField!
    
    //UIDatePickerを定義するための変数
    var datePicker: UIDatePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ピッカー設定
        datePicker.datePickerMode = UIDatePicker.Mode.dateAndTime
        datePicker.timeZone = NSTimeZone.local
        datePicker.locale = Locale.current
        TextField.inputView = datePicker
        
        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        
        // インプットビュー設定(紐づいているUITextfieldへ代入)
        TextField.inputView = datePicker
        TextField.inputAccessoryView = toolbar
    }
    
    // UIDatePickerのDoneを押したら発火
    @objc func done() {
        TextField.endEditing(true)
        
        // 日付のフォーマット
        let formatter = DateFormatter()
        
        //日本仕様で日付の出力
        formatter.timeStyle = .short
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "ja_JP")
        
        //(from: datePicker.date))を指定してあげることで
        //datePickerで指定した日付が表示される
        TextField.text = "\(formatter.string(from: datePicker.date))"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
