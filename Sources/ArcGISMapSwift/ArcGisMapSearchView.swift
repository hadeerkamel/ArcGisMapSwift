//
//  ArcGisMapSearch.swift
//
//
//  Created by Hadeer on 6/6/24.
//

import SwiftUI

public struct ArcGisMapSearch: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var result: SearchWithGeocodeView.Result
    let apiKey: String
    let initialLatitude: Double
    let initialLongitude: Double
    
    public init(apiKey: String, initialLatitude: Double, initialLongitude: Double, result: Binding<SearchWithGeocodeView.Result> ) {
        self.apiKey = apiKey
        _result = result
        self.initialLatitude = initialLatitude
        self.initialLongitude = initialLongitude
    }
    
    public var body: some View {
        ZStack(alignment: .bottom){
            SearchWithGeocodeView(apiKey: apiKey, initialLatitude: initialLatitude , initialLongitude: initialLongitude , result: $result)
            Infoview(address: $result.address, currentLocationTapped: {}, confirmTapped: {
                dismiss()
            })
        }
    }
}

#Preview {
    ArcGisMapSearch(apiKey: APIKEY, initialLatitude: 30.043414, initialLongitude: 31.235338, result: .constant(SearchWithGeocodeView.Result()))
}
