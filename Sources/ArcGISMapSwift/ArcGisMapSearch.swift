//
//  ArcGISMapView.swift
//
//
//  Created by Hadeer on 6/5/24.
//

import SwiftUI
import ArcGIS
import ArcGISToolkit
import UIKit
import CoreLocation

let APIKEY = "AAPK02c4162a6c244595b0564d86007d14b9Wvyt7aoPDLSmphsm2gwYsNv3ov6GmtsaqObChcDJx0YGTThOj2FwZ8xQQatIp3ds"

public struct ArcGisMapSearch: View {
    @State private var viewpoint: Viewpoint? = Viewpoint(center: Point(x: -93.258133, y: 44.986656, spatialReference: .wgs84), scale: 1e3)
    @State private var isGeoViewNavigating = false
    @State private var geoViewExtent: Envelope?
    @State private var queryCenter: Point?
    @State private var identifyScreenPoint: CGPoint?
    @State private var identifyTapLocation: Point?
    @State private var calloutPlacement: CalloutPlacement?
    @ObservedObject private var locatorDataSource = LocatorSearchSource(name: "My Locator", maximumResults: 10, maximumSuggestions: 5)
    
    @StateObject private var model = Model()
    private var initLat: Double?
    private var initLng: Double?
    
    public struct Result {
        var country: String = ""
        var address: String = ""
        var latitude: Double = 0.0
        var longitude: Double = 0.0
        public init() {}
    }
    @Binding var result: Result
    @Binding var isRecenterCurrentLocation: Bool
    
    public init(initialLatitude: Double?, initialLongitude: Double?, result: Binding<Result>, isRecenterCurrentLocation: Binding<Bool>) {
        
        initLat = initialLatitude
        initLng = initialLongitude
        _result = result
        _isRecenterCurrentLocation = isRecenterCurrentLocation
        ArcGISEnvironment.apiKey = APIKey("AAPK02c4162a6c244595b0564d86007d14b9Wvyt7aoPDLSmphsm2gwYsNv3ov6GmtsaqObChcDJx0YGTThOj2FwZ8xQQatIp3ds")
        
    }
    
    public var body: some View {
        MapViewReader { proxy in
            MapView(
                map: model.map,
                viewpoint: viewpoint,
                graphicsOverlays: [model.searchResultsOverlay, model.graphicsOverlay]
            )
            
            .onSingleTapGesture { screenPoint, tapLocation in
                handleSingleTap(screenPoint: screenPoint, tapLocation: tapLocation)
            }
            .onNavigatingChanged { isGeoViewNavigating = $0 }
            .onViewpointChanged(kind: .centerAndScale) { viewpointChanged($0.targetGeometry.extent.center) }
            .onVisibleAreaChanged { geoViewExtent = $0.extent }
            .callout(placement: $calloutPlacement.animation()) { placement in
                Text(placement.geoElement?.attributes["Match_addr"] as? String ?? "Unknown Address").padding()
            }
            
            .task(id: identifyScreenPoint) {
                await performIdentify(proxy: proxy)
            }
            
            .overlay {
                SearchViewOverlay()
            }
            .onChange_(of: $isRecenterCurrentLocation) { oldValue, newValue in
                if isRecenterCurrentLocation {
                    Task{
                        await recenterDeviceLocation(proxy: proxy)
                    }
                }
                isRecenterCurrentLocation = false
            }
            
        }
        .onAppear {
            model.startLocationDataSource()
            initLocation()
            
        }
    }
    private func recenterDeviceLocation(proxy: MapViewProxy) async{
           guard let loc = model.deviceLocationPoint else { return }
           print(loc)
           dropPin(at: loc)
           viewpoint = Viewpoint(center: loc, scale: 1e4)
            await proxy.setViewpoint(viewpoint!, duration: 0.5) // Animate to the new viewpoint
           queryCenter = loc
    }
    private func initLocation() {
        var loc: Point? = nil
        if let initLat, let initLng{
            loc = Point(latitude: initLat, longitude: initLng)
        }else{
            loc = model.deviceLocationPoint
            print(loc)
        }
        
        guard let loc = loc else{return}
        
        dropPin(at: loc)
        viewpoint = Viewpoint(center: loc, scale: 1e4)
    }
    
    private func handleSingleTap(screenPoint: CGPoint, tapLocation: Point) {
        identifyScreenPoint = screenPoint
        identifyTapLocation = tapLocation
        dropPin(at: tapLocation)
        Task {
            await getAddressFromPoint(point: tapLocation)
        }
    }
    
    private func viewpointChanged(_ center: Point) {
        queryCenter = center
    }
    
    private func performIdentify(proxy: MapViewProxy) async {
        guard let screenPoint = identifyScreenPoint,
              let identifyResult = try? await proxy.identify(on: model.searchResultsOverlay, screenPoint: screenPoint, tolerance: 10) else { return }
        
        calloutPlacement = identifyResult.graphics.first.flatMap {
            CalloutPlacement.geoElement($0, tapLocation: identifyTapLocation)
        }
        identifyScreenPoint = nil
        identifyTapLocation = nil
    }
    
    private func getAddressFromPoint(point: Point) async {
        let params = ReverseGeocodeParameters()
        params.maxResults = 1
        
        guard let normalizedPoint = GeometryEngine.normalizeCentralMeridian(of: point) as? Point else { return }
        
        do {
            let geocodeResults = try await model.locatorTask.reverseGeocode(forLocation: normalizedPoint, parameters: params)
          //  print(geocodeResults.first?.attributes)
            if let address = geocodeResults.first?.attributes["LongLabel"] as? String {
                result.address = address
                result.latitude = point.y
                result.longitude = point.x
                print(address)
            }
            if let country = geocodeResults.first?.attributes["CntryName"] as? String {
                result.country = country
            }
        } catch {
            print(error)
        }
    }
    
    private func dropPin(at location: Point) {
        model.markerGraphic.geometry = location
        Task {
            await getAddressFromPoint(point: location)
        }
    }
    
    @ViewBuilder
    private func SearchViewOverlay() -> some View {
        HStack{
            SearchView(sources: [locatorDataSource], viewpoint: $viewpoint)
                .resultsOverlay(model.searchResultsOverlay)
                .queryCenter($queryCenter)
                .geoViewExtent($geoViewExtent)
                .isGeoViewNavigating($isGeoViewNavigating)
                .onQueryChanged { query in
                    if query.isEmpty {
                        calloutPlacement = nil
                    }
                }
                .padding()
                .padding(.trailing,60)
            
        }
    }
    
    private class Model: ObservableObject {
        let map = Map(basemapStyle: .osmStandard)
        let searchResultsOverlay = GraphicsOverlay()
        let graphicsOverlay = GraphicsOverlay()
        let markerGraphic = Graphic(symbol: PictureMarkerSymbol(image: UIImage(named: "marker", in: .module, with: nil) ?? UIImage()))
        let locatorTask = LocatorTask(url: .geocodeServer)
        let locationManager: CLLocationManager
        var deviceLocationPoint: Point? = nil
        
        init() {
            graphicsOverlay.addGraphic(markerGraphic)
            locationManager = CLLocationManager()
        }
        func startLocationDataSource() {
        
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            locationManager.startUpdatingLocation()
            if let location = locationManager.location{
                let point = Point(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                deviceLocationPoint = point
            }
        }
        
    }
}

private extension URL {
    static var geocodeServer: URL {
        URL(string: "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer")!
    }
}

//public class ImageProvider {
//    public static func loadImage(named imageName: String) -> UIImage? {
//        let bundle = Bundle.module
//        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
//    }
//}

//#Preview {
//    ArcGisMapSearch(initialLatitude: nil, initialLongitude: nil, result: .constant(ArcGisMapSearch.Result()), isRecenterCurrentLocation: .constant(false))
//}

