//
//  MapView.swift
//  Artylery smash
//
//  Created by Artem Leschenko on 16.11.2023.
//

import Foundation
import MapKit
import CoreLocation
import SwiftUI

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    @Binding var showWithHading: Bool
    @Binding var drawPolyline: Bool
    @Binding var needToShowUser: Bool
    @Binding var typeOfVisual: MainViewModel.TypeOfVisual
    var coordForFire: [CLLocationCoordinate2D]

    public init(region: Binding<MKCoordinateRegion>, mapType: Binding<MKMapType>, showWithHading: Binding<Bool>, drawPolyline: Binding<Bool>, needToShowUser: Binding<Bool>, coordForFire: [CLLocationCoordinate2D], typeOfVisual: Binding<MainViewModel.TypeOfVisual>) {
        _region = region
        _mapType = mapType
        _showWithHading = showWithHading
        _drawPolyline = drawPolyline
        _needToShowUser = needToShowUser
        _typeOfVisual = typeOfVisual
        self.coordForFire = coordForFire
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.region = region
        mapView.mapType = mapType
        mapView.userTrackingMode = showWithHading ? .followWithHeading : .none
        mapView.delegate = context.coordinator

        updateCircles(on: mapView) // Додано цей рядок для ініціалізації кіл при створенні картографічного представлення
        updatePolyline(on: mapView) // Додано цей рядок для ініціалізації ліній при створенні картографічного представлення
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if needToShowUser {
            uiView.setRegion(region, animated: true)
            needToShowUser = false
        }
        uiView.mapType = mapType
        uiView.userTrackingMode = showWithHading ? .followWithHeading : .none

        if drawPolyline {
            uiView.removeOverlays(uiView.overlays)
            switch typeOfVisual {
            case .line:
                updatePolyline(on: uiView)
            case .way:
                updateRoute(on: uiView) // Змінено виклик на функцію для відображення маршруту
            case .all:
                updatePolyline(on: uiView)
                updateRoute(on: uiView)
            }
            
        } else {
            // Якщо drawPolyline == false, то очищаємо всі маршрути та кільця
            uiView.removeOverlays(uiView.overlays)
            uiView.removeOverlays(uiView.overlays.filter { $0 is MKCircle }) // Очистка кіл
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        // Додаємо власний renderer для ліній
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = UIColor.red
                renderer.lineWidth = 2.0
                return renderer
            } else if overlay is MKCircle {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = UIColor.red.withAlphaComponent(0.3) // Полупрозрачний червоний колір
                renderer.strokeColor = UIColor.orange
                renderer.lineWidth = 2.0
                return renderer
            }
            return MKOverlayRenderer()
        }
    }

    private func updatePolyline(on mapView: MKMapView) {
        let polyline = MKPolyline(coordinates: coordForFire, count: coordForFire.count)

        mapView.addOverlay(polyline)

        // Додаємо кільця на початок та кінець лінії
        if let lastCoordinate = coordForFire.last {
            addCircle(on: mapView, coordinate: lastCoordinate)
        }
    }

    private func addCircle(on mapView: MKMapView, coordinate: CLLocationCoordinate2D) {
        let radiusAndDistance = InfoShoot(coord1: coordForFire.first!, coord2: coordForFire.last!).calculateRadiusAndDistance()
        let radius = radiusAndDistance.radius
        let distance = radiusAndDistance.distance
        
        // Додаємо кільце з повним радіусом
        let fullRadiusCircle = MKCircle(center: coordinate, radius: radius)
        mapView.addOverlay(fullRadiusCircle)

        // Додаємо кільце з половиною радіуса
        let halfRadius = radius / 2.0
        let halfRadiusCircle = MKCircle(center: coordinate, radius: halfRadius)
        mapView.addOverlay(halfRadiusCircle)
    }

    private func updateCircles(on mapView: MKMapView) {
        // Додаємо кільця на кожну точку лінії
        for coordinate in coordForFire {
            addCircle(on: mapView, coordinate: coordinate)
        }
    }
    
    
    private func updateRoute(on mapView: MKMapView) {
            guard coordForFire.count >= 2 else {
                return
            }

            let sourcePlacemark = MKPlacemark(coordinate: coordForFire[0])
            let destinationPlacemark = MKPlacemark(coordinate: coordForFire[coordForFire.count - 1])

            let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

            let request = MKDirections.Request()
            request.source = sourceMapItem
            request.destination = destinationMapItem
            request.transportType = .automobile // або .automobile, залежно від вашого вибору

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                guard let route = response?.routes.first else {
                    return
                }

                mapView.addOverlay(route.polyline, level: .aboveRoads)
            }
        }

        private func addRouteCircles(on mapView: MKMapView, route: MKRoute) {
            // Опціонально, якщо ви хочете додатково відображати кільця на точках маршруту
            for step in route.steps {
                addCircle(on: mapView, coordinate: step.polyline.coordinate)
            }
        }
}

