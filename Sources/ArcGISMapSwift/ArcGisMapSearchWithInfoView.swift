//
//  ArcGisMapSearch.swift
//
//
//  Created by Hadeer on 6/6/24.
//

import SwiftUI

public struct ArcGisMapSearchWithInfoView: View {
    
    @Environment(\.dismiss) private var dismiss

    @State var result: ArcGisMapSearch.Result = .init()
    @State var isRecenterCurrentLocation = false
   
    let initLat: Double?
    let initLng: Double?
    var didDismissed: (ArcGisMapSearch.Result)->Void
    
    public init(initialLatitude: Double?, initialLongitude: Double? , didDismissed: @escaping (ArcGisMapSearch.Result)->Void) {
      
        initLat = initialLatitude
        initLng = initialLongitude
        self.didDismissed = didDismissed
    }
    
    public var body: some View {
        
            ZStack(alignment: .bottom){
                
                ArcGisMapSearch(initialLatitude: initLat , initialLongitude: initLng , result: $result, isRecenterCurrentLocation: $isRecenterCurrentLocation)
                   
                Infoview(address: $result.address,
                         currentLocationTapped: {
                    isRecenterCurrentLocation = true
                },
                         confirmTapped: {
                    didDismissed(result)
                    dismiss()
                }
                    
                )
                .padding(.bottom)
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.keyboard)
          
     
        
        
    }
}

#Preview {
    ArcGisMapSearchWithInfoView(initialLatitude: 30.043414, initialLongitude: 31.235338, didDismissed: {_ in })
}
