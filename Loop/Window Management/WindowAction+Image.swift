//
//  WindowAction+Image.swift
//  Loop
//
//  Created by phlpsong on 2024/3/30.
//

import Luminare
import SwiftUI

extension WindowAction {
    var icon: Image? {
        switch direction {
        case .undo:
            Image(systemName: "arrow.uturn.backward")
        case .initialFrame:
            Image(systemName: "backward.end.alt.fill")
        case .hide:
            Image(systemName: "eye.slash.fill")
        case .minimize:
            Image(systemName: "arrow.down.right.and.arrow.up.left")
        case .maximizeHeight:
            Image(systemName: "arrow.up.and.down")
        case .maximizeWidth:
            Image(systemName: "arrow.left.and.right")
        case .nextScreen:
            Image(systemName: "forward.fill")
        case .previousScreen:
            Image(systemName: "backward.fill")
        case .larger:
            Image(systemName: "arrow.up.left.and.arrow.down.right")
        case .smaller:
            Image(systemName: "arrow.down.right.and.arrow.up.left")
        case .shrinkTop, .growBottom, .moveDown:
            Image(systemName: "arrow.down")
        case .shrinkBottom, .growTop, .moveUp:
            Image(systemName: "arrow.up")
        case .shrinkRight, .growLeft, .moveLeft:
            Image(systemName: "arrow.left")
        case .shrinkLeft, .growRight, .moveRight:
            Image(systemName: "arrow.right")
        default:
            nil
        }
    }

    var radialMenuImage: Image? {
        switch direction {
        case .hide:
            Image(systemName: "eye.slash")
        case .minimize:
            Image(systemName: "arrow.down.right.and.arrow.up.left")
        default:
            nil
        }
    }
}

struct IconView: View {
    let action: WindowAction

    @State private var frame: CGRect = .init(x: 0, y: 0, width: 1, height: 1)

    private let size = CGSize(width: 14, height: 10)
    private let inset: CGFloat = 2
    private let outerCornerRadius: CGFloat = 3

    var body: some View {
        if action.direction == .cycle, let first = action.cycle?.first {
            IconView(action: first)
                .id(first.id)
                .animation(LuminareConstants.fastAnimation, value: first)
        } else {
            ZStack {
                if frame.size.area != 0 {
                    ZStack {
                        RoundedRectangle(cornerRadius: outerCornerRadius - inset)
                            .frame(
                                width: frame.width,
                                height: frame.height
                            )
                            .offset(
                                x: frame.origin.x,
                                y: frame.origin.y
                            )
                    }
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                    .onAppear {
                        refreshFrame()
                    }
                    .onChange(of: action) { _ in
                        withAnimation(LuminareConstants.fastAnimation) {
                            refreshFrame()
                        }
                    }
                } else {
                    Group {
                        if let icon = action.icon {
                            icon
                                .font(.system(size: 8))
                                .fontWeight(.bold)
                        } else if action.direction == .cycle {
                            Image(._18PxRepeat4)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(._18PxRuler)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .frame(width: size.width, height: size.height)
                }
            }
            .clipShape(.rect(cornerRadius: outerCornerRadius - inset))
            .background {
                RoundedRectangle(cornerRadius: outerCornerRadius)
                    .stroke(lineWidth: 1)
                    .padding(-inset)
            }
            .padding(.horizontal, 4)
        }
    }

    func refreshFrame() {
        frame = action.getFrame(window: nil, bounds: .init(origin: .zero, size: size), disablePadding: true)
    }
}
