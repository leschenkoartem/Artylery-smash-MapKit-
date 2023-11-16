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
                    drawPolyline: $vm.shouldDrawLine,
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
                        vm.startFolowingHead()
                    } label: {
                        Image(systemName: "arrow.down.circle.dotted")
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }.padding(.trailing)
            }
        }
        .sheet(isPresented: .constant(true)) {
            sheetView()
                .interactiveDismissDisabled()
                .presentationDetents([.fraction(0.2)], largestUndimmed: .fraction(0.2))
        }
    }
    
    @ViewBuilder
    func sheetView() -> some View {
        VStack {
            ZStack {
                VStack {
                    HStack {
                        Text("You:")
                            .frame(width: 70, alignment: .leading)
                        TextField("Coordinate", text: $vm.youCoordinateAutomatic)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Enemy:")
                            .frame(width: 70, alignment: .leading)
                        TextField("Coordinate", text: $vm.anamyCoordinateAutomatic)
                            .textFieldStyle(.roundedBorder)
                    }
                }.transition(.opacity)
            
                VStack {
                    HStack {
                        Text("You:")
                            .frame(width: 70, alignment: .leading)
                        TextField("Latitude", text: $vm.yourLatitudeInput)
                            .textFieldStyle(.roundedBorder)
                        TextField("Longtitude", text: $vm.yourLongitudeInput)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Enemy:")
                            .frame(width: 70, alignment: .leading)
                        TextField("Latitude", text: $vm.anamyLatitudeInput)
                            .textFieldStyle(.roundedBorder)
                        TextField("Longtitude", text: $vm.anamyLongitudeInput)
                            .textFieldStyle(.roundedBorder)
                    }
                }.transition(.opacity)
                    .background(Color(.systemGray6))
                    .opacity(vm.selectedInputType == .custom ? 1: 0)
            }
            
            HStack {
                Button {
                    withAnimation {
                        vm.selectedInputType = vm.selectedInputType == .automatic ? .custom: .automatic
                    }
                } label: {
                    Text("Switch input")
                }
                
                Spacer()
                Button {
                    vm.infinityRange.toggle()
                } label: {
                    Text("Inf (\(vm.infinityRange.description))")
                }
                Spacer()
                
                Button {
                    withAnimation {
                        vm.shootInfo = InfoShoot.makeInfo(vm.getCoordinates(), infRange: vm.infinityRange)
                        vm.showAnamy()
                    }
                } label: {
                    Text("Calculate")
                }
            }
            .alert(isPresented: $vm.showAlert) {
                Alert(
                    title: Text("Oops"),
                    message: Text(vm.textAlert),
                    dismissButton: .default(Text("OK"))
                )
            }
        }.padding()
    }
}

#Preview {
    MainView()
}






