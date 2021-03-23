//
//  ViewController.swift
//  YandexMap
//
//  Created by Сергей Шабельник on 20.03.2021.
//

import UIKit
import YandexMapsMobile
import PresenterKit

protocol ViewControllerDelegate: AnyObject {
    func reloadMapObjects()
}

class ViewController: UIViewController, YMKMapInputListener, UIViewControllerTransitioningDelegate {
    
    @IBOutlet weak var mapView: YMKMapView!
    
    private var area: [YMKPoint] = []
    
    private var polygonMapObjectTapListener: YMKMapObjectTapListener!
    
    private var map: YMKMap {
        mapView.mapWindow.map
    }
    
    private var isReadyToEdit: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)

        self.map.addInputListener(with: self)
        
        self.getCurrentLocation()
        
        self.drawSavedPolygons()
    }
    
    // MARK: - IBActions
    @IBAction func addFieldButtonPressed(_ sender: Any) {
        setNavigationButtons()
    }
    
    func reloadMap() {
        map.mapObjects.clear()
        self.drawSavedPolygons()
    }
    
    @IBAction func listOfFieldsButtonPressed(_ sender: Any) {
        let viewController = TableViewController()
        viewController.delegate = self
        viewController.modalTransitionStyle = .coverVertical
        presentController(viewController, type: .custom(self), animated: true)
    }
    
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        HalfModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func setNavigationButtons() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightHandAction))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(leftHandAction))
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.isReadyToEdit = true
    }
    
    @objc
    func rightHandAction() {
        self.configureAlert { (name) in
            DispatchQueue.main.async {
                self.drawNewPolygon(name: name, with: self.area)
            }
        }
        self.isReadyToEdit = false
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    @objc
    func leftHandAction() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.isReadyToEdit = false
    }
    
    func configureAlert(completion: @escaping (String) -> ()) {
        let alert = UIAlertController(title: "Name", message: "Please input name of field", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "Save Field", style: .default) { (alertAction) in
            let textField = alert.textFields!.first! as UITextField
            completion(textField.text!)
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Name of field"
        }
        alert.addAction(action)
        self.present(alert, animated:true, completion: nil)
    }
    
    func drawSavedPolygons() {
        var fields: [Field] = []
        LocalDataManager.shared.getAllPolygons { (response) in
            switch response {
            case .failure(let error):
                print(error)
            case .success(let data):
                guard let data = data else { return }
                fields = data
            }
        }
        var points: [YMKPoint] = []
        for field in fields {
            let currentPoints = field.points
            for point in currentPoints{
                let currentPoint = YMKPoint(latitude: point[0], longitude: point[1])
                points.append(currentPoint)
                self.map.mapObjects.addPlacemark(with: currentPoint)
            }
            let polygon = YMKPolygon(outerRing: YMKLinearRing(points: points), innerRings: [])
            let polygonMapObject = map.mapObjects.addPolygon(with: polygon)
            polygonMapObject.fillColor = UIColor.green.withAlphaComponent(0.16)
            polygonMapObject.strokeWidth = 3.0
            polygonMapObject.strokeColor = .green
            polygonMapObject.isGeodesic = true
            points = []
        }
    }
    
    func drawNewPolygon(name: String, with points: [YMKPoint]) {
        let polygon = YMKPolygon(outerRing: YMKLinearRing(points: points), innerRings: [])
        let polygonMapObject = map.mapObjects.addPolygon(with: polygon)
        polygonMapObject.fillColor = UIColor.green.withAlphaComponent(0.16)
        polygonMapObject.strokeWidth = 3.0
        polygonMapObject.strokeColor = .green
        polygonMapObject.isGeodesic = true
        var arrayOfPoints: [[Double]] = []
        for point in points {
            arrayOfPoints.append([point.latitude, point.longitude])
        }
        let id = UUID().uuidString
        polygonMapObject.userData = Field(id: id, name: name, points: arrayOfPoints)
        LocalDataManager.shared.savePolygon(id: id, name: name, points: arrayOfPoints)
        self.area = []
    }
    
    func onMapTap(with map: YMKMap, point: YMKPoint) {
        if self.isReadyToEdit {
            self.map.mapObjects.addPlacemark(with: point)
            self.area.append(point)
        }
    }
    
    func deletePolygon(with id: String) {
    }
    
    func onMapLongTap(with map: YMKMap, point: YMKPoint) {
    }
}

extension ViewController: YMKUserLocationObjectListener {
    
    func getCurrentLocation() {
        self.map.isRotateGesturesEnabled = true
        self.map.move(with:
            YMKCameraPosition(target: YMKPoint(latitude: 0, longitude: 0), zoom: 14, azimuth: 0, tilt: 0))

        let scale = UIScreen.main.scale
        let mapKit = YMKMapKit.sharedInstance()
        let userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)

        userLocationLayer.setVisibleWithOn(true)
        userLocationLayer.isHeadingEnabled = false
        userLocationLayer.setAnchorWithAnchorNormal(
            CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.5 * mapView.frame.size.height * scale),
            anchorCourse: CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.83 * mapView.frame.size.height * scale))
        userLocationLayer.setObjectListenerWith(self)
    }
    
    func onObjectAdded(with view: YMKUserLocationView) {
        
    }
    
    func onObjectRemoved(with view: YMKUserLocationView) {
        
    }
    
    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {
        
    }
}

extension ViewController: ViewControllerDelegate {
    func reloadMapObjects() {
        self.reloadMap()
    }
}
