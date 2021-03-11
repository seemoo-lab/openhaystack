//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI

struct IconSelectionView: View {

    @State var showImagePicker = false
    @Binding var selectedImageName: String
    @Binding var selectedColor: Color

    var body: some View {

        ZStack {
            Button(
                action: {
                    withAnimation {
                        self.showImagePicker.toggle()
                    }
                },
                label: {
                    Circle()
                        .strokeBorder(self.selectedColor, lineWidth: 2)
                        .background(
                            ZStack {
                                Circle().fill(Color("PinColor"))
                                Image(systemName: self.selectedImageName)
                                    .colorMultiply(Color("PinImageColor"))
                            }
                        )
                        .frame(width: 32, height: 32)
                }
            )
            .buttonStyle(PlainButtonStyle())
            .popover(
                isPresented: self.$showImagePicker,
                content: {
                    ImageSelectionList(selectedImageName: $selectedImageName, selectedColor: $selectedColor) {
                        self.showImagePicker = false
                    }
                })
        }
    }
}

struct ColorSelectionView_Previews: PreviewProvider {
    @State static var selectedImageName: String = "briefcase.fill"
    @State static var selectedColor: Color = .red

    static var previews: some View {
        Group {
            IconSelectionView(selectedImageName: self.$selectedImageName, selectedColor: self.$selectedColor)
            ImageSelectionList(selectedImageName: self.$selectedImageName, selectedColor: self.$selectedColor, dismiss: { () })
        }

    }
}

struct ImageSelectionList: View {
    @Binding var selectedImageName: String
    @Binding var selectedColor: Color
    static let boxSize: CGFloat = 30.0

    let dismiss: () -> Void

    let columns: [GridItem] = [
        GridItem(.fixed(boxSize), spacing: nil),
        GridItem(.fixed(boxSize), spacing: nil),
        GridItem(.fixed(boxSize), spacing: nil),
        GridItem(.fixed(boxSize), spacing: nil),
    ]

    var body: some View {
        VStack {
            ColorPicker(selection: $selectedColor, supportsOpacity: false) {
                Text("Pick a color")
                    .colorMultiply(Color("PinImageColor"))
            }
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: nil, pinnedViews: []) {
                    Section {
                        ForEach(Accessory.icons, id: \.self) { iconName in
                            Button(
                                action: {
                                    self.selectedImageName = iconName
                                    self.dismiss()
                                },
                                label: {
                                    Image(systemName: iconName)
                                        .colorMultiply(Color("PinImageColor"))
                                }
                            )
                            .frame(width: ImageSelectionList.boxSize, height: ImageSelectionList.boxSize, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
        .padding(ImageSelectionList.boxSize / 2)
    }
}
