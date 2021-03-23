//
//  TableViewController.swift
//  YandexMap
//
//  Created by Сергей Шабельник on 22.03.2021.
//

import UIKit
import YandexMapsMobile

class TableViewController: UITableViewController {
    
    // MARK: - Properties
    var fields: [Field]? = []
    
    var delegate: ViewControllerDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        getFields()
    }
    
    // MARK: - LocalDataManager
    func getFields() {
        LocalDataManager.shared.getAllPolygons(completion: { (response) in
            switch response {
            case .failure(let error):
                print(error)
            case .success(let data):
                self.fields = data
                self.tableView.reloadData()
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fields?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        guard let field = fields?[indexPath.row] else { return cell }
        cell.textLabel?.text = field.name
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            LocalDataManager.shared.deletePolygonById(id: fields![indexPath.row].id)
            fields?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            delegate.reloadMapObjects()
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate.moveCameraTo(field: fields![indexPath.row])
        delegate.highLightField(field: fields![indexPath.row])
        dismiss(animated: true, completion: nil)
    }
}
