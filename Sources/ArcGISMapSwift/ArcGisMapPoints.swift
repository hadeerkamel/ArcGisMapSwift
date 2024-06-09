//
//  ArcGisMapPoints.swift
//
//
//  Created by Hadeer on 6/9/24.
//

import SwiftUI
import ArcGIS
public struct PointCoordinate{
    let lat: Double
    let lng: Double
    public init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
}


public struct ArcGisMapPoints: View {
    
    @StateObject private var model = Model()
    @Binding var points: [PointCoordinate]
        
        public init(points: Binding<[PointCoordinate]>) {
            self._points = points
        }
    public var body: some View {
        
        MapView(map: model.map, graphicsOverlays: [model.graphicsOverlay])
            .onAppear(){
                model.updatePoints(with: points)
            }
    }
    
}

private class Model: ObservableObject {
    @Published var points: [Point] = []
    @State var map: Map = {
           let map = Map(basemapStyle: .osmStandard)
           map.initialViewpoint = Viewpoint(latitude: 30.078747, longitude: 31.203802, scale: 1e3)
           return map
    }()
    let graphicsOverlay: GraphicsOverlay = {
        let graphicsOverlay = GraphicsOverlay()
        
        return graphicsOverlay

    }()
    init() {
        ArcGISEnvironment.apiKey = APIKey(APIKEY)
    }
    func updatePoints(with coordinates: [PointCoordinate]) {
            points = coordinates.map { Point(x: $0.lng, y: $0.lat, spatialReference: .wgs84) }
            drawPolyLine()
    }
    func drawPolyLine(){
       
        var perviousPoint: Point? = nil
        for p in points {
            if let prev = perviousPoint{
                addLine(p1: prev, p2: p)
                addPoint(point: prev)
                if(p == points.last){
                    addPoint(point: p)
                }
            }
            
            perviousPoint = p
        }
        
    }
    func addPoint(point: Point){
        
        guard let markerImage = ImageProvider.loadImage(named: "marker") else{return}
        
        let markerSymbol = PictureMarkerSymbol(image: markerImage)
        
        let pointGraphic = Graphic(geometry: point, symbol: markerSymbol)

        graphicsOverlay.addGraphic(pointGraphic)
    }
    func addLine(p1:Point,p2:Point){
        let polyline = Polyline(points: [p1,p2])
        let polylineSymbol = SimpleLineSymbol(style: .solid, color: .green, width: 10.0)
        let polylineGraphic = Graphic(geometry: polyline, symbol: polylineSymbol)

        graphicsOverlay.addGraphic(polylineGraphic)
    }
}

#Preview {
    ArcGisMapPoints(points: .constant([PointCoordinate(lat: 30.078747, lng: 31.203802),
                             PointCoordinate(lat: 30.078023, lng: 31.201780),
                             PointCoordinate(lat: 30.080108, lng: 31.201958)]))
}
