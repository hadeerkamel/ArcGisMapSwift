//
//  File.swift
//  
//
//  Created by Hadeer on 6/13/24.
//

import UIKit
import SwiftUI

class ArcGisMapSearchViewController: UIViewController {
   
    var initialLatitude: Double?
    var initialLongitude: Double?
    var didDismissed: (ArcGisMapSearch.Result)->Void
    
    init( initialLatitude: Double?, initialLongitude: Double?, didDismissed: @escaping (ArcGisMapSearch.Result)->Void) {
        self.initialLatitude = initialLatitude
        self.initialLongitude = initialLongitude
        self.didDismissed = didDismissed
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let contentView = ArcGisMapSearchWithInfoView( initialLatitude: initialLatitude, initialLongitude: initialLongitude, didDismissed: didDismissed)
        let hostingController = UIHostingController(rootView: contentView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
        
    }
}

