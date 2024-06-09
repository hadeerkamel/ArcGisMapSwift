//
//  SwiftUIView.swift
//  
//
//  Created by Hadeer on 6/6/24.
//

import SwiftUI

public struct Infoview: View {
    @Binding var address: String
    var currentLocationTapped: ()->Void
    var confirmTapped: ()->Void
   
    public var body: some View {
        VStack(alignment: .leading){
            Button{
                currentLocationTapped()
            }label: {
                Image(uiImage: ImageProvider.loadImage(named: "marker") ?? UIImage())
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            .padding(.leading, 20)
            .padding(.bottom, 10)
            
            
            VStack(){
                Text(address)
                    .padding(20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.leading, 20)
            .padding(.trailing, 20)
            
            Button{
                confirmTapped()
            }label: {
                VStack{
                    Text("Confirm Location")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.green)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 10)
            }
            
        }
        .frame(maxWidth: .infinity)
    }
}

//#Preview {
//    @State var address = "x"
//    Infoview(address: $address, currentLocationTapped: {}, confirmTapped: {})
//}
