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
                Image(uiImage: UIImage(named: "myLocation", in: .module, with: nil) ?? UIImage())
                    .resizable()
                    .tint(Color("mainColor", bundle: .module))
                    .padding(5)
                    .frame(width: 40, height: 40)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    Text(NSLocalizedString("Confirm Location", comment: ""))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color("mainColor", bundle: .module))
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
//
//    Infoview(address: .constant(""), currentLocationTapped: {}, confirmTapped: {})
//}
