//
//  File.swift
//  
//
//  Created by Hadeer on 6/9/24.
//

import Foundation
import SwiftUI
import Combine

struct KeyboardAdaptive: ViewModifier {
    @State private var currentHeight: CGFloat = 0
    @State private var cancellable: AnyCancellable?

    func body(content: Content) -> some View {
        content
            .padding(.bottom, currentHeight)
            .onAppear {
                self.cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
                    .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
                    .compactMap { notification in
                        if notification.name == UIResponder.keyboardWillHideNotification {
                            return 0
                        }
                        return (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
                    }
                    .assign(to: \.currentHeight, on: self)
            }
            .onDisappear {
                self.cancellable?.cancel()
            }
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
    }
}
