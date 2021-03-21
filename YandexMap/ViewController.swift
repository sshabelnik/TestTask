//
//  ViewController.swift
//  YandexMap
//
//  Created by Сергей Шабельник on 20.03.2021.
//

import UIKit
import YandexMapsMobile

class ViewController: UIViewController, YMKMapInputListener {

    @IBOutlet weak var mapView: YMKMapView!
    
    private var area: [YMKPoint] = []
    
    private var map: YMKMap {
        return mapView.mapWindow.map
    }
    
    private var isReadyToEdit: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        mapView.mapWindow.map.move(
                with: YMKCameraPosition.init(target: YMKPoint(latitude: 55.751574, longitude: 37.573856), zoom: 15, azimuth: 0, tilt: 0),
                animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 5),
                cameraCallback: nil)

        map.addInputListener(with: self)
    }
    
    @IBAction func addFieldButtonPressed(_ sender: Any) {
        setNavigationButtons()
    }
    
    func setNavigationButtons() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(rightHandAction))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(leftHandAction))
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.isReadyToEdit = true
    }
    
    @objc
    func rightHandAction() {
        self.drawPolygon(with: area)
        self.area = []
        self.isReadyToEdit = false
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    @objc
    func leftHandAction() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.isReadyToEdit = false
    }
    
    func drawPolygon(with points: [YMKPoint]) {
        let polygon = YMKPolygon(outerRing: YMKLinearRing(points: points), innerRings: [])
        let polygonMapObject = map.mapObjects.addPolygon(with: polygon)
        polygonMapObject.fillColor = UIColor.green.withAlphaComponent(0.16)
        polygonMapObject.strokeWidth = 3.0
        polygonMapObject.strokeColor = .green
        polygonMapObject.isGeodesic = true
    }
    
    
    func onMapTap(with map: YMKMap, point: YMKPoint) {
        if self.isReadyToEdit {
            self.map.mapObjects.addPlacemark(with: point)
            self.area.append(point)
        }
    }
    
    func onMapLongTap(with map: YMKMap, point: YMKPoint) {
    }
}

