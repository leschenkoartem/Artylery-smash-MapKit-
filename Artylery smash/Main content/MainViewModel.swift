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

final class MainViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var detents = PresentationDetent.fraction(0.2)
    
    @Published var shootInfo: InfoShoot? { didSet { self.shouldDrawLine = shootInfo != nil } }
    @Published var infinityRange = false
    
    // firstVersion
    @Published var yourLongitudeInput = "" { willSet { self.shootInfo = nil } }
    @Published var yourLatitudeInput = "" { willSet { self.shootInfo = nil } }
    @Published var anamyLongitudeInput = "" { willSet { self.shootInfo = nil } }
    @Published var anamyLatitudeInput = "" { willSet { self.shootInfo = nil } }
    @Published var shouldDrawLine = false
    
    //secondVrsion
    @Published var youCoordinateAutomatic = "" { willSet { self.shootInfo = nil } }
    @Published var anamyCoordinateAutomatic = "" { willSet { self.shootInfo = nil } }
    @Published var selectedInputType = TypeOfInput.automatic
    @Published var needToShowUser = true
    
    @Published var showAlert = false
    @Published var textAlert = "" { didSet { showAlert = true } }
        
    // For Map Settings
    @Published var position = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 50.43709, longitude: 10.40787), latitudinalMeters: 4000, longitudinalMeters: 4000)
    @Published var followHead = false
    @Published var mapType: MKMapType = .standard
     
    
    enum TypeOfInput {
        case custom, automatic
    }
    
    private let locationManager = CLLocationManager()
    
    var userLocation: CLLocationCoordinate2D?
    {
        didSet {
            if oldValue == nil {
                showUser()
                self.yourLongitudeInput = "\(userLocation!.longitude)"
                self.yourLatitudeInput = "\(userLocation!.latitude)"
                self.youCoordinateAutomatic = "(\(userLocation!.latitude), \(userLocation!.longitude))"
            }
        }
    }
    
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
        
    func startFolowingHead() {
        guard locationManager.checkLAStatus() else { textAlert = "Please provide access to your geolocation to use this feature"; return }
        withAnimation {
            followHead.toggle()
        }
    }
    
    func getCoordinates() -> [CLLocationCoordinate2D] {
        switch selectedInputType {
        case .custom:
            // Генерація випадкових значень, якщо вхідні дані не є коректними
            guard let latitudeYou = Double(yourLatitudeInput),
                  let longtitudeYou = Double(yourLongitudeInput),
                  let latitudeAnamy = Double(anamyLatitudeInput),
                  let longtitudeAnamy = Double(anamyLongitudeInput) else {
                // Якщо дані некоректні, повернемо випадкові координати
                return []
            }
            
            let coordinatesYou = CLLocationCoordinate2D(latitude: latitudeYou, longitude: longtitudeYou)
            let coordinatesAnamy = CLLocationCoordinate2D(latitude: latitudeAnamy, longitude: longtitudeAnamy)
            
            let location1 = CLLocation(latitude: coordinatesYou.latitude, longitude: coordinatesYou.longitude)
            let location2 = CLLocation(latitude: coordinatesAnamy.latitude, longitude: coordinatesAnamy.longitude)
            location1.distance(from: location2)
            
            if self.infinityRange {
                return [coordinatesYou, coordinatesAnamy]
            } else {
                return location1.distance(from: location2) > 50_000 ? [] : [coordinatesYou, coordinatesAnamy]
            }
        case .automatic:
            // Отримання координат з автоматичних властивостей
            guard let coordinatesYou = convertCoordinateString(youCoordinateAutomatic),
                  let coordinatesAnamy = convertCoordinateString(anamyCoordinateAutomatic) else {
                // Якщо дані некоректні, повернемо випадкові координати
                return []
            }
            
            let location1 = CLLocation(latitude: coordinatesYou.latitude, longitude: coordinatesYou.longitude)
            let location2 = CLLocation(latitude: coordinatesAnamy.latitude, longitude: coordinatesAnamy.longitude)
            location1.distance(from: location2)
            
            if self.infinityRange {
                return [coordinatesYou, coordinatesAnamy]
            } else {
                return location1.distance(from: location2) > 50_000 ? [] : [coordinatesYou, coordinatesAnamy]
            }
        }
        
        func convertCoordinateString(_ coordinateString: String) -> CLLocationCoordinate2D? {
            let coordinateComponents = coordinateString
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .components(separatedBy: ",")
                .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            
            guard coordinateComponents.count == 2 else {
                // Неправильний формат рядка координат
                return nil
            }

            let latitude = coordinateComponents[0]
            let longitude = coordinateComponents[1]

            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    func showAnamy() {
        switch selectedInputType {
        case .custom:
            guard let latitudeAnamy = Double(anamyLatitudeInput),
                  let longtitudeAnamy = Double(anamyLongitudeInput) else { textAlert = "Enter the correct coordinates"; return }
            needToShowUser = true
            let coordinatesAnamy = CLLocationCoordinate2D(latitude: latitudeAnamy, longitude: longtitudeAnamy)
            self.position = MKCoordinateRegion(center: coordinatesAnamy, latitudinalMeters: 4000, longitudinalMeters: 4000)
        case .automatic:
            var coord = getCoordinates()
            guard  !coord.isEmpty else { textAlert = "Enter the correct coordinates"; return }
            needToShowUser = true
            let coordinatesAnamy = CLLocationCoordinate2D(latitude: coord.last!.latitude, longitude: coord.last!.longitude)
            self.position = MKCoordinateRegion(center: coordinatesAnamy, latitudinalMeters: 4000, longitudinalMeters: 4000)
        }
    }
    
    func showUser() {
        guard locationManager.checkLAStatus() else { textAlert = "Please provide access to your geolocation to use this feature"; return }
        needToShowUser = true
        guard let location = userLocation else { textAlert = "Something went wrong"; return }
        self.position = MKCoordinateRegion(center: location, latitudinalMeters: 4000, longitudinalMeters: 4000)
    }
    
    
}

extension CLLocationManager {
    func checkLAStatus() -> Bool {
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            // Разрешение получено
            return true
        case .denied, .restricted:
            // Разрешение отклонено или ограничено
            return false
        case .notDetermined:
            // Разрешение еще не запрошено
            return false
        @unknown default:
            return false
        }
    }
}

struct InfoShoot {
    var coord1: CLLocationCoordinate2D
    var coord2: CLLocationCoordinate2D
    
    var distance: Int {
        Int(self.calculateRadiusAndDistance().distance)
    }
    var spreadInMeters: Int { Int(self.calculateRadiusAndDistance().radius) }
    var spreadInMetersForView: CLLocationDistance { self.calculateRadiusAndDistance().radius }
    var projectileHeight: Int {
            calculateProjectileHeight()
        }
        
        var flightTime: Double {
            calculateFlightTime()
        }
    
    static func makeInfo(_ coords: [CLLocationCoordinate2D], infRange: Bool) -> InfoShoot? {
        guard !coords.isEmpty else { return nil }
        let info = InfoShoot(coord1: coords.first!, coord2: coords.last!)
        
        if infRange {
            return info
        } else {
            print(info.distance)
            return info.distance > 50_000 ? nil : info
        }
    }
    
    func calculateRadiusAndDistance() -> (distance: CLLocationDistance, radius: CLLocationDistance) {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        let distance = location1.distance(from: location2)
        
        // Змініть формулу для розрахунку радіуса, використовуючи ваш власний коефіцієнт
        // У цьому прикладі, 2 метри додаються до радіуса за кожний кілометр відстані.
        let additionalRadius = 2.0 * distance / 1_000.0
        let finalRadius = 20.0 + additionalRadius
        
        return (distance, finalRadius)
    }
    
    func calculateProjectileHeight() -> Int {
            // Розрахунок висоти снаряду
            // Ваш код тут
            
            return 0 // Повертаємо заглушкове значення, замініть його на реальний розрахунок
        }
        
        func calculateFlightTime() -> Double {
            // Розрахунок часу польоту
            // Ваш код тут
            
            return 0.0 // Повертаємо заглушкове значення, замініть його на реальний розрахунок
        }
}
