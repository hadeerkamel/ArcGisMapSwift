//
//  ArcGisMapSearch.swift
//
//
//  Created by Hadeer on 6/6/24.
//

import SwiftUI

public struct ArcGisMapSearch: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var result: SearchWithGeocodeView.Result = SearchWithGeocodeView.Result()
    
    public var body: some View {
        ZStack(alignment: .bottom){
            SearchWithGeocodeView(apiKey: APIKEY, initialLatitude: 30.043414, initialLongitude: 31.235338, result: $result)
            Infoview(address: $result.address, currentLocationTapped: {}, confirmTapped: {
                dismiss()
            })
        }
    }
}

#Preview {
    ArcGisMapSearch()
}
