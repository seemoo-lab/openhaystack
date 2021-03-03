//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only

import SwiftUI

struct IconSelectionView: View {

    @State var showImagePicker = false
    @State var color: Color = .red
    @Binding var selectedImageName: String

    var body: some View {

        ZStack {
            Button(action: {
                withAnimation {
                    self.showImagePicker.toggle()
                }
            }, label: {
                Circle()
                    .strokeBorder(Color.gray, lineWidth: 0.5)
                    .background(
                        Image(systemName: self.selectedImageName)
                    )
                    .frame(width: 30, height: 30)
            })
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: self.$showImagePicker, content: {
                ImageSelectionList(selectedImageName: self.$selectedImageName) {
                    self.showImagePicker = false
                }
            })
        }
    }
}

struct ColorSelectionView_Previews: PreviewProvider {
    @State static var selectedImageName: String = "briefcase.fill"

    static var previews: some View {
        Group {
            IconSelectionView(selectedImageName: self.$selectedImageName)
            ImageSelectionList(selectedImageName: self.$selectedImageName, dismiss: {})
        }

    }
}

struct ImageSelectionList: View {
    let selectableIcons = ["briefcase.fill", "case.fill", "latch.2.case.fill", "key.fill", "mappin", "crown.fill", "gift.fill", "car.fill"]

    @Binding var selectedImageName: String

    let dismiss: () -> Void

    var body: some View {
        List(self.selectableIcons, id: \.self) { iconName in
            Button(action: {
                self.selectedImageName = iconName
                self.dismiss()
            }, label: {
                HStack {
                   Spacer()
                    Image(systemName: iconName)
                    Spacer()
                }
            })
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
        }
        .frame(width: 100)
    }

}
