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
    private let locationDisplay = LocationDisplay(dataSource: SystemLocationDataSource())
    
    @StateObject private var model = Model()
    private var initLat: Double
    private var initLng: Double
    
    public struct Result {
        var address: String = ""
        var latitude: Double = 0.0
        var longitude: Double = 0.0
        public init() {}
    }
    @Binding var result: Result
    
    public init(apiKey: String, initialLatitude: Double, initialLongitude: Double, result: Binding<Result>) {
        ArcGISEnvironment.apiKey = APIKey(apiKey)
        initLat = initialLatitude
        initLng = initialLongitude
        _result = result
    }
    
    public var body: some View {
        MapViewReader { proxy in
            MapView(
                map: model.map,
                viewpoint: viewpoint,
                graphicsOverlays: [model.searchResultsOverlay, model.graphicsOverlay]
            )
            .locationDisplay(locationDisplay)
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
            .task {
                await setupCurrentLocation()
            }
            .overlay {
                SearchViewOverlay()
            }
        }
        .onAppear {
            initLocation()
        }
    }
    private func setupCurrentLocation() async{
        print("current")
        let locationManager = CLLocationManager()
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        do {
            try await locationDisplay.dataSource.start()
            
            locationDisplay.initialZoomScale = 40_000
            locationDisplay.autoPanMode = .recenter
            print(locationDisplay.location)
        } catch {
            print("Faild to start detecting current location")
            print(error)
        }
    }
    private func initLocation() {
        let loc = Point(latitude: initLat, longitude: initLng)
        dropPin(at: loc)
        viewpoint = Viewpoint(center: loc, scale: 1e3)
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
        Task {
            if let center = queryCenter {
                await getAddressFromPoint(point: center)
            }
        }
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
            if let address = geocodeResults.first?.attributes["LongLabel"] as? String {
                result.address = address
                print(address)
            }
        } catch {
            print(error)
        }
    }
    
    private func dropPin(at location: Point) {
        model.markerGraphic.geometry = location
    }
    
    @ViewBuilder
    private func SearchViewOverlay() -> some View {
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
            .keyboardAdaptive()
            .padding()
    }
    
    private class Model: ObservableObject {
        let map = Map(basemapStyle: .osmStandard)
        let searchResultsOverlay = GraphicsOverlay()
        let graphicsOverlay = GraphicsOverlay()
        let markerGraphic = Graphic(symbol: PictureMarkerSymbol(image: ImageProvider.loadImage(named: "marker")!))
        let locatorTask = LocatorTask(url: .geocodeServer)
        
        init() {
            graphicsOverlay.addGraphic(markerGraphic)
        }
    }
}

private extension URL {
    static var geocodeServer: URL {
        URL(string: "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer")!
    }
}

public class ImageProvider {
    public static func loadImage(named imageName: String) -> UIImage? {
        let bundle = Bundle.module
        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
    }
}

#Preview {
    ArcGisMapSearch(apiKey: APIKEY, initialLatitude: 30.043414, initialLongitude: 31.235338, result: .constant(ArcGisMapSearch.Result()))
}

