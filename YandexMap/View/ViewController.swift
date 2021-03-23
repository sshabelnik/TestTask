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
    func moveCameraTo(field: Field)
    func highLightField(field: Field)
}

class ViewController: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet weak var mapView: YMKMapView!
    
    // MARK: - Properties
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
        self.setNavigationButtons()
    }
    
    @IBAction func listOfFieldsButtonPressed(_ sender: Any) {
        let viewController = TableViewController()
        viewController.delegate = self
        viewController.modalTransitionStyle = .coverVertical
        presentController(viewController, type: .custom(self), animated: true)
    }
    
    // MARK: - NavigationBar
    func setNavigationButtons() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightHandAction))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(leftHandAction))
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.isReadyToEdit = true
    }
    
    @objc
    func rightHandAction() {
        if area.count > 2 {
            self.configureAlert { (name) in
                self.drawNewPolygon(name: name, with: self.area)
            }
            self.isReadyToEdit = false
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        } else {
            let alert = UIAlertController(title: "Error", message: "You need select at least 3 points!", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "Understand!", style: .default)
            alert.addAction(action)
            self.present(alert, animated:true, completion: nil)
        }
    }

    @objc
    func leftHandAction() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.isReadyToEdit = false
        if self.area.count != 0 {
            self.reloadMap()
            self.area.removeAll()
        }
    }
    
    // MARK: - Custom functional
    func reloadMap() {
        self.map.mapObjects.clear()
        self.drawSavedPolygons()
    }
    
    func configureAlert(completion: @escaping (String) -> ()) {
        let alert = UIAlertController(title: "Name", message: "Please input name of field", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "Save Field", style: .default) { (alertAction) in
            let textField = alert.textFields!.first! as UITextField
            completion(textField.text!)
        }
        action.isEnabled = false
        alert.addTextField { (textField) in
            textField.placeholder = "Name of field"
        }
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object:alert.textFields?[0], queue: OperationQueue.main) { (notification) -> Void in
           let textField = alert.textFields!.first! as UITextField
            action.isEnabled = !textField.text!.isEmpty
        }
        alert.addAction(action)
        self.present(alert, animated:true, completion: nil)
    }
    
    func makePolygon(with points: [YMKPoint], with data: Field?, color: UIColor){
        let polygon = YMKPolygon(outerRing: YMKLinearRing(points: points), innerRings: [])
        let polygonMapObject = map.mapObjects.addPolygon(with: polygon)
        polygonMapObject.fillColor = UIColor.green.withAlphaComponent(0.16)
        polygonMapObject.strokeWidth = 3.0
        polygonMapObject.strokeColor = color
        polygonMapObject.isGeodesic = true
        guard let data = data else { return }
        polygonMapObject.userData = data
    }
    
    func drawSavedPolygons() {
        LocalDataManager.shared.getAllPolygons { (response) in
            switch response {
            case .failure(let error):
                print(error)
            case .success(let data):
                guard let fields = data else { return }
                var points: [YMKPoint] = []
                for field in fields {
                    let currentPoints = field.points
                    for point in currentPoints{
                        let currentPoint = YMKPoint(latitude: point[0], longitude: point[1])
                        points.append(currentPoint)
                        self.map.mapObjects.addPlacemark(with: currentPoint)
                    }
                    self.makePolygon(with: points, with: nil, color: .green)
                    points.removeAll()
                }
            }
        }
    }
    
    func drawNewPolygon(name: String, with points: [YMKPoint]) {
        var arrayOfPoints: [[Double]] = []
        for point in points {
            arrayOfPoints.append([point.latitude, point.longitude])
        }
        let id = UUID().uuidString
        let userData = Field(id: id, name: name, points: arrayOfPoints)
        makePolygon(with: points, with: userData, color: .green)
        LocalDataManager.shared.savePolygon(id: id, name: name, points: arrayOfPoints)
        self.area.removeAll()
    }
}

// MARK: - Tap Listener
extension ViewController: YMKMapInputListener {
    func onMapTap(with map: YMKMap, point: YMKPoint) {
        if self.isReadyToEdit {
            self.map.mapObjects.addPlacemark(with: point)
            self.area.append(point)
        }
    }
    
    func onMapLongTap(with map: YMKMap, point: YMKPoint) {
    }
}

// MARK: - User Location
extension ViewController: YMKUserLocationObjectListener {
    func getCurrentLocation() {
        self.map.isRotateGesturesEnabled = true
        self.map.move(with:
            YMKCameraPosition(target: YMKPoint(latitude: 0, longitude: 0), zoom: 14, azimuth: 0, tilt: 0))

        let scale = UIScreen.main.scale
        let mapKit = YMKMapKit.sharedInstance()
        let userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)

        userLocationLayer.setVisibleWithOn(true)
        userLocationLayer.isHeadingEnabled = true
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

// MARK: - Delegate Pattern Realisation
extension ViewController: ViewControllerDelegate {
    func reloadMapObjects() {
        self.reloadMap()
    }
    
    func moveCameraTo(field: Field) {
        let latitude = field.points.first!.first!
        let longtitude = field.points[field.points.count / 2].last!
        self.map.move(with: YMKCameraPosition(target: YMKPoint(latitude: latitude, longitude: longtitude), zoom: 14, azimuth: 0, tilt: 0))
    }
    
    func highLightField(field: Field) {
        var points: [YMKPoint] = []
        for point in field.points {
            let currentPoint = YMKPoint(latitude: point[0], longitude: point[1])
            points.append(currentPoint)
        }
        makePolygon(with: points, with: nil, color: .red)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.reloadMap()
        }
    }
}

// MARK: - PresenterKit
extension ViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        HalfModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
