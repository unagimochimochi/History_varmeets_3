//
//  LoginViewController.swift
//  varmeets
//
//  Created by 持田侑菜 on 2020/10/22.
//

import UIKit
import CloudKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    var inputID: String?
    var inputPassword: String?
    
    var accountNotFound: Bool?
    var fetchedName: String?
    var fetchedPassword: String?

    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    
    var inputCheck = [false, false]
    @IBOutlet weak var continueButton: UIBarButtonItem!
    
    var timer: Timer!
    var passwordCheck: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        idTextField.delegate = self
        passwordTextField.delegate = self
        
        // ID入力時の判定
        idTextField.addTarget(self, action: #selector(idTextEditingChanged), for: UIControl.Event.editingChanged)
        // パスワード入力時の判定
        passwordTextField.addTarget(self, action: #selector(passwordTextFieldEditingChanged), for: UIControl.Event.editingChanged)
    }
    
    // ID入力時の判定
    @objc func idTextEditingChanged(textField: UITextField) {
        
        if let text = textField.text {
            // 4文字未満のとき
            if text.count < 4 {
                idLabel.text = "4文字以上で入力してください"
                noGood(num: 0)
            }
            
            // 21文字以上のとき
            else if text.count > 20 {
                idLabel.text = "20文字以下で入力してください"
                noGood(num: 0)
            }
            
            // 4~20文字のとき
            else {
                // 半角英数字と"_"で構成されているとき
                if idTextFieldCharactersSet(textField, text) == true {
                    // OK!
                    idLabel.text = "OK!"
                    idLabel.textColor = .blue
                    
                    inputCheck[0] = true
                }
                
                // 使用できない文字が含まれているとき
                else {
                    idLabel.text = "半角英数字とアンダーバー（_）のみで構成してください"
                    noGood(num: 0)
                }
            }
        }
    }
    
    // ID入力文字列の判定
    func idTextFieldCharactersSet(_ textField: UITextField, _ text: String) -> Bool {
        // 入力できる文字
        let characters = CharacterSet(charactersIn:"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_").inverted
            
        let components = text.components(separatedBy: characters)
        let filtered = components.joined(separator: "")
            
        if text == filtered {
            return true
        } else {
            return false
        }
    }
    
    // パスワード入力時の判定
    @objc func passwordTextFieldEditingChanged(textField: UITextField) {
            
        if let text = textField.text {
            // 8文字未満のとき
            if text.count < 8 {
                passwordLabel.text = "8文字以上で入力してください"
                noGood(num: 1)
            }
                
            // 33文字以上のとき
            else if text.count > 32 {
                passwordLabel.text = "32文字以下で入力してください"
                noGood(num: 1)
            }
                
            // 8~32文字のとき
            else {
                // 半角英数字で構成されているとき
                if passwordTextFieldCharactersSet(textField, text) == true {
                    // OK!
                    passwordLabel.text = "OK!"
                    passwordLabel.textColor = .blue
                        
                    inputCheck[1] = true
                }
                    
                // 使用できない文字が含まれているとき
                else {
                    passwordLabel.text = "半角英数字のみで構成してください"
                    noGood(num: 1)
                }
            }
        }
    }
        
    // パスワード入力文字列の判定
    func passwordTextFieldCharactersSet(_ textField: UITextField, _ text: String) -> Bool {
        // 入力できる文字
        let characters = CharacterSet(charactersIn:"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz").inverted
            
        let components = text.components(separatedBy: characters)
        let filtered = components.joined(separator: "")
            
        if text == filtered {
            return true
        } else {
            return false
        }
    }
    
    // 警告を表示 & 続行ボタンを無効にする
    func noGood(num: Int) {
        
        inputCheck[num] = false
        
        // ラベルが初期テキストではないとき（入力済みのとき）、ラベルを赤くする
        if inputCheck[0] == false && idLabel.text != "半角英数字・アンダーバー（_）を入力できます" {
            idLabel.textColor = .red
        }
        if inputCheck[1] == false && passwordLabel.text != "半角英数字を入力できます" {
            passwordLabel.textColor = .red
        }
        
        continueButton.isEnabled = false
        continueButton.image = UIImage(named: "ContinueButton_gray")
    }
    
    // 入力中は続行ボタンを無効にする
    func textFieldDidBeginEditing(_ textField: UITextField) {
        continueButton.isEnabled = false
        continueButton.image = UIImage(named: "ContinueButton_gray")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.endEditing(true)
        
        // ID、パスワードの入力条件をクリアしていれば続行ボタンを有効にする
        if inputCheck.contains(false) == false {
            continueButton.isEnabled = true
            continueButton.image = UIImage(named: "ContinueButton")
        }
        
        if textField == idTextField {
            inputID = textField.text
            print(inputID!)
        }
        
        if textField == passwordTextField {
            inputPassword = textField.text
            print(inputPassword!)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        
        // ID、パスワードの入力条件をクリアしていれば続行ボタンを有効にする
        if inputCheck.contains(false) == false {
            continueButton.isEnabled = true
            continueButton.image = UIImage(named: "ContinueButton")
        }
        
        return true
    }

    @IBAction func login(_ sender: Any) {
        // 複数回押すときのことを考え、変数をリセット
        accountNotFound = nil
        passwordCheck = nil
        
        // タイマースタート
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        
        // データベースから名前とパスワードを取得し終えたら
        fetchNameAndPassword(id: inputID!, completion: {
            // 取得したパスワードと入力したパスワードが一致したとき
            if self.fetchedPassword == self.inputPassword {
                self.passwordCheck = true
            } else {
                self.passwordCheck = false
            }
        })
    }
    
    @objc func update() {
        print("update")
        
        // データベースと通信できなかったとき
        if accountNotFound == true {
            // タイマーを止める
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            let dialog = UIAlertController(title: "ログイン失敗", message: "通信環境が悪いか、varmeets IDが違います。\nアカウントが見つかりません。", preferredStyle: .alert)
            // もう一度挑戦ボタン
            dialog.addAction(UIAlertAction(title: "もう一度挑戦", style: .default, handler: nil))
            // ダイアログを表示
            self.present(dialog, animated: true, completion: nil)
        }
        
        else if passwordCheck != nil {
            // タイマーを止める
            if let workingTimer = timer {
                workingTimer.invalidate()
            }
            
            // ログイン成功
            if passwordCheck == true {
                // グローバル変数にIDと名前を代入
                myID = idTextField.text!
                myName = fetchedName
                
                userDefaults.set(idTextField.text!, forKey: "myID")
                userDefaults.set(fetchedName, forKey: "myName")
                
                // ログイン画面をとじてホーム画面へ
                self.dismiss(animated: true, completion: nil)
            }
            
            // ログイン失敗
            else {
                let dialog = UIAlertController(title: "ログイン失敗", message: "パスワードが違います。", preferredStyle: .alert)
                // もう一度挑戦ボタン
                dialog.addAction(UIAlertAction(title: "もう一度挑戦", style: .default, handler: nil))
                // ダイアログを表示
                self.present(dialog, animated: true, completion: nil)
            }
        }
    }
    
    func fetchNameAndPassword(id: String, completion: @escaping () -> ()) {
        
        let recordID = CKRecord.ID(recordName: "accountID-\(id)")
        
        publicDatabase.fetch(withRecordID: recordID, completionHandler: {(record, error) in
            
            if let error = error {
                print("名前とパスワード取得エラー: \(error)")
                self.accountNotFound = true
                return
            }
            
            if let name = record?.value(forKey: "accountName") as? String {
                self.fetchedName = name
            }
            
            if let password = record?.value(forKey: "password") as? String {
                self.fetchedPassword = password
            }
            
            completion()
        })
    }
    
}
