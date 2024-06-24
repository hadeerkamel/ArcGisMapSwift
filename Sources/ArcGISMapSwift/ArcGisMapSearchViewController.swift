//
//  File.swift
//  
//
//  Created by Hadeer on 6/13/24.
//

import UIKit
import SwiftUI

public class ArcGisMapSearchViewController: UIViewController {
   
    var initialLatitude: Double?
    var initialLongitude: Double?
    var didDismissed: (ArcGisMapSearch.Result)->Void
    
    public init( initialLatitude: Double?, initialLongitude: Double?, didDismissed: @escaping (ArcGisMapSearch.Result)->Void) {
        self.initialLatitude = initialLatitude
        self.initialLongitude = initialLongitude
        self.didDismissed = didDismissed
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let contentView = ArcGisMapSearchWithInfoView( initialLatitude: initialLatitude, initialLongitude: initialLongitude, didDismissed: didDismissed)
        let hostingController = UIHostingController(rootView: contentView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
        
    }
    
    static public func presentAsFullScreen(rootVC: UIViewController, initLat: Double?, initLng: Double?) async -> String {
           return await withCheckedContinuation { continuation in
               let vc = ArcGisMapSearchViewController(initialLatitude: initLat, initialLongitude: initLng) { result in
                   do {
                       let jsonData = try JSONEncoder().encode(result)
                       if let jsonString = String(data: jsonData, encoding: .utf8) {
                           print(jsonString)
                           continuation.resume(returning: jsonString)
                       }
                   } catch {
                       print("Error encoding JSON: \(error)")
                   }
                   
               }
               vc.modalPresentationStyle = .overFullScreen
               rootVC.present(vc, animated: true)
           }
       }
    
}

