//
//  ArcGisMapSearch.swift
//
//
//  Created by Hadeer on 6/6/24.
//

import SwiftUI

public struct ArcGisMapSearchWithInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var result: SearchWithGeocodeView.Result
    let apiKey: String
    let initLat: Double
    let initLng: Double
    
    public init(apiKey: String, initialLatitude: Double, initialLongitude: Double, result: Binding<SearchWithGeocodeView.Result> ) {
        self.apiKey = apiKey
        _result = result
        initLat = initialLatitude
        initLng = initialLongitude
    }
    
    public var body: some View {
        ZStack(alignment: .bottom){
            SearchWithGeocodeView(apiKey: apiKey, initialLatitude: initLat , initialLongitude: initLng , result: $result)
            
            Infoview(address: $result.address, currentLocationTapped: {}, confirmTapped: {
                dismiss()
            })
        }
    }
}

#Preview {
    ArcGisMapSearchWithInfoView(apiKey: APIKEY, initialLatitude: 30.043414, initialLongitude: 31.235338, result: .constant(SearchWithGeocodeView.Result()))
}
