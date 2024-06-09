//
//  ArcGISMapView.swift
//
//
//  Created by Hadeer on 6/5/24.
//


import SwiftUI
import ArcGIS
import ArcGISToolkit
let APIKEY = "AAPK02c4162a6c244595b0564d86007d14b9Wvyt7aoPDLSmphsm2gwYsNv3ov6GmtsaqObChcDJx0YGTThOj2FwZ8xQQatIp3ds"
public struct SearchWithGeocodeView: View {
    /// The viewpoint used by the search view to pan/zoom the map to the extent
    /// of the search results.
    @State private var viewpoint: Viewpoint? = Viewpoint(
        center: Point(
            x: -93.258133,
            y: 44.986656,
            spatialReference: .wgs84
        ),
        scale: 1e3
    )
    
    /// Denotes whether the map view is navigating. Used for the repeat search
    /// behavior.
    @State private var isGeoViewNavigating = false
    
    /// The current map view extent. Used to allow repeat searches after
    /// panning/zooming the map.
    @State private var geoViewExtent: Envelope?
    
    /// The center for the search.
    @State private var queryCenter: Point?
    
    /// The screen point to perform an identify operation.
    @State private var identifyScreenPoint: CGPoint?
    
    /// The tap location to perform an identify operation.
    @State private var identifyTapLocation: Point?
    
    /// The placement for a graphic callout.
    @State private var calloutPlacement: CalloutPlacement?
    
    /// Provides search behavior customization.
    @ObservedObject private var locatorDataSource = LocatorSearchSource(
        name: "My Locator",
        maximumResults: 10,
        maximumSuggestions: 5
    )
    
    /// The view model for the sample.
    @StateObject private var model = Model()
    private var initLat: Double
    private var initLng: Double
   
    public struct Result{
        var address: String = ""
        var latitude: Double = 0.0
        var longitude: Double = 0.0
    }
    @Binding var result: Result
    
    
    public init(apiKey: String, initialLatitude: Double, initialLongitude: Double, result: Binding<Result> ) {
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
            .onSingleTapGesture { screenPoint, tapLocation in
                identifyScreenPoint = screenPoint
                identifyTapLocation = tapLocation
                dropPin(at: tapLocation)
                Task{
                    await getAddressFromPoint(point: tapLocation)
                }
            }
            .onNavigatingChanged { isGeoViewNavigating = $0 }
            .onViewpointChanged(kind: .centerAndScale) {
                queryCenter = $0.targetGeometry.extent.center
                
                let latitude = CoordinateFormatter.latitudeLongitudeString(from: queryCenter!, format: .decimalDegrees, decimalPlaces: 6)
                print(latitude)
                Task{
                    if let center = queryCenter{
                        await getAddressFromPoint(point: center)
                    }
                }
                //print(longitude)
            }
            .onVisibleAreaChanged { newVisibleArea in
                // For "Repeat Search Here" behavior, use `geoViewExtent` and
                // `isGeoViewNavigating` modifiers on the search view.
                geoViewExtent = newVisibleArea.extent
            }
            .callout(placement: $calloutPlacement.animation()) { placement in
                // Show the address of user tapped location graphic.
                // To get the fully geocoded address, use "Place_addr".
                Text(placement.geoElement?.attributes["Match_addr"] as? String ?? "Unknown Address")
                    .padding()
            }
            .task(id: identifyScreenPoint) {
                
                guard let screenPoint = identifyScreenPoint,
                      // Identifies when user taps a graphic.
                      let identifyResult = try? await proxy.identify(
                        on: model.searchResultsOverlay,
                        screenPoint: screenPoint,
                        tolerance: 10
                      )
                        
                else {
                    return
                }
                
                
                // Creates a callout placement at the user tapped location.
                calloutPlacement = identifyResult.graphics.first.flatMap { graphic in
                    CalloutPlacement.geoElement(graphic, tapLocation: identifyTapLocation)
                }
                identifyScreenPoint = nil
                identifyTapLocation = nil
            }
            .overlay {
                SearchView(
                    sources: [locatorDataSource],
                    viewpoint: $viewpoint
                )
                .resultsOverlay(model.searchResultsOverlay)
                .queryCenter($queryCenter)
                .geoViewExtent($geoViewExtent)
                .isGeoViewNavigating($isGeoViewNavigating)
                .onQueryChanged { query in
                    if query.isEmpty {
                        // Hides the callout when query is cleared.
                        calloutPlacement = nil
                    }
                }
                .padding()
            }
            
        }
        .onAppear(){
            initLocation()
        }
    }
    func initLocation(){
        let loc = Point(latitude: initLat, longitude: initLng)
        dropPin(at: loc)
        viewpoint = Viewpoint(center: loc, scale: 1e3)
    }
    func getAddressFromPoint(point: Point) async {

        
        // Create parameters for reverse geocode
        let params = ReverseGeocodeParameters()
        params.maxResults = 1
        
        // Perform reverse geocode
        guard let normalizedPoint = GeometryEngine.normalizeCentralMeridian(
            of: point
        ) as? Point else { return }
        
        do {
            // Perform reverse geocode using the locator task with the point and parameters.
            let geocodeResults = try await model.locatorTask.reverseGeocode(
                forLocation: normalizedPoint,
                parameters: params
            )
            
            // Update the callout text using the first result from the reverse geocode.
            let address = geocodeResults.first?.attributes["LongLabel"] as? String
            result.address = address ?? ""
            print(address)
        } catch {
            print(error)
            
        }
        
        
    }
    private func dropPin(at location: Point) {
        model.markerGraphic.geometry = location
    }
    
    
    
    
}

private extension SearchWithGeocodeView {
    /// The model used to store the geo model and other expensive objects
    /// used in this view.
    class Model: ObservableObject {
        /// A map with imagery basemap.
        let map = Map(basemapStyle: .osmStandard)
        
        /// The graphics overlay used by the search toolkit component to display
        /// search results on the map.
        let searchResultsOverlay = GraphicsOverlay()
        
        let graphicsOverlay = GraphicsOverlay()
        //let markerImage:UIImage
        /// The red map marker graphic used to indicate a tap location on the map.
        let markerGraphic = {
            // Create a symbol using the image from the project assets.
            guard let markerImage = ImageProvider.loadImage(named: "marker") else{return Graphic()}
            //let markerSymbol = SimpleMarkerSymbol(style: .circle, color: .red)
            let markerSymbol = PictureMarkerSymbol(image: markerImage)
            // Change the symbol's offsets, so it aligns properly to a given point.
           // markerSymbol.leaderOffsetY = markerImage.size.height / 2
           // markerSymbol.offsetY = markerImage.size.height / 2
            
            // Create a graphic with the symbol.
            return Graphic(symbol: markerSymbol)
        }()
        
        /// The locator task for reverse geocoding.
        let locatorTask = LocatorTask(url: .geocodeServer)
    
        
        init() {
            graphicsOverlay.addGraphic(markerGraphic)
          //  self.markerImage = markerImage
        }
    }
}
private extension URL {
    /// A URL to a geocode server on ArcGIS Online.
    static var geocodeServer: URL {
        URL(string: "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer")!
    }
}

#Preview {
    SearchWithGeocodeView(
        apiKey: APIKEY,
        initialLatitude: 30.043414,
        initialLongitude: 31.235338, result: .constant(SearchWithGeocodeView.Result()))
}


public class ImageProvider {
    public static func loadImage(named imageName: String) -> UIImage? {
        let bundle = Bundle.module
        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
    }
}
