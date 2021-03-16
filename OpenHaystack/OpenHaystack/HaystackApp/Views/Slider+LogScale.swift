//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI

extension Binding where Value == Double {
    func logarithmic(base: Double = 10.0) -> Binding<Double> {
        Binding(
            get: {
                logC(self.wrappedValue, forBase: base)
            },
            set: { (newValue) in
                self.wrappedValue = pow(base, newValue)
            })
    }
}

extension Slider {
    static func withLogScale(
        base: Double = 10.0,
        value: Binding<Double>,
        in inRange: ClosedRange<Double>,
        minimumValueLabel: ValueLabel = EmptyView() as! ValueLabel,
        maximumValueLabel: ValueLabel = EmptyView() as! ValueLabel,
        label: () -> Label = { EmptyView() as! Label },
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) -> Slider where Label: View, ValueLabel: View {
        return self.init(
            value: value.logarithmic(base: base),
            in: logC(inRange.lowerBound, forBase: base)...logC(inRange.upperBound, forBase: base),
            onEditingChanged: onEditingChanged, minimumValueLabel: minimumValueLabel,
            maximumValueLabel: maximumValueLabel,
            label: label)
    }
}

private func logC(_ value: Double, forBase base: Double) -> Double {
    return log(value) / log(base)
}
