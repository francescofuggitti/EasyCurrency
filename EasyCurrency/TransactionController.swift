//
//  TransactionController.swift
//  EasyCurrency
//
//  Created by Francesco Fuggitti on 02/01/2018.
//  Copyright © 2018 Francesco Fuggitti. All rights reserved.
//

import UIKit

class TransactionController: UIViewController {
    
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var currencyField: UITextField!
    
    var pickerView = UIPickerView()
    var pickOption = ["AUD", "BNG", "BRL", "CAD", "CHF", "CNY", "CZK", "DKK", "EUR", "GBP", "HKD", "HRK", "HUF", "IDR", "ILS", "INR", "JPY", "KRW", "MXN", "MYR", "NOK", "NZD", "PHP", "PLN", "RON", "RUB", "SEK", "SGD", "THB", "TRY", "USD", "ZAR"]
    
    var user_id = Int()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let defaults = UserDefaults.standard
        if let user_id = defaults.string(forKey: "user_id"){
            self.user_id = Int(user_id)!
        }
        
        pickerView.delegate = self
        pickerView.dataSource = self
        currencyField.inputView = pickerView
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveTransaction(_ sender: UIBarButtonItem) {
        
        var rat = Double(1)
        
        func getRates(selCurrencyFrom: String, selCurrencyTo: String, completion: @escaping (Double)->()){
            let url = URL(string: "https://api.fixer.io/latest?base="+selCurrencyFrom+"&symbols="+selCurrencyTo)
            let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
                if error != nil {
                    print("HTTP request error")
                }
                else{
                    do{
                        let json = try JSONSerialization.jsonObject(with: data!)
                        if let dictResponse = json as? [String:Any] {
                            if let currencies = dictResponse["rates"] as? [String:Any]{
                                if currencies[selCurrencyTo] != nil {
                                    rat = (currencies[selCurrencyTo] as? Double)!
                                }
                                else{
                                    print("Rate not present")                                    
                                }
                            }
                        }
                    }catch {
                        print("Error parsing Json")
                    }
                }
                completion(rat)
            }
            task.resume()
        }
        
        if self.amountField.text != "" {
//            prendo il deposito e lo confronto
            let amountTyped = Double(self.amountField.text!)!
            let chosenCurrency = self.currencyField.text!
            self.getDeposit(completion: { (deposit) in
                if amountTyped > deposit {
                    let alertController = UIAlertController(title: "ERROR", message: "The amount is greater than your deposit!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler:nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                else{
                    getRates(selCurrencyFrom: "EUR", selCurrencyTo: chosenCurrency){ rate in
                        let trans = Transaction(id: "", amount: amountTyped, currency: chosenCurrency, rate: rate, user: self.user_id)
                        let diffDepAmount = deposit - amountTyped
                        trans.saveTrans(diffDepAmount: diffDepAmount)
                        defaults.set(diffDepAmount, forKey: "deposit")
                        transactions.append(trans)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            })
        }
        else{
            let alertController = UIAlertController(title: "ERROR", message: "Insert a value in the amount field", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler:nil))
            present(alertController, animated: true, completion: nil)
        }
        

    }
    
    func getDeposit (completion: @escaping (Double)->()){
        var deposit = 0.0
        
        let url = URL(string: "http://francesco1735212.ddns.net:3000/server_app_mob/get_dep_bal.php?user_id="+String(self.user_id))
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print("HTTP request error")
            }
            else{
                do{
                    let json = try JSONSerialization.jsonObject(with: data!)
                    if let dictResponse = json as? [String:Any] {
                        if let state = dictResponse["state"] as? String{
                            if state == "SUCCESS"{
                                let _deposit = dictResponse["deposit"] as? String
                                deposit = Double(_deposit!)!
                            }
                            else{
                                let cause = dictResponse["cause"] as? String
                                print(cause!)
                            }
                        }
                    }
                }catch {
                    print("Error parsing Json")
                }
            }
            completion(deposit)
        }
        task.resume()
    }
    
    @IBAction func undoTransaction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension TransactionController: UIPickerViewDelegate, UIPickerViewDataSource{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickOption.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickOption[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currencyField.text = pickOption[row]
    }
}
