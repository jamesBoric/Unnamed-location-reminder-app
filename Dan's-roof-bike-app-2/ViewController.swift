//
//  ViewController.swift
//  Dan's bike roof app
//
//  Created by James Boric on 14/7/18.
//  Copyright © 2018 Ode To Code. All rights reserved.
//

//Suggestions for places
//bug with search bar search can't cancel


import UIKit
import MapKit
import CoreData
import UserNotifications
import AVFoundation

var managedObjectDictionary: [String: NSManagedObject] = [:]

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var mainMapView: MKMapView!
    
    let addButtonView = UIView()
    
    let searchBar = UISearchBar()
    
    @IBOutlet weak var changingView: UIView!
    
    let plusLayer = CAShapeLayer()
    
    let manager = CLLocationManager()
    
    @IBOutlet weak var changeButton: UIButton!
    
    @IBOutlet weak var linkView: UIView!

    var objectToPass: NSEntityDescription = NSEntityDescription()
    
    var shouldAddPin = false
    
    @IBAction func longPressAddPin(_ sender: UILongPressGestureRecognizer) {
    
        if sender.state == .began && shouldAddPin {
            
            var location = mainMapView.centerCoordinate
            
            expandTextField(changeButton)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            var context = appDelegate.persistentContainer.viewContext
            
            var newUser = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
            
            newUser.setValue("New Place", forKey: "name")
            
            newUser.setValue(1000, forKey: "distance")
            
            newUser.setValue(location.latitude, forKey: "latitude")
            
            newUser.setValue(location.longitude, forKey: "longitude")
            
            newUser.setValue(true, forKey: "active")
            
            do {
            
                try context.save()
                
                addAnnotatedPlace(place: Place(name: "New Place", location: location, reminder: 1000, object: newUser, active: true))
                
                managedObjectDictionary["\(location.latitude)|\(location.longitude)"] = newUser
                
                print("SAVED")
                
            }
            catch {
                
                print("Crashed")
            
            }
            
        }
    }
    //MARK
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let activityIndicator = UIActivityIndicatorView()
        
        activityIndicator.activityIndicatorViewStyle = .gray
        
        activityIndicator.center = self.view.center
        
        activityIndicator.hidesWhenStopped = true
        
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
        
        searchBar.resignFirstResponder()
        
        let searchRequest = MKLocalSearchRequest()
        
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
        
            activityIndicator.stopAnimating()
            
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil {
            
                print("error")
            }
            else {
            
                let latitude = response?.boundingRegion.center.latitude
                
                let longitude = response?.boundingRegion.center.longitude
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
                
                let span = MKCoordinateSpanMake(0.01, 0.01)
                
                let region = MKCoordinateRegionMake(coordinate, span)
                
                self.mainMapView.setRegion(region, animated: true)
                
            }
        }
        
        changeButton.frame.origin.x = 100
    }
    
    func addAnnotatedPlace(place: Place) {
    
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = place.location
        
        annotation.title = place.name
        
        switch place.reminder {
        
        case 500:
            annotation.subtitle = "500 metres"
        
        case 1000:
            annotation.subtitle = "1 kilometre"
        
        case 2000:
            annotation.subtitle = "2 kilometres"
            
        default:
            annotation.subtitle = "3 kilometres"
        }
        mainMapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
        
            return nil
        }
        
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "myReuseIdentifier")
        
        annotationView.image = UIImage(named: "myPin")
        
        annotationView.frame.size = CGSize(width: 45, height: 84)
        
        annotationView.canShowCallout = true
        
        let btn = UIButton(type: .detailDisclosure)
        
        btn.addTarget(self, action: #selector(ViewController.move), for: .touchUpInside)
        
        annotationView.rightCalloutAccessoryView = btn
        
        let switchDemo = UISwitch()
        
        switchDemo.setOn((managedObjectDictionary["\((annotation.coordinate.latitude))|\((annotation.coordinate.longitude))"]!.value(forKey: "active") as! Bool), animated: false)
        
        switchDemo.isEnabled = true;
        
        annotationView.leftCalloutAccessoryView = switchDemo
       
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    
        if control != view.rightCalloutAccessoryView {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            var newUser = managedObjectDictionary["\((view.annotation?.coordinate.latitude)!)|\((view.annotation?.coordinate.longitude)!)"]!
            
            let tapp = Place(
        
                name: newUser.value(forKey: "name") as! String,
                
                location: CLLocationCoordinate2D(
                    latitude: newUser.value(forKey: "latitude") as! Double,
                    longitude: newUser.value(forKey: "longitude") as! Double
                ),
                
                reminder: newUser.value(forKey: "distance") as! Int,
                
                object: newUser, active: newUser.value(forKey: "active") as! Bool
            )
            
            newUser.setValue((control as! UISwitch).isOn, forKey: "active")
            
            if (control as! UISwitch).isOn == true {
                
                let content = UNMutableNotificationContent()
                
                content.title = "You are about to arrive at \(tapp.name)"
                
                content.body = "Watch out for enclosed spaces."
                
                content.sound = UNNotificationSound(named: "horn.caf")
                
                let center = CLLocationCoordinate2D(latitude: tapp.location.latitude, longitude: tapp.location.longitude)
                
                let region = CLCircularRegion(center: center, radius: CLLocationDistance(tapp.reminder), identifier: tapp.name)
                
                if tapp.reminder != 500 {
                    let region2 = CLCircularRegion(center: center, radius: 500, identifier: "+\(tapp.name)")
                    let trigger2 = UNLocationNotificationTrigger(region: region2, repeats: false)
                    let request2 = UNNotificationRequest(identifier: "+\(tapp.location.latitude)|\(tapp.location.longitude)", content: content, trigger: trigger2)
                    locationManager.startMonitoring(for: region2)
                    region2.notifyOnEntry = true
                    region2.notifyOnExit = false
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["+\(tapp.location.latitude)|\(tapp.location.longitude)"])
                    UNUserNotificationCenter.current().add(request2, withCompletionHandler: nil)
                }
                
                locationManager.distanceFilter = kCLDistanceFilterNone
                
                locationManager.startMonitoring(for: region)
                
                region.notifyOnEntry = true
                
                region.notifyOnExit = false
                
                let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
                
                let request = UNNotificationRequest(identifier: "\(tapp.location.latitude)|\(tapp.location.longitude)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(tapp.location.latitude)|\(tapp.location.longitude)"])
                
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
            else {
                
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(tapp.location.latitude)|\(tapp.location.longitude)"])
                
                let center = CLLocationCoordinate2D(latitude: tapp.location.latitude, longitude: tapp.location.longitude)
                
                let region = CLCircularRegion(center: center, radius: CLLocationDistance(tapp.reminder), identifier: tapp.name)
                
                locationManager.stopMonitoring(for: region)
            }
            
            appDelegate.saveContext()
        }
    }
    
    @objc func move() {
        
        self.performSegue(withIdentifier: "placeDeets", sender: nil)
    }
    
    var entityToPass = NSManagedObject()
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        entityToPass = managedObjectDictionary["\((view.annotation?.coordinate.latitude)!)|\((view.annotation?.coordinate.longitude)!)"]!
    }
    
    @IBAction func goToWebpage(_ sender: UIButton) {
       
        UIApplication.shared.open(URL(string: "https://komfa.com.au/")!, options: [:], completionHandler: nil)
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        if isExpand {
        
            searchBar.alpha = 1
            
            changingView.frame = CGRect(x: 16, y: 20 + 20, width: view.frame.size.width - 2 * 16, height: changingView.frame.size.height)
            
            changingView.layer.cornerRadius = 4
            
            changingView.backgroundColor = UIColor.white
            
            addButtonView.transform = CGAffineTransform(rotationAngle: -3 * .pi/4)
            
            addButtonView.center.x = (view.frame.size.width - 2 * 16) - (addButtonView.frame.size.height / 3)
            
            shouldAddPin = true
            
            plusLayer.fillColor = UIColor.gray.cgColor
            
            changeButton.frame.origin.x = view.frame.size.width + 100
        }
        else {
            
            searchBar.alpha = 0
            
            changingView.frame = CGRect(
                x: view.frame.size.width - 16 - changingView.frame.size.height,
                y: 20 + 20,
                width: changingView.frame.size.height,
                height: changingView.frame.size.height
            )
            
            changingView.layer.cornerRadius = changingView.frame.size.height/2
            
            changingView.backgroundColor = UIColor.black
            
            addButtonView.transform = CGAffineTransform(rotationAngle: 0)
            
            addButtonView.frame.origin = CGPoint(x: 0, y: 0)
            
            plusLayer.fillColor = UIColor.white.cgColor
            
            shouldAddPin = false
            
            searchBar.isHidden = true
            
            changeButton.frame.origin.x = 0
        }
    }
    var selectedPlace: Place?
    
    let pinView = UIImageView()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        pinView.isHidden = true
        
        pinView.frame.size = CGSize(width: 50, height: 94)
        
        pinView.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height / 2)
        
        pinView.image = UIImage(named: "myPin")
        
        view.addSubview(pinView)
        
        manager.delegate = self
        
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        manager.distanceFilter = kCLDistanceFilterNone
        
        manager.requestAlwaysAuthorization()
        
        manager.requestWhenInUseAuthorization()
        
        manager.startUpdatingLocation()
        
        
        if manager.location != nil {
            
            let span: MKCoordinateSpan = try MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
            let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: manager.location!.coordinate.latitude, longitude: manager.location!.coordinate.longitude)
        
            let region:MKCoordinateRegion = MKCoordinateRegion(center: myLocation, span: span)
            
            mainMapView.setRegion(region, animated: true)
            
            mainMapView.showsUserLocation = true
        }
        
        searchBar.barTintColor = UIColor.white
        
        searchBar.searchBarStyle = .minimal
        
        searchBar.delegate = self
        
        addButtonView.frame = CGRect(x: 0, y: 0, width: changingView.frame.size.width, height: changingView.frame.size.height)
        
        addButtonView.backgroundColor = UIColor.clear
        
        changingView.addSubview(addButtonView)
        
        changingView.sendSubview(toBack: addButtonView)
        
        changingView.layer.shadowColor = UIColor.black.cgColor
        
        changingView.layer.shadowOpacity = 1
        
        changingView.layer.shadowOffset = CGSize(width: 0, height: 3)
        
        changingView.layer.shadowRadius = 3
        
        linkView.layer.shadowColor = UIColor.black.cgColor
        
        linkView.layer.shadowOpacity = 1
        
        linkView.layer.shadowOffset = CGSize(width: 0, height: 3)
        
        linkView.layer.shadowRadius = 3
        
        linkView.layer.cornerRadius = 10
        
        changingView.layer.cornerRadius = addButtonView.frame.size.height/2
        
        changingView.clipsToBounds = false
        
        searchBar.frame = CGRect(x: 8, y: 8, width: view.frame.size.width - 16 * 2 - 60, height: 60 - 16)
        
        searchBar.placeholder = "Search"
        
        changingView.addSubview(searchBar)
        
        searchBar.isHidden = true
        
        searchBar.alpha = 0
        
        let plusWidth: CGFloat = 2
        
        let spacing: CGFloat = 10
        
        let importantSize = addButtonView.frame.size.height - spacing * 2
        
        //// Rectangle Drawing
        let plusPath = UIBezierPath()
        
        plusPath.move(to: CGPoint(x: spacing, y: spacing + (importantSize - plusWidth)/2))
        plusPath.addLine(to: CGPoint(x: spacing + (importantSize - plusWidth)/2, y: spacing + (importantSize - plusWidth)/2))
        plusPath.addLine(to: CGPoint(x: spacing + (importantSize - plusWidth)/2, y: spacing))
        plusPath.addLine(to: CGPoint(x: spacing + (importantSize - plusWidth)/2 + plusWidth, y: spacing))
        plusPath.addLine(to: CGPoint(x: spacing + (importantSize - plusWidth)/2 + plusWidth, y: spacing + (importantSize - plusWidth)/2))
        plusPath.addLine(to: CGPoint(x: importantSize + spacing, y: spacing + (importantSize - plusWidth)/2))
        plusPath.addLine(to: CGPoint(x: importantSize + spacing, y: spacing + (importantSize - plusWidth)/2 + plusWidth))
        plusPath.addLine(to: CGPoint(x: spacing + (importantSize - plusWidth)/2 + plusWidth, y: spacing + (importantSize - plusWidth)/2 + plusWidth))
        plusPath.addLine(to: CGPoint(x: spacing + (importantSize - plusWidth)/2 + plusWidth, y: importantSize + spacing))
        plusPath.addLine(to: CGPoint(x: spacing + (importantSize - plusWidth)/2, y: importantSize + spacing))
        plusPath.addLine(to: CGPoint(x: spacing + (importantSize - plusWidth)/2, y: spacing + (importantSize - plusWidth)/2 + plusWidth))
        plusPath.addLine(to: CGPoint(x: spacing, y: spacing + (importantSize - plusWidth)/2 + plusWidth))
        
        plusLayer.fillColor = UIColor.white.cgColor
        
        plusLayer.path = plusPath.cgPath
        
        addButtonView.layer.addSublayer(plusLayer)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        
        request.returnsObjectsAsFaults = false
        
        do {
            
            let results = try context.fetch(request)
            
            if results.count > 0 {
              
                for result in (results as! [NSManagedObject]) {
                
                    let myPlace = Place(
                    
                        name: result.value(forKey: "name") as! String,
                        
                        location: CLLocationCoordinate2D(
                            latitude: result.value(forKey: "latitude") as! Double,
                            longitude: result.value(forKey: "longitude") as! Double
                        ),
                        
                        reminder: result.value(forKey: "distance") as! Int,
                        
                        object: result,
                        
                        active: result.value(forKey: "active") as! Bool
                    )
                    
                    managedObjectDictionary["\(myPlace.location.latitude)|\(myPlace.location.longitude)"] = result
                    
                    addAnnotatedPlace(place: myPlace)
                    
                    if myPlace.active {
                    
                        locationManager.delegate = self
                        
                        locationManager.requestAlwaysAuthorization()
                        
                        locationManager.startUpdatingLocation()
                        
                        let content = UNMutableNotificationContent()
                        
                        content.title = "You are about to arrive at \(myPlace.name)"
                        
                        content.body = "Watch out for any enclosed spaces."
                        
                        content.sound = UNNotificationSound(named: "horn.caf")
                        
                        let center = CLLocationCoordinate2D(latitude: myPlace.location.latitude, longitude: myPlace.location.longitude)
                        
                        let region = CLCircularRegion(center: center, radius: CLLocationDistance(myPlace.reminder), identifier: myPlace.name)
                        
                        if myPlace.reminder != 500 {
                            let region2 = CLCircularRegion(center: center, radius: 500, identifier: "+\(myPlace.name)")
                            let trigger2 = UNLocationNotificationTrigger(region: region2, repeats: false)
                            let request2 = UNNotificationRequest(identifier: "+\(myPlace.location.latitude)|\(myPlace.location.longitude)", content: content, trigger: trigger2)
                            locationManager.startMonitoring(for: region2)
                            region2.notifyOnEntry = true
                            region2.notifyOnExit = false
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["+\(myPlace.location.latitude)|\(myPlace.location.longitude)"])
                            UNUserNotificationCenter.current().add(request2, withCompletionHandler: nil)
                        }
                        
                        locationManager.distanceFilter = 100
                        
                        locationManager.startMonitoring(for: region)
                        
                        region.notifyOnEntry = true
                        
                        region.notifyOnExit = false
                        
                        let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
                        
                        let request = UNNotificationRequest(identifier: "\(myPlace.location.latitude)|\(myPlace.location.longitude)", content: content, trigger: trigger)
                        
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(myPlace.location.latitude)|\(myPlace.location.longitude)"])
                        
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                       
                    }
                }
            }
        }
        catch {
            //nothing
        }
        
    }
    
    var soundToPlay: AVAudioPlayer?
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("EnteredRegion")
        let alert = UIAlertController(title: "You've almost arrived", message: "Watch out for enclosed spaces.", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: {
            print("Alert dismissed")
        })
        
        let path = Bundle.main.path(forResource: "horn.caf", ofType: nil)!
        
        let url = URL(fileURLWithPath: path)
        
        do {
        
            soundToPlay = try AVAudioPlayer(contentsOf: url)
            
            soundToPlay?.play()
        }
        catch {
            // couldn't load file :(
        }
    }
    
    let locationManager: CLLocationManager = CLLocationManager()
    
    var isExpand = false
    
    @IBAction func expandTextField(_ sender: UIButton) {
        
        if isExpand {
        
            pinView.isHidden = true
            
            searchBar.resignFirstResponder()
            
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
            
                self.searchBar.alpha = 0
                
                self.changingView.frame = CGRect(
                    x: self.view.frame.size.width - 16 - self.changingView.frame.size.height,
                    y: 20 + 20,
                    width: self.changingView.frame.size.height,
                    height: self.changingView.frame.size.height
                )
                
                self.changingView.layer.cornerRadius = self.changingView.frame.size.height/2
                
                self.changingView.backgroundColor = UIColor.black
                
                self.addButtonView.transform = CGAffineTransform(rotationAngle: 0)
                
                self.addButtonView.frame.origin = CGPoint(x: 0, y: 0)
                
                self.plusLayer.fillColor = UIColor.white.cgColor
                
            }, completion: { (Bool) in
                
                self.shouldAddPin = false
                
                self.searchBar.isHidden = true
                
                self.isExpand = false
                
                sender.frame.origin.x = 0
            }
            )
            
            
        }
        else {
            
            pinView.isHidden = false
            
            searchBar.isHidden = false
            
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
            
                self.searchBar.alpha = 1
                
                self.changingView.frame = CGRect(x: 16, y: 20 + 20, width: self.view.frame.size.width - 2 * 16, height: self.changingView.frame.size.height)
                
                self.changingView.layer.cornerRadius = 4
                
                self.changingView.backgroundColor = UIColor.white
                
                self.addButtonView.transform = CGAffineTransform(rotationAngle: -3 * .pi/4)
                
                self.addButtonView.center.x = (self.view.frame.size.width - 2 * 16) - (self.addButtonView.frame.size.height / 3)
            }, completion: { (Bool) in
                
                self.shouldAddPin = true
                
                self.isExpand = true
                
                self.plusLayer.fillColor = UIColor.gray.cgColor
                
                sender.frame.origin.x = self.view.frame.size.width - 2 * 16 - sender.frame.size.width
            }
            )
        }
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "placeDeets" {
        
            if let nextVC = segue.destination as? AddDetailsViewController {
            
                nextVC.passedEntity = entityToPass
            }
        }
    }
}
