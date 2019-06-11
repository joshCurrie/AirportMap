//
//  resultsPageViewController.swift
//  AirportMap
//
//  Created by Joshua Currie on 6/1/19.
//  Copyright © 2019 Joshua Currie. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

class resultsPageViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var origin: UITextField!
    @IBOutlet weak var destination: UITextField!
    @IBOutlet weak var refreshResults: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var originText:String = ""
    var destinationText:String = ""
    
    var homePage: homePageViewController!
    var airportInfo: [[String]]!
    var currentRoute: [String]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        origin.text = originText
        destination.text = destinationText
        self.mapView.delegate = self
        addRouteToMap()
    }
    
    @IBAction func refreshClick(_ sender: Any) {
        if origin.text != originText {
            originText = origin.text ?? ""
            refreshMap()
        } else if destinationText != destination.text {
            destinationText = destination.text ?? ""
            refreshMap()
        }
    }
    
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let polyline = overlay as? MKPolyline {
            let lineRenderer = MKPolylineRenderer(polyline: polyline)
            lineRenderer.strokeColor = .blue
            lineRenderer.lineWidth = 2.0
            return lineRenderer
        }
        fatalError("Something wrong...")
    }
    
    private func presentErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    //This function refreshes the Map with the correctly inputted origin and destination.
    // Used primarily when user makes changes to origin and destination
    private func refreshMap() {
        
        let origin = self.origin.text
        let destination = self.destination.text
        
        let checkIATAs = homePage.IATAExists(iata: origin!) && homePage.IATAExists(iata: destination!)
        if (!checkIATAs) {
            presentErrorAlert(title: "Input Error", message: "Please make sure you have inputted a valid IATA in both fields")
        }
        
        let doesRouteExist = homePage.doesRouteExist(origin: origin!, destination: destination!)
        
        if (doesRouteExist) {
            currentRoute = homePage.shortestRoute
            mapView.removeAnnotations(mapView.annotations)
            mapView.removeOverlays(mapView.overlays)
            //route changed need to update map
            addRouteToMap()
        } else {
            presentErrorAlert(title: "Route Does Not Exist", message: "Route between \(origin!) and \(destination!) does not exist within our database")
        }
    }
    
    //This function is used to add self.currentRoute to the map.
    // Uses MKPolylines to draw between two points on the map
    private func addRouteToMap() {
        var annotationArray: [MKPointAnnotation] = []
        var coordinateArray: [CLLocationCoordinate2D] = []
        for airport in self.currentRoute
        {
            let cord = getCoordinates2D(airport: airport)
            let sourcePlacemark = MKPlacemark(coordinate: cord, addressDictionary: nil)
            let sourceAnnotation = MKPointAnnotation()
            if let location = sourcePlacemark.location {
                sourceAnnotation.coordinate = location.coordinate
            }
            annotationArray.append(sourceAnnotation)
            coordinateArray.append(cord)
        }
        
        let routePolyline = MKPolyline(coordinates: coordinateArray, count: coordinateArray.count)
        mapView.addOverlay(routePolyline)
        mapView.showAnnotations(annotationArray, animated: true)
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    //Gets the longitude and latitude of the inputted airport
    // uses it to construct a CLLocationCoordinate2D type 
    private func getCoordinates2D(airport: String) -> CLLocationCoordinate2D {
        let airportInfo = self.homePage.dataArrayAirports
        for ai in airportInfo! {
            if airport == ai[3] {
                return CLLocationCoordinate2D(latitude: CLLocationDegrees(exactly: Double(ai[4])!)!, longitude: CLLocationDegrees(exactly: Double(ai[5])!)!)
            }
        }
        
        let emptyCord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        return emptyCord
    }
}
