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
    var coordForFire: [CLLocationCoordinate2D]

    public init(region: Binding<MKCoordinateRegion>, mapType: Binding<MKMapType>, showWithHading: Binding<Bool>, drawPolyline: Binding<Bool>, needToShowUser: Binding<Bool>, coordForFire: [CLLocationCoordinate2D]) {
        _region = region
        _mapType = mapType
        _showWithHading = showWithHading
        _drawPolyline = drawPolyline
        _needToShowUser = needToShowUser
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
            updatePolyline(on: uiView)
        } else {
            // Якщо drawPolyline == false, то очищаємо всі лінії та кільця
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
                renderer.strokeColor = UIColor.blue
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

        // Очищаємо попередні лінії перед додаванням нової
        mapView.removeOverlays(mapView.overlays)

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
}

