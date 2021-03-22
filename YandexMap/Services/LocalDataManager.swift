//
//  LocalDataManager.swift
//  YandexMap
//
//  Created by Сергей Шабельник on 22.03.2021.
//

import Foundation
import CoreData
import YandexMapsMobile

class LocalDataManager {
    public static let shared = LocalDataManager()
    
    func savePolygon(id: String, name: String, points: [[Double]]) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let userEntity = NSEntityDescription.entity(forEntityName: "PolygonEntitie", in: managedContext)!
        
        let currentPolygon = NSManagedObject(entity: userEntity, insertInto: managedContext)
        currentPolygon.setValue(id, forKey: "id")
        currentPolygon.setValue(name, forKey: "name")
        currentPolygon.setValue(points, forKey: "points")
        
        do {
            try managedContext.save()
        }   catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func getAllPolygons(completion: @escaping (Result<[Field]?, Error>) -> () ) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let managedContext = appDelegate!.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PolygonEntitie")
        
        var fields: [Field]? = []
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            for object in result {
                let object = object as! NSManagedObject
                let id = object.value(forKey: "id") as! String
                let name = object.value(forKey: "name") as! String
                let points = object.value(forKey: "points") as! [[Double]]
                let field = Field(id: id, name: name, points: points)
                fields?.append(field)
                
            completion(.success(fields))
            }
        } catch let error{
            completion(.failure(error))
        }
    }
    
    func deletePolygonById(id: String) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let managedContext = appDelegate!.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PolygonEntitie")
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            for object in result {
                let object = object as! NSManagedObject
                if id == object.value(forKey: "id") as! String {
                    managedContext.delete(object)
                }
                try managedContext.save()
                
            }
        } catch let error{
            print(error)
        }
    }
}
