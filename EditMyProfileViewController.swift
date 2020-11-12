//
//  EditMyProfileViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/09/19.
//
//  キーボードでbioTextViewが隠れないようにする https://i-app-tec.com/ios/textfield-scroll.html

import UIKit
import CloudKit

class EditMyProfileViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate {
    
    var name: String?
    var bio: String?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewInScrollView: UIView!
    
    @IBOutlet weak var icon: UIButton!
    @IBOutlet weak var header: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var bioTextView: UITextView!
    
    var check = [true, true]
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        nameTextField.delegate = self
        bioTextView.delegate = self
        
        icon.layer.borderColor = UIColor.gray.cgColor // 枠線の色
        icon.layer.borderWidth = 0.5 // 枠線の太さ
        icon.layer.cornerRadius = icon.bounds.width / 2 // 丸くする
        icon.layer.masksToBounds = true // 丸の外側を消す
        
        if let name = myName {
            nameTextField.text = name
        }
        
        // bioTextViewのフォント設定（不具合でTimesNewRomanになるのを防ぐ）
        let stringAttributes: [NSAttributedString.Key : Any] = [.font : UIFont.systemFont(ofSize: 14.0)]
        
        if let existingBio = bio {
            bioTextView.attributedText = NSAttributedString(string: existingBio, attributes: stringAttributes)
            if #available(iOS 13.0, *) {
                bioTextView.textColor = .label
            } else {
                bioTextView.textColor = .black
            }
        } else {
            bioTextView.attributedText = NSAttributedString(string: "自己紹介（100文字以内）", attributes: stringAttributes)
            if #available(iOS 13.0, *) {
                bioTextView.textColor = .placeholderText
            } else {
                bioTextView.textColor = .gray
            }
        }

        // 名前入力時の判定
        nameTextField.addTarget(self, action: #selector(nameTextEditingChanged), for: UIControl.Event.editingChanged)
        
        // カスタムバー
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        toolbar.sizeToFit()
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spaceItem, doneItem], animated: true)
        
        // bioTextViewにはカスタムバーをつける
        bioTextView.inputAccessoryView = toolbar
        
        // 表示部分のscrollViewのサイズと位置
        let screenSize = UIScreen.main.bounds
        scrollView.frame.size = CGSize(width: screenSize.width, height: screenSize.height)
        
        // scrollViewの大きさをスクリーンの縦方向の2倍にする
        scrollView.contentSize = CGSize(width: screenSize.width, height: (screenSize.height)*2)
        
        viewInScrollView.addSubview(header)
        viewInScrollView.addSubview(icon)
        viewInScrollView.addSubview(nameTextField)
        viewInScrollView.addSubview(bioTextView)
        
        scrollView.addSubview(viewInScrollView)
        
        self.view.addSubview(scrollView)
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 名前入力時の判定
    @objc func nameTextEditingChanged(textField: UITextField) {
        if let text = textField.text {
            // 入力されていないとき
            if text.count == 0 {
                noGood(num: 0)
            }
                
            // 21文字以上のとき
            else if text.count > 20 {
                noGood(num: 0)
            }
                
            // 1~20文字のとき
            else {
                check.remove(at: 0)
                check.insert(true, at: 0)
            }
        }
    }
    
    // 自己紹介入力時の判定
    func textViewDidChange(_ textView: UITextView) {
        // 100文字以下のとき
        if textView.text.count <= 100 {
            check.remove(at: 1)
            check.insert(true, at: 1)
        }
        
        // 101文字以上のとき
        else {
            noGood(num: 1)
        }
    }
    
    func noGood(num: Int) {
        check.remove(at: num)
        check.insert(false, at: num)
        saveButton.isEnabled = false
        saveButton.image = UIImage(named: "SaveButton_gray")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.endEditing(true)
        
        // 名前、自己紹介の入力条件をクリアしていれば保存ボタンを有効にする
        if check.contains(false) == false {
            saveButton.isEnabled = true
            saveButton.image = UIImage(named: "SaveButton")
            
            myName = nameTextField.text!
            // 初期テキストが入っていたら変数に空文字を代入
            if bioTextView.text == "自己紹介（100文字以内）" {
                bio = ""
            } else {
                bio = bioTextView.text
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        
        // 名前、自己紹介の入力条件をクリアしていれば保存ボタンを有効にする
        if check.contains(false) == false {
            saveButton.isEnabled = true
            saveButton.image = UIImage(named: "SaveButton")
            
            myName = nameTextField.text!
            // 初期テキストが入っていたら変数に空文字を代入
            if bioTextView.text == "自己紹介（100文字以内）" {
                bio = ""
            } else {
                bio = bioTextView.text
            }
        }
        
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // 初期テキストが入っていたらタップで空にする
        if textView.text == "自己紹介（100文字以内）" {
            textView.text = ""
        }
        
        if #available(iOS 13.0, *) {
            textView.textColor = .label
        } else {
            textView.textColor = .black
        }
        
        // 入力中は保存ボタンを無効にする
        saveButton.isEnabled = false
        saveButton.image = UIImage(named: "SaveButton_gray")
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        textView.endEditing(true)
        
        // 名前、自己紹介の入力条件をクリアしていれば続行ボタンを有効にする
        if check.contains(false) == false {
            saveButton.isEnabled = true
            saveButton.image = UIImage(named: "SaveButton")
            
            myName = nameTextField.text!
            bio = bioTextView.text
        }
    }
    
    @objc func done() {
        bioTextView.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: self.view.window)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        // bioTextViewの下
        let bottomBioTextView = bioTextView.frame.origin.y + bioTextView.frame.height
        // キーボードの上
        let topKeyboard = UIScreen.main.bounds.height - keyboardFrame.size.height
        // 重なり
        let distance = bottomBioTextView - topKeyboard
        
        if distance >= 0 {
            scrollView.contentOffset.y = distance + 50
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentOffset.y = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            return
        }
        
        name = nameTextField.text!
        if bioTextView.text == "自己紹介（100文字以内）" {
            bio = ""
        } else {
            bio = bioTextView.text
        }
    }

}

