//
//  ViewController.swift
//  kiatukei
//
//  Created by tanakasouta on 2019/03/25.
//  Copyright © 2019 tanakasouta. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation
import Charts

class ViewController: UIViewController, CLLocationManagerDelegate{
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var kaimennKiatuLabel: UILabel!
    @IBOutlet var altitudeLabel: UILabel!
    @IBOutlet var ido: UILabel!
    @IBOutlet var keido: UILabel!
    @IBOutlet var chartView: LineChartView!
    @IBOutlet var gpsHeight: UILabel!
    
    var pressureArray: [Float] = []
    
    
    let altimeter = CMAltimeter()
    
    var locationManager: CLLocationManager!
    
    var latitude: Double!
    var longitude: Double!
    var altitude: Double!
    
    var resData: resAltitude!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getKiatu()
        setupLocationManager()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        guard let locationManager = locationManager else { return }
        locationManager.requestWhenInUseAuthorization()
        
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.distanceFilter = 10
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let nowLocation = locations.first
        let nowLatitude = nowLocation?.coordinate.latitude
        let nowLongitude = nowLocation?.coordinate.longitude
        let nowAltitude = nowLocation?.altitude
        self.latitude = nowLatitude
        self.longitude = nowLongitude
        self.altitude = nowAltitude
        
        print("latitude: \(self.latitude!)\nlongitude: \(self.longitude!)")
        
        self.ido.text = String(latitude)
        self.keido.text = String(longitude)
        self.gpsHeight.text = String(format: "%.2f", altitude)
        
        getAltitude()
    }
    
    func getAltitude(){
        let urlStr = "http://cyberjapandata2.gsi.go.jp/general/dem/scripts/getelevation.php?lon=\(longitude as Double)&lat=\(latitude as Double)&outtype=JSON"
        
        let url = URL(string: urlStr)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        
        
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let data = data, let _ = response as? HTTPURLResponse {
                //print("statusCode: \(response.statusCode)")
                //print(String(data: data, encoding: String.Encoding.utf8) ?? "")
                do {
                    self.resData = try? JSONDecoder().decode(resAltitude.self, from: data)
                    print(self.resData)
                }catch let error{
                    print(error)
                    self.resData.elevation = 1013.0
                }
                
            }
            }.resume()
        
        
    }
    
    func convartPres(p: Double, h: Double, t: Int = 16)-> Double {
        var pres: Double!
        pres = p * pow((1 - (0.0065 * h / (Double(t) + 0.0065 * h + 273.13))), -5.257)
        return pres
    }
    
    func getKiatu(){
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler:
                {data, error in
                    if error == nil {
                        let pressure:Double = data?.pressure as! Double
                        //let altitude:Double = data?.relativeAltitude as! Double
                        //print(pressure)
                        //print(altitude)
                        self.label.text = String(Float(pressure) * 10)
                        self.pressureArray.append(Float(pressure * 10))
                        self.altitudeLabel.text = String(Float(self.resData.elevation))
                        self.kaimennKiatuLabel.text = String(Float(self.convartPres(p: pressure * 10, h: self.resData.elevation)))
                        
                        
                        self.displayChart(data: self.pressureArray)
                        
                    }else{
                        print(error ?? "nil")
                    }
            })
        } else{
            print("not use altimeter")
        }
        
    }
    
    func displayChart(data: [Float]){
        
        var entry = [ChartDataEntry]()
        
        for (i, d) in data.enumerated() {
            entry.append(ChartDataEntry(x: Double(i), y: Double(d) ))
        }
        
        let dataSet = LineChartDataSet(values: entry, label: "現在地気圧")
        
        chartView.xAxis.labelPosition = .bottom
        chartView.leftAxis.enabled = false
        dataSet.drawValuesEnabled = false
        
        chartView.data = LineChartData(dataSet: dataSet)
        
        
    }
    
}


struct resAltitude: Codable {
    var elevation: Double = 0
    var hsrc: String
}

