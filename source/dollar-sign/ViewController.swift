//
//  ViewController.swift
//  dollar-sign
//
//  Created by MACKINTOSH on 2019/11/28.
//  Copyright © 2019年 MACKINTOSH. All rights reserved.
//

import UIKit
import AudioToolbox

struct Item: Codable {
    var index: Int
    var desc: String
    var cost: String
}

struct Record: Codable {
    var index: Int
    var date: String
    var items: [Item]
    var is_expanded: Bool
    
    func getCostPerDay() -> String {
        var sum = 0
        for item in self.items {
            sum += Int(item.cost)!
        }
        
        return String(sum)
    }
}

extension UITextField {
    func setupForSearch(_ placeholder: String) {
        self.placeholder = placeholder
        self.borderStyle = UITextField.BorderStyle.line
        self.font = self.font?.withSize(20)
        self.textAlignment = .center
        self.adjustsFontSizeToFitWidth = true
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var total_cost: UILabel!
    
    @IBOutlet weak var table_view: UITableView!
    
    @IBOutlet weak var show_search_view_btn: UIButton!
   
    var records = [Record]()
    var filtered_records = [Record]()
    
    let formatter = DateFormatter()
    
    var search_view = UIView()
    let picker = UIDatePicker()
    var from_date_tf = UITextField()
    var to_date_tf = UITextField()
    var min_cost_tf = UITextField()
    var max_cost_tf = UITextField()
    var desc_tf = UITextField()
    var search_btn = UIButton()
    
    var is_searching: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // self.saveRecords()
        
        // load data
        self.loadRecords() // load records from storage
        
        // setup formatter
        self.formatter.dateFormat = "yyyy/MM/dd"
        
        /*
        insertRecord("666", "2019/11/30", "123")
        insertRecord("777", "2019/11/29", "456")
        insertRecord("777", "2019/11/29", "456")
        insertRecord("777", "2019/11/29", "456")
        insertRecord("888", "2019/11/30", "789")
        insertRecord("777", "2019/12/01", "456")
        insertRecord("777", "2019/12/02", "456")
        insertRecord("777", "2019/12/03", "456")
        */
        
        // setup table view
        self.table_view.dataSource = self
        self.table_view.delegate = self
        self.table_view.tableFooterView = UIView()
        
        //
        self.setupForSearch()
        
        // setup records & refresh page
        self.filterRecords()
        self.refresh()
    }
    
    func filterRecords () {
        self.filtered_records = self.records
        
        // filter from date
        var offset_of_records = 0
        if let from_date = formatter.date(from: self.from_date_tf.text!) {
            for (index, record) in self.filtered_records.enumerated() {
                if from_date > formatter.date(from: record.date)! {
                    self.filtered_records.remove(at: index - offset_of_records)
                    offset_of_records += 1
                }
            }
        }
    
        // filter to date
        offset_of_records = 0
        if let to_date = formatter.date(from: self.to_date_tf.text!) {
            for (index, record) in self.filtered_records.enumerated() {
                if to_date < formatter.date(from: record.date)! {
                    self.filtered_records.remove(at: index - offset_of_records)
                    offset_of_records += 1
                }
            }
        }
    
        // filter min cost
        offset_of_records = 0
        var offset_of_items = 0
        if let min_cost = Int(self.min_cost_tf.text!) {
            for (section, record) in self.filtered_records.enumerated() {
                offset_of_items = 0
                for (row, item) in record.items.enumerated() {
                    if min_cost > Int(item.cost)! {
                        if self.filtered_records[section - offset_of_records].items.count == 1 {
                            self.filtered_records.remove(at: section - offset_of_records)
                            offset_of_records += 1
                        }
                        else {
                            self.filtered_records[section - offset_of_records].items.remove(at: row - offset_of_items)
                            offset_of_items += 1
                        }
                    }
                }
            }
        }
    
        // filter max cost
        offset_of_records = 0
        offset_of_items = 0
        if let max_cost = Int(self.max_cost_tf.text!) {
            for (section, record) in self.filtered_records.enumerated() {
                offset_of_items = 0
                for (row, item) in record.items.enumerated() {
                    if max_cost < Int(item.cost)! {
                        if self.filtered_records[section - offset_of_records].items.count == 1 {
                            self.filtered_records.remove(at: section - offset_of_records)
                            offset_of_records += 1
                        }
                        else {
                            self.filtered_records[section - offset_of_records].items.remove(at: row - offset_of_items)
                            offset_of_items += 1
                        }
                    }
                }
            }
        }
    
        // filter description
        offset_of_records = 0
        offset_of_items = 0
        if let desc = self.desc_tf.text, !desc.isEmpty {
            for (section, record) in self.filtered_records.enumerated() {
                offset_of_items = 0
                for (row, item) in record.items.enumerated() {
                    if !item.desc.contains(desc) {
                        if self.filtered_records[section - offset_of_records].items.count == 1 {
                            self.filtered_records.remove(at: section - offset_of_records)
                            offset_of_records += 1
                        }
                        else {
                            self.filtered_records[section - offset_of_records].items.remove(at: row - offset_of_items)
                            offset_of_items += 1
                        }
                    }
                }
            }
        }
    }
    
    func refresh() {
        self.table_view.reloadData()
        self.countTotal()
    }
    
    func countTotal() {
        var sum = 0
        for record in self.filtered_records {
            sum += Int(record.getCostPerDay())!
        }
        
        self.total_cost.text = "$" + String(sum)
    }

    @IBAction func onClickShowSearchViewButton(_ sender: Any) {
        if !self.is_searching {
            self.showSearchView()
        }
        else {
            self.hideSearchView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { // for editing
        if let default_value = sender as? [String:String] {
            let controller = segue.destination as! NewRecordViewController
            controller.edit_mode_param = default_value
        }
        
        if self.is_searching {
            self.hideSearchView()
        }
 
    }
    
    var index_path_for_IE = IndexPath()

    @IBAction func unwindBackToMain(segue: UIStoryboardSegue) {
        let source = segue.source as? NewRecordViewController
        if !(source?.edit_mode_param.isEmpty)! { // edit mode
            let section: Int = Int((source?.edit_mode_param["section"]!)!)!
            let row: Int = Int((source?.edit_mode_param["row"]!)!)!
            self.changeRecord((source?.desc_TF.text)!, (source?.cost_TF.text)!,
                              self.filtered_records[section].index, self.filtered_records[section].items[row - 1].index)
            
            self.filterRecords()
            self.index_path_for_IE = IndexPath(row: row, section: section)
        }
        else {
            insertRecord((source?.cost_TF.text)!, (source?.date_TF.text)!, (source?.desc_TF.text)!)
            
            if let date = formatter.date(from: (source?.date_TF.text)!) { // expand date range to contain new date
                if let from_date = formatter.date(from: self.from_date_tf.text!) {
                    if from_date > date {
                        self.from_date_tf.text = formatter.string(from: date)
                    }
                }
                
                if let to_date = formatter.date(from: self.to_date_tf.text!) {
                    if to_date < date {
                        self.to_date_tf.text = formatter.string(from: date)
                    }
                }
            }
            
            if let cost = Int((source?.cost_TF.text!)!) { // expand cost range to contain new cost
                if let min_cost = Int(self.min_cost_tf.text!) {
                    if min_cost > cost {
                        self.min_cost_tf.text = String(cost)
                    }
                }
                
                if let max_cost = Int(self.max_cost_tf.text!) {
                    if max_cost < cost {
                        self.max_cost_tf.text = String(cost)
                    }
                }
            }
            
            self.filterRecords()
            let section = self.getSectionOfDate((source?.date_TF.text)!)
            let row = self.filtered_records[section].items.count
            self.index_path_for_IE = IndexPath(row: row, section: section)
        }
        
        self.saveRecords()
        self.refresh()
        self.table_view.scrollToRow(at: self.index_path_for_IE, at: .middle, animated: true)
    }
}

// --------------------------- record operations --------------------------- //
extension ViewController {
    func insertRecord(_ cost: String, _ date: String, _ desc: String) {
        var index = 0
        var is_inserted = false
        while index < self.records.count {
            if date == self.records[index].date { // date already existed
                self.records[index].items.append(Item(index: self.records[index].items.count, desc: desc, cost: cost))
                is_inserted = true
                
                print("appended record no.\(self.records[index].index) item no.\(self.records[index].items.count - 1): " +
                      "with cost: \(cost), date: \(date), desc: \(desc)")
            }
            
            index += 1
        }
        
        if !is_inserted { // insert new record
            let item = Item(index: 0, desc: desc, cost: cost)
            self.records.append(Record(index: self.records.count, date: date, items: [item], is_expanded: true))
            
            self.records = self.records.sorted(by: {
                self.formatter.date(from: $0.date)!.compare(self.formatter.date(from: $1.date)!) == .orderedAscending
            })
            
            print("inserted record no.\(self.records.count - 1): with cost: \(cost), date: \(date), desc: \(desc)")
        }
    }
    
    func changeRecord(_ desc: String, _ cost: String, _ index_of_section: Int, _ index_of_row: Int) {
        let section = self.records.firstIndex(where: {$0.index == index_of_section})!
        let row = self.records[section].items.firstIndex(where: {$0.index == index_of_row})!
        
        self.records[section].items[row].desc = desc
        self.records[section].items[row].cost = cost
        
        let date = self.records[section].date
        print("changed record with desc: \(desc), cost: \(cost) on \(date)")
    }
    
    func removeRecord(index_of_section: Int, index_of_row: Int) {
        let section = self.records.firstIndex(where: {$0.index == index_of_section})!
        
        if index_of_row == -1 { // remove section
            self.records.remove(at: section)
        }
        else { // remove row
            let row = self.records[section].items.firstIndex(where: {$0.index == index_of_row})!
            self.records[section].items.remove(at: row)
        }
    }
    
    func getSectionOfDate(_ date: String) -> Int { // get the section number from filtered records
        for (index, record) in self.filtered_records.enumerated() {
            if date == record.date {
                return index
            }
        }
        
        return -1
    }
    
    func loadRecords() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.object(forKey: "records") as? Data {
            if let records = try? decoder.decode([Record].self, from: data) {
                self.records = records
            }
        }
    }
    
    func saveRecords() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self.records) {
            UserDefaults.standard.set(data, forKey: "records")
        }
    }
    
}

// --------------------------- table view operations --------------------------- //
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if is_searching { // hide records while searching
            return 0
        }
        else {
            return self.filtered_records.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.filtered_records[section].is_expanded {
            return self.filtered_records[section].items.count + 1
        }
        else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Title", for: indexPath) as! TableViewCell
            cell.date.text = self.filtered_records[indexPath.section].date
            if self.filtered_records[indexPath.section].is_expanded {
                cell.show_hide_btn.setImage(UIImage(named: "collapse"), for: .normal)
                cell.cost_per_day.text = ""
            }
            else {
                cell.show_hide_btn.setImage(UIImage(named: "expand"), for: .normal)
                cell.cost_per_day.text = "$" + self.filtered_records[indexPath.section].getCostPerDay()
                
            }
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! TableViewCell
            cell.desc.text = self.filtered_records[indexPath.section].items[indexPath.row - 1].desc
            cell.cost.text = "$" + self.filtered_records[indexPath.section].items[indexPath.row - 1].cost
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if self.filtered_records[indexPath.section].is_expanded {
                AudioServicesPlaySystemSound(1100)
            }
        
            self.filtered_records[indexPath.section].is_expanded = !self.filtered_records[indexPath.section].is_expanded
            let indexes = IndexSet(integer: indexPath.section)
            tableView.beginUpdates()
            tableView.reloadSections(indexes, with: .automatic)
            tableView.endUpdates()
        }
        else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete", handler: { (action, indexPath) in
            if indexPath.row == 0 || self.filtered_records[indexPath.section].items.count == 1 {
                // at whole section OR section remain only 1 row
                self.removeRecord(index_of_section: self.filtered_records[indexPath.section].index, index_of_row: -1)
                self.filtered_records.remove(at: indexPath.section)
                
                let indexes = IndexSet(integer: indexPath.section)
                tableView.beginUpdates()
                tableView.deleteSections(indexes, with: .fade)
                tableView.endUpdates()
            }
            else {
                self.removeRecord(index_of_section: self.filtered_records[indexPath.section].index,
                                  index_of_row: self.filtered_records[indexPath.section].items[indexPath.row - 1].index)
                self.filtered_records[indexPath.section].items.remove(at: indexPath.row - 1)
                
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }
            
            self.saveRecords()
            self.countTotal()
        })
        
        if indexPath.row == 0 {
            return [delete]
        }
        else {
            let edit = UITableViewRowAction(style: .normal, title: "Edit", handler: { (action, indexPath) in
                var sender = [String:String]()
                sender["cost"] = self.filtered_records[indexPath.section].items[indexPath.row - 1].cost
                sender["date"] = self.filtered_records[indexPath.section].date
                sender["desc"] = self.filtered_records[indexPath.section].items[indexPath.row - 1].desc
                sender["section"] = String(indexPath.section)
                sender["row"] = String(indexPath.row)
                
                self.performSegue(withIdentifier: "GoToNewRecord", sender: sender)
            })
            
            return [delete, edit]
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !self.index_path_for_IE.isEmpty { // IE => Insertion or Edition
            if indexPath.section == self.index_path_for_IE.section && indexPath.row == self.index_path_for_IE.row {
                self.table_view.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
    
                UIView.animate(withDuration: 2, animations: {
                    cell.alpha = 0
                    cell.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
                    cell.alpha = 1
                    cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                })
                
                self.table_view.deselectRow(at: indexPath, animated: true)
                
                self.index_path_for_IE = IndexPath()
            }
        }
    }
    
    
}

// --------------------------- searching operations --------------------------- //
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @objc func onClickDoneButton() {
        if self.from_date_tf.isFirstResponder || self.to_date_tf.isFirstResponder {
            changeDate()
        }
        
        self.view.endEditing(true)
    }
    
    @objc func changeDate() {
        if self.from_date_tf.isFirstResponder {
            self.from_date_tf.text = self.formatter.string(from: picker.date)
        }
        else { // to date
            self.to_date_tf.text = self.formatter.string(from: picker.date)
        }
    }
    
    func setupForSearch() {
        // setup search view
        self.search_view = UIView(frame: CGRect(x: 0, y: 80, width: 375, height: 190))
        self.search_view.backgroundColor = #colorLiteral(red: 0.8829190422, green: 0.8829190422, blue: 0.8829190422, alpha: 1)
        
        // setup text fields
        self.from_date_tf = UITextField(frame: CGRect(x: 16, y: 10, width: 158, height: 30))
        self.to_date_tf = UITextField(frame: CGRect(x: 201, y: 10, width: 158, height: 30))
        self.min_cost_tf = UITextField(frame: CGRect(x: 16, y: 50, width: 158, height: 30))
        self.max_cost_tf = UITextField(frame: CGRect(x: 201, y: 50, width: 158, height: 30))
        self.desc_tf = UITextField(frame: CGRect(x: 16, y: 90, width: 275, height: 30))
        
        self.from_date_tf.setupForSearch("from")
        self.to_date_tf.setupForSearch("to")
        self.min_cost_tf.setupForSearch("min")
        self.max_cost_tf.setupForSearch("max")
        self.desc_tf.setupForSearch("description")
        
        self.from_date_tf.delegate = self
        self.to_date_tf.delegate = self
        self.min_cost_tf.delegate = self
        self.max_cost_tf.delegate = self
        self.desc_tf.delegate = self
        
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
        
        // setup keyboard of text fields
        self.from_date_tf.inputView = picker
        self.from_date_tf.inputAccessoryView = toolbar
        self.to_date_tf.inputView = picker
        self.to_date_tf.inputAccessoryView = toolbar
        self.min_cost_tf.keyboardType = UIKeyboardType.numberPad
        self.min_cost_tf.inputAccessoryView = toolbar
        self.max_cost_tf.keyboardType = UIKeyboardType.numberPad
        self.max_cost_tf.inputAccessoryView = toolbar
        
        // setup separator
        let sep_for_date = UILabel(frame: CGRect(x: 174, y: 10, width: 27, height: 30))
        sep_for_date.font = sep_for_date.font.withSize(30)
        sep_for_date.text = "-"
        sep_for_date.textAlignment = .center
        let sep_for_cost = UILabel(frame: CGRect(x: 174, y: 50, width: 27, height: 30))
        sep_for_cost.font = sep_for_cost.font.withSize(30)
        sep_for_cost.text = "-"
        sep_for_cost.textAlignment = .center
        
        // setup search button
        self.search_btn = UIButton(frame: CGRect(x: 0, y: 130, width: 375, height: 60))
        self.search_btn.backgroundColor = #colorLiteral(red: 0.2941176471, green: 0.5058823529, blue: 0.5490196078, alpha: 1)
        // search_btn.setImage(UIImage(named: "search_flipped"), for: .normal)
        self.search_btn.setTitle("Search", for: .normal)
        self.search_btn.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        self.search_btn.titleLabel?.font = .systemFont(ofSize: 40)
        // search_btn.imageEdgeInsets.left = 250
        // search_btn.titleEdgeInsets.right = 60
        self.search_btn.addTarget(self, action: #selector(self.search), for: .touchUpInside)
        
        // setup clear button
        let clear_btn = UIButton(frame: CGRect(x: 298, y: 90, width: 61, height: 30))
        clear_btn.backgroundColor = #colorLiteral(red: 0.8829190422, green: 0.8829190422, blue: 0.8829190422, alpha: 1)
        // clear_btn.setImage(UIImage(named: "search_flipped"), for: .normal)
        clear_btn.setTitle("Clear", for: .normal)
        clear_btn.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        clear_btn.titleLabel?.font = .systemFont(ofSize: 25)
        clear_btn.addTarget(self, action: #selector(self.onClickClearButton), for: .touchUpInside)
        
        // add subviews
        self.search_view.addSubview(self.from_date_tf)
        self.search_view.addSubview(self.to_date_tf)
        self.search_view.addSubview(self.min_cost_tf)
        self.search_view.addSubview(self.max_cost_tf)
        self.search_view.addSubview(self.desc_tf)
        self.search_view.addSubview(sep_for_date)
        self.search_view.addSubview(sep_for_cost)
        self.search_view.addSubview(self.search_btn)
        self.search_view.addSubview(clear_btn)
    }
    
    @objc func onClickClearButton() {
        self.from_date_tf.text = ""
        self.to_date_tf.text = ""
        self.min_cost_tf.text = ""
        self.max_cost_tf.text = ""
        self.desc_tf.text = ""
    }
    
    func showSearchView() {
        self.is_searching = true
        
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.view.addSubview(self.search_view)
        }, completion: nil)
        
        self.table_view.reloadData() // to hide records
        self.total_cost.text = "$0"
    }
    
    func hideSearchView() {
        self.is_searching = false
        
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.search_view.removeFromSuperview()
        }, completion: nil)
        
        self.table_view.reloadData() // to show records
        self.countTotal()
    }
    
    @objc func search() {
        if validateInput() {
            self.hideSearchView()
            self.filterRecords()
            self.refresh()
        }
        else {
            self.showMsg(" INVALID INPUT ")
        }
    }
    
    func validateInput() -> Bool {
        do {
            let from_date = self.from_date_tf.text!
            let to_date = self.to_date_tf.text!
            let min_cost = self.min_cost_tf.text!
            let max_cost = self.max_cost_tf.text!
            
            if !from_date.isEmpty && formatter.date(from: from_date) == nil {
                return false
            }
            else if !to_date.isEmpty && formatter.date(from: to_date) == nil {
                return false
            }
            else {
                if !from_date.isEmpty && !to_date.isEmpty {
                    if let from_date = formatter.date(from: from_date),
                       let to_date = formatter.date(from: to_date) {
                        if from_date > to_date {
                            return false
                        }
                    }
                }
            }
            
            let regex = try NSRegularExpression(pattern: "^[0-9]*$", options: [])

            if !min_cost.isEmpty &&
               regex.firstMatch(in: min_cost, options: [], range: NSRange(location: 0, length: min_cost.utf16.count)) == nil {
                return false
            }
            else if !max_cost.isEmpty &&
               regex.firstMatch(in: max_cost, options: [], range: NSRange(location: 0, length: max_cost.utf16.count)) == nil {
                return false
            }
            else {
                if !min_cost.isEmpty && !max_cost.isEmpty {
                    if let min_cost = Int(min_cost),
                       let max_cost = Int(max_cost) {
                        if min_cost > max_cost {
                            return false
                        }
                    }
                }
            }
        
            return true
        }
        catch {
            print("ERROR")
            return false
        }
    }
    
    func showMsg(_ msg: String) {
        AudioServicesPlaySystemSound(1006)
        
        self.search_btn.titleLabel?.alpha = 0
        
        let label = UILabel(frame: CGRect(x: 0, y: 130, width: 375, height: 60))
        label.text = msg
        label.layer.borderWidth = 3
        label.layer.cornerRadius = 5
        label.textColor = UIColor.red
        label.layer.borderColor = UIColor.red.cgColor
        label.font = label.font.withSize(40)
        label.sizeToFit()
        label.center.x = self.view.center.x
        label.center.y = self.search_btn.center.y
        
        self.search_view.addSubview(label)
        
        UIView.animate(withDuration: 2, delay: 0, options: [.beginFromCurrentState], animations: {
            label.alpha = 0
        }, completion: {_ in
            label.removeFromSuperview()
            self.search_btn.titleLabel?.alpha = 1
        })
    }
}
