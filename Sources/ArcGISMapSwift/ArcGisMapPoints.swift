//
//  ArcGisMapPoints.swift
//
//
//  Created by Hadeer on 6/9/24.
//

import SwiftUI
import ArcGIS
import CoreLocation
import ArcGISToolkit

public struct ArcGisMapPoints: View {
    
    @State private var identifyScreenPoint: CGPoint?
    @State private var identifyTapLocation: Point?
    @State private var calloutPlacement: CalloutPlacement?
    
    @StateObject private var viewModel: MapViewModel
    @Binding var points: [PointCoordinate]
    @State var scale = 1e4
    public init(points: Binding<[PointCoordinate]>) {
        _points = points
        _viewModel = StateObject(wrappedValue: MapViewModel(points: []))
    }
    
    public var body: some View {
        ZStack(alignment: .bottomLeading){
            MapViewReader { proxy in
                MapView(map: viewModel.map, graphicsOverlays: [viewModel.graphicsOverlay, viewModel.deviceLocationGraphicsOverlay])
                
                    .callout(placement: $calloutPlacement.animation()) { placement in
                        Text(viewModel.addresses[ placement.geoElement?.geometry as? Point  ] ?? "")
                            .padding(10)
                    }
                    .onSingleTapGesture { screenPoint, mapPoint in
                        identifyScreenPoint = screenPoint
                        identifyTapLocation = mapPoint
                        Task {
                            await performIdentify(proxy: proxy)
                        }
                    }
                
                
                    
                    .onChange_(of: $points) { oldValue, newValue in
                        viewModel.points = points
                        viewModel.updatePoints()
                    }
                    .onAppear {
                        viewModel.points = points
                        viewModel.updatePoints()
                        viewModel.startLocationDataSource()
                    }
                HStack{
                    Button{
                        Task{
                            await viewModel.recenterDeviceLocation(proxy: proxy)
                        }
                    }label: {
                        Image(uiImage: UIImage(named: "myLocation", in: .module, with: nil) ?? UIImage())
                            .resizable()
                            .tint(Color("mainColor", bundle: .module))
                            .padding(5)
                            .frame(width: 40, height: 40)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    
                    Spacer()
                    VStack(spacing: 0){
                        Button{
                            Task{
                                scale -= 1000
                                await proxy.setViewpointScale(scale)
                            }
                        }label: {
                            Text("+")
                                .foregroundStyle(Color.black.opacity(0.7))
                                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        }
                        .frame(width: 40,height: 40)
                        .background(Color.white.opacity(0.8))
                        .border(Color.black.opacity(0.3),width: 0.4)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        
                        
                        Button{
                            Task{
                                scale += 1000
                                await proxy.setViewpointScale(scale)
                            }
                        }label: {
                            Text("-")
                                .foregroundStyle(Color.black.opacity(0.7))
                                .font(.title)
                        }
                        .frame(width: 40,height: 40)
                        .background(Color.white.opacity(0.8))
                        .border(Color.black.opacity(0.3),width: 0.4)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        
                    }
                }
                
                .padding( 15)
            }
        }
        
    }
    private func performIdentify(proxy: MapViewProxy) async {
        guard let screenPoint = identifyScreenPoint,
              let identifyResult = try? await proxy.identify(on: viewModel.graphicsOverlay, screenPoint: screenPoint, tolerance: 10) else { return }
        
        calloutPlacement = identifyResult.graphics.first.flatMap {
            CalloutPlacement.geoElement($0, tapLocation: identifyTapLocation)
        }
        identifyScreenPoint = nil
        identifyTapLocation = nil
    }
}

public struct PointCoordinate: Equatable {
    public let lat: Double
    public let lng: Double
    public init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
}

class MapViewModel: ObservableObject {
    @Published var points: [PointCoordinate]
    @Published var map: Map
    var graphicsOverlay: GraphicsOverlay
    var deviceLocationGraphicsOverlay: GraphicsOverlay
    let locationManager: CLLocationManager
    var deviceLocationPoint: Point? = nil
    var addresses: [Point?: String] = [:]
    
    init(points: [PointCoordinate]) {
        self.points = points
        self.map = Map(basemapStyle: .osmStandard)
        self.graphicsOverlay = GraphicsOverlay()
        self.deviceLocationGraphicsOverlay = GraphicsOverlay()
        locationManager = CLLocationManager()
        
        ArcGISEnvironment.apiKey = APIKey(APIKEY)
        
    }
    
    
    func startLocationDataSource() {
        
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation()
        if let location = locationManager.location{
            let point = Point(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            deviceLocationPoint = point
            
            initMapOnCurrentLocation()
        }
    }
    private func initMapOnCurrentLocation(){
        
        if let p = deviceLocationPoint{
            
            //self.map.initialViewpoint = Viewpoint(center: p, scale: 1e4)
            
            guard let markerImage = UIImage(named: "current_location_indicator", in: .module, with: nil) else { return }
            let markerSymbol = PictureMarkerSymbol(image: markerImage)
            let pointGraphic = Graphic(geometry: p, symbol: markerSymbol)
            deviceLocationGraphicsOverlay.addGraphic(pointGraphic)
        }
    }
    func recenterDeviceLocation(proxy: MapViewProxy) async{
        print("Current location button tapped")
        guard let loc = deviceLocationPoint else {
            print("can't find current location")
            return
        }
        print("Current location is: \(loc)")
        let viewpoint = Viewpoint(center: loc, scale: 1e4)
        await proxy.setViewpoint(viewpoint, duration: 0.5)
    }
    
    
    
    func updatePoints() {
        print("----Package-Update points func-RecievedPoints---\(points.count)")
        let points = self.points.map { Point(x: $0.lng, y: $0.lat, spatialReference: .wgs84) }
        if let lastPoints = points.last{
            self.map.initialViewpoint = Viewpoint(center: lastPoints, scale: 1e4)
        }
        graphicsOverlay.removeAllGraphics()
        var previousPoint: Point? = nil
        for p in points {
            
            if let prev = previousPoint {
                addLine(p1: prev, p2: p)
                addPoint(point: prev)
            }
            if p == points.last {
                addPoint(point: p)
            }
            
            previousPoint = p
        }
        //print("----Package-Update points func-RecievedPoints---\(points.count)")
    }
    
    func addPoint(point: Point) {
        guard let markerImage = UIImage(named: "marker", in: .module, with: nil) else { return }
        let markerSymbol = PictureMarkerSymbol(image: markerImage)
        let pointGraphic = Graphic(geometry: point, symbol: markerSymbol)
        graphicsOverlay.addGraphic(pointGraphic)
        fetchAddress(for: point)
    }
    
    func addLine(p1: Point, p2: Point) {
        let polyline = Polyline(points: [p1, p2])
        let polylineSymbol = SimpleLineSymbol(style: .solid, color: UIColor(Color("mainColor", bundle: .module)), width: 10.0)
        let polylineGraphic = Graphic(geometry: polyline, symbol: polylineSymbol)
        graphicsOverlay.addGraphic(polylineGraphic)
    }
    private func fetchAddress(for point: Point) {
        let location = CLLocation(latitude: point.y, longitude: point.x)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, error == nil, let placemark = placemarks?.first else { return }
            let address = [
                placemark.name,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }.joined(separator: ", ")
            self.addresses[point] = address
        }
    }
}

struct ArcGisMapPoints_Previews: PreviewProvider {
    static var previews: some View {
        ArcGisMapPoints(points: .constant([
            PointCoordinate(lat: 30.078747, lng: 31.203802),
            PointCoordinate(lat: 30.078023, lng: 31.201780),
            PointCoordinate(lat: 30.080108, lng: 31.201958)
        ]))
    }
}


//#Preview {
//    ArcGisMapPoints(points: .constant([PointCoordinate(lat: 30.078747, lng: 31.203802),
//                                       PointCoordinate(lat: 30.078023, lng: 31.201780),
//                                       PointCoordinate(lat: 30.080108, lng: 31.201958)]))
//}
