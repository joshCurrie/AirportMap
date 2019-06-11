//
//  ViewController.swift
//  AirportMap
//
//  Created by Joshua Currie on 5/28/19.
//  Copyright © 2019 Joshua Currie. All rights reserved.
//

import UIKit
import MapKit

class homePageViewController: UIViewController {

    @IBOutlet weak var origin: UITextField!
    @IBOutlet weak var destination: UITextField!
    @IBOutlet weak var findRoute: UIButton!
    
    var dataArrayAirports: [[String]]!
    var dataArrayRoutes: [[String]]!
    var shortestRoute: [String]!
    
    private var originLatitude: String!
    private var originLongitude: String!
    
    private var destinationLatitude: String!
    private var destinationLongitude: String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        collectAirportInformation()
        collectRouteInformation()
        
    }
    
    
    
    @IBAction func submitRoute(_ sender: Any) {
        if (!origin.hasText || !destination.hasText) {
            let alert = UIAlertController(title: "Input Error", message: "Please make sure you have inputted a valid IATA in both fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            
            self.present(alert, animated: true)
        }
        else {
            //open a different page
            if IATAExists(iata: origin.text ?? "") && IATAExists(iata: destination.text ?? "") {
                if (doesRouteExist(origin: origin.text ?? "", destination: destination.text ?? "")) {
                    self.performSegue(withIdentifier: "homeToResultsSegue", sender: self)
                } else {
                    presentErrorAlert(title: "Route Does Not Exist", message: "Route between \(origin.text!) and \(destination.text!) does not exist within our database")
                }
            }
            else {
                presentErrorAlert(title: "Input Error", message: "Please make sure you have inputted a valid IATA in both fields")
            }
        }
    }
    
    private func presentErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "homeToResultsSegue") {
            let vc = segue.destination as? resultsPageViewController
            vc?.originText = self.origin.text ?? ""
            vc?.destinationText = self.destination.text ?? ""
            vc?.homePage = self
            vc?.airportInfo = self.dataArrayAirports
            vc?.currentRoute = self.shortestRoute
            
        }
    }
    
    //Check to see if the associated IATA exists within the given csv file "airports.csv"
    public func IATAExists(iata: String) -> Bool {
        if iata == "" {
            return false
        }
        if (dataArrayAirports == nil) {
            collectAirportInformation()
        }
        
        for airportInfo in dataArrayAirports
        {
            if (iata == airportInfo[3]) {
                return true
            }
        }
        return false
    }
    
    //This function returns true is a route between origin and destination exist
    // false otherwise. It uses 'findRouteAlg' to find a route between origin and destination.
    // After it returns we check to see if we can shorten the given route, before returning true
    public func doesRouteExist(origin: String, destination: String) -> Bool {
        if (dataArrayRoutes == nil) {
            collectRouteInformation()
        }
        if (dataArrayRoutes.contains([origin, destination])) {
            shortestRoute = [origin, destination]
            return true
        }
        
        var currentRoute = findRouteAlg(origin: origin, destination: destination)
        if (currentRoute == []) {
            return false
        }
        currentRoute = shortenRoute(route: &currentRoute, destination: destination)
        shortestRoute = currentRoute
        return true
    }
    
    //shortenRoute is used to shorten the route. This function does not guarentee the shortest
    // route will be found, but makes an attempt to find one.
    /* Algorithm is as follows:
     
        given route = [A,B,C,...,Y,Z], where A is origin and Z is destination
        I iterate starting at A:
            I then start another iteration starting at Y,...,A
            During this step I check if there is a connection between A and Y
            If there is not a connection continue iterating on Y,...,A (in this case go to X)
            If there is a connection:
                I take the current route -> [A,...,Y,Z]
                Make beginningOfRoute = [A], and end of route = [Y,Z]
                making my currentRoute = [A] + [Y,Z] = [A,Y,Z]
     
    */
    private func shortenRoute(route: inout [String], destination: String) -> [String] {
        for i in 0...route.endIndex
        {
            if (i >= route.endIndex) {
                break;
            }
            let airport = route[i]
            if airport == destination {
                break
            } else {
                var restOfAirports = Array(route[i+1..<route.endIndex-1])
                if (restOfAirports.count == 0) {
                    continue;
                }
                for j in stride(from: restOfAirports.endIndex - 1, to: 0, by: -1)
                {
                    let newAirport = restOfAirports[j]
                    if (findConnection(origin: airport, destination: newAirport)) {
                        var beginningOfRoute = Array(route[0..<i+1])
                        let endOfRoute = Array(route[i+j+1..<route.endIndex])
                        beginningOfRoute.append(contentsOf: endOfRoute)
                        route = beginningOfRoute
                        break;
                    }
                }
            }
        }
        return route
    }
    
    //checks to see if there is a connection between given origin and destination
    private func findConnection(origin: String, destination: String) -> Bool {
        if (dataArrayRoutes.contains([origin,destination])) {
            return true
        } else {
            return false
        }
    }
    
    //findRouteAlg takes in the origin, and destination, and simply connects origin to destination
    // via available airports routes
    private func findRouteAlg(origin: String, destination: String) -> [String] {
        var routeInfo: [[String]] = dataArrayRoutes!
        var route: [String] = [origin]
        while (route.last != destination || routeInfo.count == 0) {
            var newRoute = grabNextOriginRoute(routeInfo: &routeInfo, origin: route[route.count-1]);
            if (newRoute == []) { //returns nil iff no more origin elements exist
                route.remove(at: route.count-1)
            } else if (!route.contains(newRoute[1])){
                route.append(newRoute[1]);
            }
        }
        if (route.last != destination) {
            return [];
        } else {
            return route;
        }
    }
    
    //This function, finds the next available route that has given origin, as the route origin.
    // For example: given YYZ as origin, it will find the next available connection in routeInfo,
    // such that the connection is in the form: (YYZ, *some destination*)
    // It will remove the found connection from routeInfo, and then return it
    private func grabNextOriginRoute(routeInfo: inout [[String]], origin: String) -> [String] {
        var counter: Int = 0
        var retVal: [String] = []
        for route in routeInfo
        {
            if (route[0] == origin) {
                retVal = route
                break;
            }
            counter+=1
        }
        if (retVal == []) {
            return retVal
        }
        routeInfo.remove(at: counter)
        return retVal
    }
    
    //collects given airports.csv information and stores it in class variable: dataArrayAirports
    private func collectAirportInformation() {
        dataArrayAirports = []
        if let path = Bundle.main.path(forResource: "airports", ofType: "csv") {
            let url = URL(fileURLWithPath: path)
            do {
                let data = try Data(contentsOf: url)
                let dataEncoded = String(data: data, encoding: .utf8)
                if let dataArr = dataEncoded?.components(separatedBy: "\r\n").map({ $0.components(separatedBy: ";") })
                {
                    for line in dataArr
                    {
                        var arrayOfElementsInLine = line[0].components(separatedBy: ",")
                        if (arrayOfElementsInLine[3] == "\\N") {
                            continue;
                        }
                        dataArrayAirports.append(arrayOfElementsInLine)
                    }
                }
            }
            catch let jsonErr {
                print("\n Error read CSV file: \n ", jsonErr)
            }
        }
    }
    
    //collects given routes.csv information and stores it in class variable: dataArrayRoutes
    private func collectRouteInformation() {
        dataArrayRoutes = []
        
        if let path = Bundle.main.path(forResource: "routes", ofType: "csv") {
            let url = URL(fileURLWithPath: path)
            do {
                let data = try Data(contentsOf: url)
                let dataEncoded = String(data: data, encoding: .utf8)
                if let dataArr = dataEncoded?.components(separatedBy: "\r\n").map({ $0.components(separatedBy: ";") })
                {
                    for line in dataArr
                    {
                        var newLine = line[0].components(separatedBy: ",");
                        newLine.remove(at: 0)
                        if (!dataArrayRoutes.contains(newLine)) {
                            dataArrayRoutes.append(newLine);
                        }
                    }
                }
            }
            catch let jsonErr {
                print("\n Error read CSV file: \n ", jsonErr)
            }
        }
        dataArrayRoutes.remove(at: 0)
    }
}




