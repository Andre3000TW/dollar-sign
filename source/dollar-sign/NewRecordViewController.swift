//
//  ViewController.swift
//  dollar-sign
//
//  Created by MACKINTOSH on 2019/11/28.
//  Copyright © 2019年 MACKINTOSH. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

struct Barcode: Codable {
    var barcode: String
    var item: Item
    
    func getBarcode() -> String {
        return self.barcode
    }
    
    func getItem() -> Item {
        return self.item
    }
}

extension UITextField {
    func addButtons() {
        let up_btn = UIButton(type: .custom)
        let down_btn = UIButton(type: .custom)
        up_btn.setImage(UIImage(named: "up"), for: .normal)
        down_btn.setImage(UIImage(named: "down"), for: .normal)
        up_btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        down_btn.frame = CGRect(x: 0, y: 30, width: 30, height: 30)
        up_btn.addTarget(self, action: #selector(goUp), for: .touchUpInside)
        down_btn.addTarget(self, action: #selector(goDown), for: .touchUpInside)
        
        let btn_view = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        btn_view.addSubview(up_btn)
        btn_view.addSubview(down_btn)
        
        self.leftView = btn_view
        self.leftViewMode = .always
    }
    
    @objc func goUp() {
        if (self.text?.isEmpty)! {
            self.text = "$0"
        }
        else {
            let str = self.text!
            let int_text = Int(String(str.suffix(str.count - 1)))!
            self.text = "$" + String(int_text + 1)
        }
        
        AudioServicesPlaySystemSound(1104)
    }
    
    @objc func goDown() {
        if (self.text?.isEmpty)! || self.text == "$0" {
            self.text = "$0"
        }
        else {
            let str = self.text!
            let int_text = Int(String(str.suffix(str.count - 1)))!
            self.text = "$" + String(int_text - 1)
        }
        
        AudioServicesPlaySystemSound(1104)
    }

    func addPadding() {
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 60))
        self.rightView = padding
        self.rightViewMode = .always
    }
}

class NewRecordViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var dismiss_btn: UIButton!
    @IBOutlet weak var confirm_btn: UIButton!
    
    @IBOutlet weak var zero_btn: UIButton!
    @IBOutlet weak var one_btn: UIButton!
    @IBOutlet weak var two_btn: UIButton!
    @IBOutlet weak var three_btn: UIButton!
    @IBOutlet weak var four_btn: UIButton!
    @IBOutlet weak var five_btn: UIButton!
    @IBOutlet weak var six_btn: UIButton!
    @IBOutlet weak var seven_btn: UIButton!
    @IBOutlet weak var eight_btn: UIButton!
    @IBOutlet weak var nine_btn: UIButton!
    @IBOutlet weak var barcode_btn: UIButton!
    @IBOutlet weak var backspace_btn: UIButton!
    
    @IBOutlet weak var cost_TF: UITextField!
    @IBOutlet weak var date_TF: UITextField!
    @IBOutlet weak var desc_TF: UITextField!
    
    @IBOutlet weak var msg: UILabel!
    @IBOutlet weak var view_title: UILabel!
    
    var edit_mode_param = [String:String]()
    
    let picker = UIDatePicker()
    let session = AVCaptureSession()
    var video = AVCaptureVideoPreviewLayer()
    var video_view = UIView()
    var is_button_enable = true
    
    var barcode = String()
    var barcodes = [Barcode]()
    
    func setupEditMode() {
        if !edit_mode_param.isEmpty {
            self.cost_TF.text = "$" + self.edit_mode_param["cost"]!
            self.date_TF.text = self.edit_mode_param["date"]
            self.desc_TF.text = self.edit_mode_param["desc"]
            
            self.date_TF.textColor = UIColor.gray
            self.date_TF.isUserInteractionEnabled = false
            
            self.view_title.text = "Edit Record"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // self.saveBarcodes()
        
        // load barcodes
        self.loadBarcodes()
        
        // setup msg
        self.msg.alpha = 0
        self.msg.layer.borderWidth = 3
        self.msg.layer.cornerRadius = 5
        
        // setup text fields
        self.cost_TF.addButtons()
        self.cost_TF.addPadding()
        self.date_TF.addPadding()
        self.desc_TF.addPadding()
        self.cost_TF.delegate = self
        self.date_TF.delegate = self
        self.desc_TF.delegate = self
        
        // setup datepicker
        picker.datePickerMode = .date
        picker.locale = Locale(identifier: "zh_TW")
        picker.addTarget(self, action: #selector(changeDate), for: .valueChanged)
        
        // setup toolbar
        let toolbar = UIToolbar()
        let done = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(onClickDoneButton))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([space, done], animated: true)
        toolbar.sizeToFit()
        
        // attach datepicker & toolbar
        self.cost_TF.inputView = UIView()
        self.date_TF.inputView = picker
        self.date_TF.inputAccessoryView = toolbar
        
        // setup edit mode
        self.setupEditMode()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.session.isRunning {
            self.toggleButton()
            self.session.stopRunning()
            self.video_view.removeFromSuperview()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @objc func onClickDoneButton() {
        changeDate()
        self.view.endEditing(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.session.isRunning {
            self.toggleButton()
            self.session.stopRunning()
            self.video_view.removeFromSuperview()
        }
        
        self.view.endEditing(true)
    }
    
    @objc func changeDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        
        self.date_TF.text = formatter.string(from: picker.date)
    }
    
    @IBAction func onClickNumpad(_ sender: UIButton) {
        if self.is_button_enable {
            let max_len = 15
            
            if sender != backspace_btn { AudioServicesPlaySystemSound(1104) }
            else { AudioServicesPlaySystemSound(1155) }
            
            switch sender {
                case self.zero_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$0"
                        }
                        else {
                            self.cost_TF.text! += "0"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.one_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$1"
                        }
                        else {
                            self.cost_TF.text! += "1"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.two_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$2"
                        }
                        else {
                            self.cost_TF.text! += "2"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.three_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$3"
                        }
                        else {
                            self.cost_TF.text! += "3"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.four_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$4"
                        }
                        else {
                            self.cost_TF.text! += "4"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.five_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$5"
                        }
                        else {
                            self.cost_TF.text! += "5"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.six_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$6"
                        }
                        else {
                            self.cost_TF.text! += "6"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.seven_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$7"
                        }
                        else {
                            self.cost_TF.text! += "7"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.eight_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$8"
                        }
                        else {
                            self.cost_TF.text! += "8"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.nine_btn:
                    if self.cost_TF.text!.count < max_len {
                        if (self.cost_TF.text?.isEmpty)! || self.cost_TF.text == "$0" { // first time typing in
                            self.cost_TF.text = "$9"
                        }
                        else {
                            self.cost_TF.text! += "9"
                        }
                    }
                    else {
                        self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
                    }
                case self.barcode_btn:
                    UIView.animate(withDuration: 0.05, animations: {
                        self.barcode_btn.alpha = 0
                        self.barcode_btn.alpha = 1.0
                    })
                    
                    self.scan()
                    self.toggleButton()
                case self.backspace_btn:
                    UIView.animate(withDuration: 0.05, animations: {
                        self.backspace_btn.alpha = 0
                        self.backspace_btn.alpha = 1.0
                    })
                    
                    if self.cost_TF.text!.count <= 2 {
                        self.cost_TF.text = "$0"
                    }
                    else {
                        self.cost_TF.text?.removeLast()
                    }
                default: break
            }
        }
    }
    
    func toggleButton() {
        self.is_button_enable = !self.is_button_enable
    }
    
    func validateInput(_ cost: String, _ date: String, _ desc: String) -> Bool {
        if cost.isEmpty || date.isEmpty || desc.isEmpty { // one of them empty
            self.showMsg(type: "error", " ERROR: PLEASE FILL OUT EVERY FIELD ")
            return false
        }
        else if cost.count > 14 {
            self.showMsg(type: "error", " ERROR: EXCEED MAX LEN OF INPUT ")
            return false
        }
        else {
            do {
                let regex = try NSRegularExpression(pattern: "^\\$[0-9]*$", options: [])

                if regex.firstMatch(in: cost, options: [], range: NSRange(location: 0, length: cost.utf16.count)) == nil {
                    self.showMsg(type: "error", " INVALID INPUT OF COdollar-sign ")
                    return false
                }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd"
                
                if formatter.date(from: date) == nil {
                    self.showMsg(type: "error", " INVALID INPUT OF DATE ")
                    return false
                }
                
                self.cost_TF.text = String(cost.suffix(cost.count - 1))
                
                return true
            }
            catch {
                print("ERROR")
                return false
            }
        }
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if validateInput((self.cost_TF.text)!, (self.date_TF.text)!, (self.desc_TF.text)!) {
            if !self.barcode.isEmpty { // barcode is not empty => to be inserted OR to be changed
                if let item = self.getInfoFromBarcode(barcode) {
                    if self.cost_TF.text != item.cost || self.desc_TF.text != item.desc { // to be changed
                        self.changeBarcode(self.barcode, self.cost_TF.text!, self.desc_TF.text!)
                        self.saveBarcodes() // save barcodes to storage
                        
                        // change to the display format
                        self.cost_TF.text = "$" + self.cost_TF.text!
                        
                        let controller = UIAlertController(title: "dollar-signATUS", message: "BARCODE CHANGED SUCCESSFULLY", preferredStyle: .alert)
                    
                        let ok = UIAlertAction(title: "OK", style: .default) { (_) in
                            // change back to store format
                            self.cost_TF.text = String(self.cost_TF.text!.suffix(self.cost_TF.text!.count - 1))
                            self.performSegue(withIdentifier: "BackToMain", sender: sender)
                        }
                        
                        controller.addAction(ok)
                        self.present(controller, animated: true, completion: nil)
                        
                        return false
                    }
                    else {
                        return true
                    }
                }
                else { // to be inserted
                    self.insertBarcode(self.barcode, self.cost_TF.text!, self.desc_TF.text!)
                    self.saveBarcodes() // save barcodes to storage
                    
                    // change to the display format
                    self.cost_TF.text = "$" + self.cost_TF.text!
                    
                    let controller = UIAlertController(title: "dollar-signATUS", message: "BARCODE INSERTED SUCCESSFULLY", preferredStyle: .alert)
                
                    let ok = UIAlertAction(title: "OK", style: .default) { (_) in
                        // change back to store format
                        self.cost_TF.text = String(self.cost_TF.text!.suffix(self.cost_TF.text!.count - 1))
                        self.performSegue(withIdentifier: "BackToMain", sender: sender)
                    }
                    
                    controller.addAction(ok)
                    self.present(controller, animated: true, completion: nil)
                    
                    return false
                }
            }
            else {
                return true
            }
        }
        else {
            return false
        }
    }
    
    @IBAction func onClickDismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showMsg(type: String, _ msg: String) {
        self.msg.text = msg
        
        if type == "prompt" {
            self.msg.textColor = UIColor.blue
            self.msg.layer.borderColor = UIColor.blue.cgColor
            self.msg.backgroundColor = UIColor.blue.withAlphaComponent(0.2)
        }
        else { // error
            self.msg.textColor = UIColor.red
            self.msg.layer.borderColor = UIColor.red.cgColor
            self.msg.backgroundColor = UIColor.red.withAlphaComponent(0.2)
            AudioServicesPlaySystemSound(1006)
        }
        
        self.msg.sizeToFit()
        self.msg.center.x = self.view.center.x
        
        UIView.animate(withDuration: 5, animations: {
            self.msg.alpha = 1.0
            self.msg.alpha = 0
        })
    }
    
}

extension NewRecordViewController { // for barcode operations
    func getInfoFromBarcode(_ barcode: String) -> Item? {
        for bar in self.barcodes {
            if barcode == bar.getBarcode() {
                return bar.getItem()
            }
        }
        
        return nil
    }
    
    func insertBarcode(_ barcode: String, _ cost: String, _ desc: String) {
        let item = Item(index: 0, desc: desc, cost: cost)
        self.barcodes.append(Barcode(barcode: barcode, item: item))
        
        print("inserted barcode: \(barcode), with cost: \(cost), desc: \(desc)")
    }
    
    func changeBarcode(_ barcode: String, _ cost: String, _ desc: String) {
        let item = Item(index: 0, desc: desc, cost: cost)
        for (index, bar) in self.barcodes.enumerated() {
            if barcode == bar.getBarcode() {
                self.barcodes[index].item = item
            }
        }
        
        print("changed barcode: \(barcode), with cost: \(cost), desc: \(desc)")
    }
    
    func validateBarcode() {
        print("barcode: \(barcode)")
        
        if let item = self.getInfoFromBarcode(barcode) {
            self.showMsg(type: "prompt", " BARCODE SCANNED SUCCESSFULLY ")
            self.cost_TF.text = "$" + item.cost
            self.desc_TF.text = item.desc
        }
        else {
            self.showMsg(type: "error", " BARCODE UNDEFINED, INPUT MANUALLY ")
        }
    }
    
    func loadBarcodes() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.object(forKey: "barcodes") as? Data {
            if let barcodes = try? decoder.decode([Barcode].self, from: data) {
                self.barcodes = barcodes
            }
        }
    }
    
    func saveBarcodes() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self.barcodes) {
            UserDefaults.standard.set(data, forKey: "barcodes")
        }
    }
}

extension NewRecordViewController: AVCaptureMetadataOutputObjectsDelegate { // for barcode scanning
    func scan() {
        let capture_device = AVCaptureDevice.default(for: AVMediaType.video)
        
        if self.session.inputs.isEmpty {
            do {
                let input = try AVCaptureDeviceInput(device: capture_device!)
                self.session.addInput(input)
            }
            catch {
                print("ERROR")
            }
            
            let output = AVCaptureMetadataOutput()
            self.session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.code39,
                                          AVMetadataObject.ObjectType.code39Mod43, AVMetadataObject.ObjectType.code93,
                                          AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.ean8,
                                          AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.itf14,
                                          AVMetadataObject.ObjectType.interleaved2of5,
                                          AVMetadataObject.ObjectType.aztec, AVMetadataObject.ObjectType.pdf417,
                                          AVMetadataObject.ObjectType.dataMatrix, AVMetadataObject.ObjectType.qr]
        }
        
        self.video_view = UIView()
        self.video = AVCaptureVideoPreviewLayer(session: self.session)
        self.video.videoGravity = .resizeAspectFill
        self.video.frame = CGRect(x: 0, y: 409, width: 375, height: 258)
        self.video_view.layer.addSublayer(self.video)
        view.addSubview(self.video_view)
        
        self.session.startRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count != 0 {
            let metadata_obj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            switch metadata_obj.type {
                case AVMetadataObject.ObjectType.upce: fallthrough
                case AVMetadataObject.ObjectType.code39: fallthrough
                case AVMetadataObject.ObjectType.code39Mod43: fallthrough
                case AVMetadataObject.ObjectType.code93: fallthrough
                case AVMetadataObject.ObjectType.code128: fallthrough
                case AVMetadataObject.ObjectType.ean8: fallthrough
                case AVMetadataObject.ObjectType.ean13: fallthrough
                case AVMetadataObject.ObjectType.itf14: fallthrough
                case AVMetadataObject.ObjectType.interleaved2of5: fallthrough
                case AVMetadataObject.ObjectType.aztec: fallthrough
                case AVMetadataObject.ObjectType.pdf417: fallthrough
                case AVMetadataObject.ObjectType.dataMatrix: fallthrough
                case AVMetadataObject.ObjectType.qr:
                    if metadata_obj.stringValue != nil {
                        barcode = metadata_obj.stringValue!
                        self.toggleButton()
                        self.session.stopRunning()
                        self.video_view.removeFromSuperview()
                        AudioServicesPlaySystemSound(1108)
                        self.validateBarcode()
                    }
                default: break
            }
        }
        
    }
}
