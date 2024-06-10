//
//  ArcGisMapSearch.swift
//
//
//  Created by Hadeer on 6/6/24.
//

import SwiftUI

public struct ArcGisMapSearchWithInfoView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    //private var mapSearchView: ArcGisMapSearch
    @Binding var result: ArcGisMapSearch.Result
    @State var isRecenterCurrentLocation = false
    let apiKey_: String
    let initLat: Double?
    let initLng: Double?
    
    public init(apiKey: String, initialLatitude: Double?, initialLongitude: Double?, result: Binding<ArcGisMapSearch.Result> ) {
        apiKey_ = apiKey
        _result = result
        initLat = initialLatitude
        initLng = initialLongitude
        //mapSearchView = ArcGisMapSearch(apiKey: apiKey, initialLatitude: initialLatitude , initialLongitude: initialLongitude , result: result)
    }
    
    public var body: some View {
        ZStack(alignment: .bottom){
            
            ArcGisMapSearch(apiKey: apiKey_, initialLatitude: initLat , initialLongitude: initLng , result: $result, isRecenterCurrentLocation: $isRecenterCurrentLocation)
            Infoview(address: $result.address,
                     currentLocationTapped: {
                isRecenterCurrentLocation = true
            },
                     confirmTapped: {
                dismiss()
            }
            )
            
        }
    }
}

#Preview {
    ArcGisMapSearchWithInfoView(apiKey: APIKEY, initialLatitude: 30.043414, initialLongitude: 31.235338, result: .constant(ArcGisMapSearch.Result()))
}
