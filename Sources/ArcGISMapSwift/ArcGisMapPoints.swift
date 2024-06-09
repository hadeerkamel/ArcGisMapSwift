//
//  ArcGisMapPoints.swift
//
//
//  Created by Hadeer on 6/9/24.
//

import SwiftUI
import ArcGIS

public struct ArcGisMapPoints: View {
    
    @StateObject private var viewModel: MapViewModel
    
    public init(points: [PointCoordinate]) {
        _viewModel = StateObject(wrappedValue: MapViewModel(points: points))
    }
    
    public var body: some View {
        MapView(map: viewModel.map, graphicsOverlays: [viewModel.graphicsOverlay])
            .onAppear {
                viewModel.updatePoints()
            }
    }
}

public struct PointCoordinate {
    let lat: Double
    let lng: Double
}

class MapViewModel: ObservableObject {
    @Published var points: [PointCoordinate]
    @Published var map: Map
    var graphicsOverlay: GraphicsOverlay
    
    init(points: [PointCoordinate]) {
        self.points = points
        self.map = Map(basemapStyle: .osmStandard)
        self.graphicsOverlay = GraphicsOverlay()
        self.map.initialViewpoint = Viewpoint(latitude: 30.078747, longitude: 31.203802, scale: 1e3)
        ArcGISEnvironment.apiKey = APIKey(APIKEY)
    }
    
    func updatePoints() {
        let points = self.points.map { Point(x: $0.lng, y: $0.lat, spatialReference: .wgs84) }
        graphicsOverlay.removeAllGraphics()
        var previousPoint: Point? = nil
        for p in points {
            addPoint(point: p)
            if let prev = previousPoint {
                addLine(p1: prev, p2: p)
            }
            previousPoint = p
        }
    }
    
    func addPoint(point: Point) {
        guard let markerImage = ImageProvider.loadImage(named: "marker") else { return }
        let markerSymbol = PictureMarkerSymbol(image: markerImage)
        let pointGraphic = Graphic(geometry: point, symbol: markerSymbol)
        graphicsOverlay.addGraphic(pointGraphic)
    }
    
    func addLine(p1: Point, p2: Point) {
        let polyline = Polyline(points: [p1, p2])
        let polylineSymbol = SimpleLineSymbol(style: .solid, color: .green, width: 10.0)
        let polylineGraphic = Graphic(geometry: polyline, symbol: polylineSymbol)
        graphicsOverlay.addGraphic(polylineGraphic)
    }
}

struct ArcGisMapPoints_Previews: PreviewProvider {
    static var previews: some View {
        ArcGisMapPoints(points: [
            PointCoordinate(lat: 30.078747, lng: 31.203802),
            PointCoordinate(lat: 30.078023, lng: 31.201780),
            PointCoordinate(lat: 30.080108, lng: 31.201958)
        ])
    }
}


//#Preview {
//    ArcGisMapPoints(points: .constant([PointCoordinate(lat: 30.078747, lng: 31.203802),
//                             PointCoordinate(lat: 30.078023, lng: 31.201780),
//                             PointCoordinate(lat: 30.080108, lng: 31.201958)]))
//}
