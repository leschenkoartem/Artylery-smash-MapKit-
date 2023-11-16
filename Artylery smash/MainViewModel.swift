//
//  MainView.swift
//  Artylery smash
//
//  Created by Artem Leschenko on 14.11.2023.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

class MainViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var searchText = ""
    @Published var detents = PresentationDetent.fraction(0.2)
    
    
    // firstVersion
    @Published var longtitudeYou = "" { willSet { self.drawLine = false } }
    @Published var latitudeYou = "" { willSet { self.drawLine = false } }
    @Published var longtitudeAnamy = "" { willSet { self.drawLine = false } }
    @Published var latitudeAnamy = "" { willSet { self.drawLine = false } }
    @Published var drawLine = false
    //secondVrsion
    @Published var coordinateYouAutomatic = "" { willSet { self.drawLine = false } }
    @Published var coordinateAnamyAutomatic = "" { willSet { self.drawLine = false } }
    @Published var selectedInput = TypeOfInput.automatic
    @Published var needToShowUser = true
    
    enum TypeOfInput {
        case custom, automatic
    }
    
    private let locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D? 
    {
        didSet {
            if oldValue == nil {
                showUser()
                self.longtitudeYou = "\(userLocation!.longitude)"
                self.latitudeYou = "\(userLocation!.latitude)" 
                self.coordinateYouAutomatic = "(\(userLocation!.longitude), \(userLocation!.latitude))"
            }
        }
    }
    
    @Published var position = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 50.43709, longitude: 10.40787), latitudinalMeters: 4000, longitudinalMeters: 4000)
    @Published var followHead = false
    @Published var mapType: MKMapType = .standard
    @Published var anamyPosition: CLLocationCoordinate2D?
     
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first?.coordinate {
            userLocation = location
        }
    }
    
    func getCoordinates() -> [CLLocationCoordinate2D] {
        switch selectedInput {
        case .custom:
            // Генерація випадкових значень, якщо вхідні дані не є коректними
            let defaultCoordinatesYou = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) // Нью-Йорк
            let defaultCoordinatesAnamy = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437) // Лос-Анджелес
            
            guard let latitudeYou = Double(latitudeYou),
                  let longtitudeYou = Double(longtitudeYou),
                  let latitudeAnamy = Double(latitudeAnamy),
                  let longtitudeAnamy = Double(longtitudeAnamy) else {
                // Якщо дані некоректні, повернемо випадкові координати
                return [defaultCoordinatesYou, defaultCoordinatesAnamy]
            }
            
            let coordinatesYou = CLLocationCoordinate2D(latitude: latitudeYou, longitude: longtitudeYou)
            let coordinatesAnamy = CLLocationCoordinate2D(latitude: latitudeAnamy, longitude: longtitudeAnamy)
            
            return [coordinatesYou, coordinatesAnamy]
        case .automatic:
            // Отримання координат з автоматичних властивостей
            guard let coordinatesYou = convertCoordinateString(coordinateYouAutomatic),
                  let coordinatesAnamy = convertCoordinateString(coordinateAnamyAutomatic) else {
                // Якщо дані некоректні, повернемо випадкові координати
                let defaultCoordinatesYou = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) // Нью-Йорк
                let defaultCoordinatesAnamy = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437) // Лос-Анджелес
                return [defaultCoordinatesYou, defaultCoordinatesAnamy]
            }
            
            return [coordinatesYou, coordinatesAnamy]
        }
        
        func convertCoordinateString(_ coordinateString: String) -> CLLocationCoordinate2D? {
            let coordinateComponents = coordinateString.components(separatedBy: CharacterSet(charactersIn: "(),° ")).filter { !$0.isEmpty }

            guard coordinateComponents.count == 4 else {
                // Некоректний формат координат
                return nil
            }

            // Виділення компонентів координат
            let latitudeValue = Double(coordinateComponents[0]) ?? 0.0
            let longitudeValue = Double(coordinateComponents[2]) ?? 0.0
            let latitudeDirection = coordinateComponents[1].lowercased()
            let longitudeDirection = coordinateComponents[3].lowercased()

            // Перевірка та перетворення значень широти та довготи залежно від напрямків
            let latitude: Double
            let longitude: Double

            if latitudeDirection == "пн" {
                latitude = latitudeValue
            } else if latitudeDirection == "пд" {
                latitude = -latitudeValue
            } else {
                // Некоректний напрямок широти
                return nil
            }

            if longitudeDirection == "сх" {
                longitude = longitudeValue
            } else if longitudeDirection == "зх" {
                longitude = -longitudeValue
            } else {
                // Некоректний напрямок довготи
                return nil
            }

            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    func showAnamy() {
        guard let latitudeAnamy = Double(latitudeAnamy),
              let longtitudeAnamy = Double(longtitudeAnamy) else { return }
        needToShowUser = true
        let coordinatesAnamy = CLLocationCoordinate2D(latitude: latitudeAnamy, longitude: longtitudeAnamy)
        self.position = MKCoordinateRegion(center: coordinatesAnamy, latitudinalMeters: 4000, longitudinalMeters: 4000)
    }
    func showUser() {
        needToShowUser = true
        guard let location = userLocation else { return }
        self.position = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
    }
}
