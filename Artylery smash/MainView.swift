//
//  ContentView.swift
//  Artylery smash
//
//  Created by Artem Leschenko on 14.11.2023.
//

import CoreLocation
import MapKit
import SwiftUI

struct MainView: View {
    @StateObject var vm = MainViewModel()
    var body: some View {
        ZStack {
            MapView(region: $vm.position, 
                    mapType: $vm.mapType,
                    showWithHading: $vm.followHead,
                    drawPolyline: $vm.drawLine,
                    needToShowUser: $vm.needToShowUser,
                    coordForFire: vm.getCoordinates())
                            .edgesIgnoringSafeArea(.all)
                            .environmentObject(vm)
            
            HStack {
                Spacer()
                
                VStack {
                    Button {
                        vm.mapType = (vm.mapType == .standard) ? .satellite : .standard
                    } label: {
                        Image(systemName: "map")
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
    
                    Button {
                        withAnimation {
                            vm.showUser()
                        }
                    } label: {
                        Image(systemName: "location")
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        withAnimation {
                            vm.showAnamy()
                        }
                    } label: {
                        Image(systemName: "flame")
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        withAnimation {
                            vm.followHead.toggle()
                        }
                        
                    } label: {
                        Image(systemName: "arrow.down.circle.dotted")
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }.padding(.trailing)
            }
        }.sheet(isPresented: .constant(true)) {
            VStack {
                ZStack {
                    VStack {
                        HStack {
                            Text("You:")
                                .frame(width: 70, alignment: .leading)
                            TextField("Coordinate", text: $vm.coordinateYouAutomatic)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Text("Enemy:")
                                .frame(width: 70, alignment: .leading)
                            TextField("Coordinate", text: $vm.coordinateAnamyAutomatic)
                                .textFieldStyle(.roundedBorder)
                        }
                    }.transition(.opacity)
                
                    VStack {
                        HStack {
                            Text("You:")
                                .frame(width: 70, alignment: .leading)
                            TextField("Longtitude", text: $vm.longtitudeYou)
                                .textFieldStyle(.roundedBorder)
                            TextField("Latitude", text: $vm.latitudeYou)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Text("Enemy:")
                                .frame(width: 70, alignment: .leading)
                            TextField("Longtitude", text: $vm.longtitudeAnamy)
                                .textFieldStyle(.roundedBorder)
                            TextField("Latitude", text: $vm.latitudeAnamy)
                                .textFieldStyle(.roundedBorder)
                        }
                    }.transition(.opacity)
                        .background(Color(.systemGray6))
                        .opacity(vm.selectedInput == .custom ? 1: 0)
                }
                
                HStack {
                    Button {
                        withAnimation {
                            vm.selectedInput = vm.selectedInput == .automatic ? .custom: .automatic
                        }
                    } label: {
                        Text("Switch input")
                    }
                    Spacer()
                    Button {
                        withAnimation {
                            vm.drawLine = true
                            vm.showAnamy()
                        }
                    } label: {
                        Text("Calculate")
                    }
                }
            }.padding()
                .interactiveDismissDisabled()
                .presentationDetents([.fraction(0.2)], largestUndimmed: .fraction(0.2))
        }
    }
}

#Preview {
    MainView()
}

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
                renderer.fillColor = UIColor.red
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
        let circle = MKCircle(center: coordinate, radius: mapView.convert(1, toMetersFrom: mapView))
        mapView.addOverlay(circle)
    }

    private func updateCircles(on mapView: MKMapView) {
        // Додаємо кільця на кожну точку лінії
        for coordinate in coordForFire {
            addCircle(on: mapView, coordinate: coordinate)
        }
    }
}

extension MKMapView {
    func convert(_ value: Double, toMetersFrom mapView: MKMapView) -> CLLocationDistance {
        let region = mapView.region
        let span = region.span
        let centerCoordinate = region.center

        let latitudeRadians = centerCoordinate.latitude * .pi / 180.0

        let metersPerLongitude = Double(span.longitudeDelta) * 111.319 * cos(latitudeRadians)
        let metersPerLatitude = Double(span.latitudeDelta) * 111.319

        return value / 2 * (metersPerLongitude + metersPerLatitude)
    }
}





