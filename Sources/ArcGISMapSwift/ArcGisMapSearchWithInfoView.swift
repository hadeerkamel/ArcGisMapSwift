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
        ZStack(alignment: .topTrailing){
           
            ZStack(alignment: .bottom){
                
                ArcGisMapSearch(initialLatitude: initLat , initialLongitude: initLng , result: $result, isRecenterCurrentLocation: $isRecenterCurrentLocation)
                
                Infoview(country: $result.country,address: $result.address,
                         currentLocationTapped: {
                    print("----- Current Location info view clusure ------")
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
            
            
            Button{
               dismiss()
            }label: {
                VStack{
                    Image("left-arrow",bundle: .module)
                        .resizable()
                        .padding(2)
                    
                }
                .background(.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(width: 35, height: 35)
            }
            .padding(21)
        }
        
        
    }
}

#Preview {
    ArcGisMapSearchWithInfoView(initialLatitude: 30.043414, initialLongitude: 31.235338, didDismissed: {_ in })
}
