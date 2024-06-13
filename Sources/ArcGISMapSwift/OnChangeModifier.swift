//
//  OnChangeVersionDependency.swift
//  sss
//
//  Created by Hadeer on 6/13/24.
//

import SwiftUI

struct OnChangeModifier<T: Equatable>: ViewModifier {
    @Binding var value: T
    let action: (T, T) -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content.onChange(of: value) { oldValue, newValue in
                action(value, newValue)
            }
        } else {
            content.onChange(of: value) { newValue in
                action(value, newValue)
            }
        }
    }
}

extension View {
    func onChange_<T: Equatable>(
        of value: Binding<T>,
        perform action: @escaping (T, T) -> Void
    ) -> some View {
        self.modifier(OnChangeModifier(value: value, action: action))
    }
}
