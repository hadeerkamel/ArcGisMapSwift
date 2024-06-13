//
//  ArcGisMapPoints.swift
//
//
//  Created by Hadeer on 6/9/24.
//

import SwiftUI
import ArcGIS
import CoreLocation

public struct ArcGisMapPoints: View {
    
    @StateObject private var viewModel: MapViewModel
    @Binding var points: [PointCoordinate]
    
    public init(points: Binding<[PointCoordinate]>) {
        _points = points
        _viewModel = StateObject(wrappedValue: MapViewModel(points: []))
    }
    
    public var body: some View {
        ZStack(alignment: .bottomLeading){
            MapViewReader { proxy in
                MapView(map: viewModel.map, graphicsOverlays: [viewModel.graphicsOverlay, viewModel.deviceLocationGraphicsOverlay])
                    .onAppear {
                        viewModel.points = points
                        viewModel.updatePoints()
                        viewModel.startLocationDataSource()
                    }
                    .onChange_(of: $points) { oldValue, newValue in
                        viewModel.points = points
                        viewModel.updatePoints()
                    }
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
                .padding(.leading, 15)
                .padding(.bottom, 15)
            }
        }
    }
}

public struct PointCoordinate: Equatable {
    let lat: Double
    let lng: Double
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
            
            self.map.initialViewpoint = Viewpoint(center: p, scale: 1e3)
            
            guard let markerImage = UIImage(named: "current_location_indicator", in: .module, with: nil) else { return }
            let markerSymbol = PictureMarkerSymbol(image: markerImage)
            let pointGraphic = Graphic(geometry: p, symbol: markerSymbol)
            deviceLocationGraphicsOverlay.addGraphic(pointGraphic)
        }
    }
     func recenterDeviceLocation(proxy: MapViewProxy) async{
           guard let loc = deviceLocationPoint else { return }
           
         await proxy.setViewpoint(map.initialViewpoint!, duration: 0.5)
    }
    
   
    
    func updatePoints() {
        let points = self.points.map { Point(x: $0.lng, y: $0.lat, spatialReference: .wgs84) }
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
    }
    
    func addPoint(point: Point) {
        guard let markerImage = UIImage(named: "marker", in: .module, with: nil) else { return }
        let markerSymbol = PictureMarkerSymbol(image: markerImage)
        let pointGraphic = Graphic(geometry: point, symbol: markerSymbol)
        graphicsOverlay.addGraphic(pointGraphic)
    }
    
    func addLine(p1: Point, p2: Point) {
        let polyline = Polyline(points: [p1, p2])
        let polylineSymbol = SimpleLineSymbol(style: .solid, color: UIColor(Color("mainColor", bundle: .module)), width: 10.0)
        let polylineGraphic = Graphic(geometry: polyline, symbol: polylineSymbol)
        graphicsOverlay.addGraphic(polylineGraphic)
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
//                             PointCoordinate(lat: 30.078023, lng: 31.201780),
//                             PointCoordinate(lat: 30.080108, lng: 31.201958)]))
//}
