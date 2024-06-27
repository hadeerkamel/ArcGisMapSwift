//
//  SwiftUIView.swift
//
//
//  Created by Hadeer on 6/6/24.
//

import SwiftUI

public struct Infoview: View {
    @Binding var country: String
    @Binding var address: String
    var currentLocationTapped: ()->Void
    var confirmTapped: ()->Void
   
    public var body: some View {
        VStack(alignment: .leading){
            Button{
                print("----- Current Location Tapped ------")
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
            
            HStack(alignment: .center){
                
//                if AGConfig.locale == "ar" {
//                    Spacer()
//                    
//                }
                if AGConfig.locale == "en" {
                    Image("location", bundle: .module)
                        .foregroundColor(Color("mainColor", bundle: .module))
                        .padding(.leading)
                }
                
                VStack(alignment: AGConfig.locale == "en" ? .leading : .trailing){
                    
                    Text(country)
                        .padding(0)
                        .padding(.top, 5)
                        .font(.headline)
                    Text(address)
                        .padding(0)
                        .padding(.bottom, 5)
                }
                if AGConfig.locale == "ar" {
                    Image("location", bundle: .module)
                        .foregroundColor(Color("mainColor", bundle: .module))
                        .padding(.trailing)
                }
               // if AGConfig.locale == "en" {
                    Spacer()
                //}
            }
            
            .frame(maxWidth: .infinity)
            //.frame(height: 100)
            .background(.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.leading, 20)
            .padding(.trailing, 20)
            
            Button{
                confirmTapped()
            }label: {
                VStack{
                    Text(AGConfig.locale == "en" ? "Confirm Location" : "تأكيد الموقع" )
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
        
    //    .background(Color.red)
    }
}

//#Preview {
//
//    Infoview(country: .constant(""),address: .constant(""), currentLocationTapped: {}, confirmTapped: {})
//}
