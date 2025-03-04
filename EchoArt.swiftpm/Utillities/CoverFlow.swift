//
//  CoverFlow.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/05.
//

import SwiftUI

struct CenteredItemPreferenceData<ID: Hashable>: Equatable {
    let id: ID
    let distance: CGFloat
}

struct CenteredItemPreferenceKey<ID: Hashable>: PreferenceKey {
    static var defaultValue: [CenteredItemPreferenceData<ID>] { [] }
    
    static func reduce(value: inout [CenteredItemPreferenceData<ID>], nextValue: () -> [CenteredItemPreferenceData<ID>]) {
        let newValues = value + nextValue()
        if let minValue = newValues.min(by: { $0.distance < $1.distance }) {
            value = [minValue]
        } else {
            value = []
        }
    }
}

struct CoverFlow<Content: View, Item: RandomAccessCollection>: View where Item.Element: Identifiable {
    var itemWidth: CGFloat
    var enableReflection: Bool = false
    var spacing: CGFloat = 0
    var rotation: Double
    var items: Item
    var content: (Item.Element) -> Content
    
    var onCenteredItemChange: ((Item.Element.ID?) -> Void)? = nil
    var onScrollStateChange: ((Bool) -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let effectiveItemWidth = min(itemWidth, size.width)
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                            .frame(width: effectiveItemWidth)
                            .reflection(enableReflection)
                            .background(
                                GeometryReader { itemProxy in
                                    let itemMidX = itemProxy.frame(in: .named("scroll")).midX
                                    let scrollCenterX = size.width / 2
                                    let distance = abs(itemMidX - scrollCenterX)
                                    Color.clear
                                        .preference(key: CenteredItemPreferenceKey<Item.Element.ID>.self,
                                                    value: [CenteredItemPreferenceData(id: item.id, distance: distance)])
                                }
                            )
                            .visualEffect { content, geometryProxy in
                                content
                                    .rotation3DEffect(
                                        .init(degrees: rotation(geometryProxy)),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .center
                                    )
                            }
                    }
                }
                .padding(.horizontal, (size.width - effectiveItemWidth) / 2)
                .scrollTargetLayout()
            }
            .coordinateSpace(name: "scroll")
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .onPreferenceChange(CenteredItemPreferenceKey<Item.Element.ID>.self) { preferences in
                let newId = preferences.first?.id
                DispatchQueue.main.async {
                    onCenteredItemChange?(newId)
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        onScrollStateChange?(true)
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onScrollStateChange?(false)
                        }
                    }
            )
        }
    }
    
    nonisolated func rotation(_ proxy: GeometryProxy) -> Double {
        let scrollViewWidth = proxy.bounds(of: .scrollView(axis: .horizontal))?.width ?? 0
        let midX = proxy.frame(in: .scrollView(axis: .horizontal)).midX
        let progress = midX / scrollViewWidth
        let cappedProgress = max(min(progress, 1), 0)
        let cappedRotation = max(min(rotation, 90), 0)
        let degree = cappedProgress * (cappedRotation * 2)
        return cappedRotation - degree
    }
}

fileprivate extension View {
    @ViewBuilder
    func reflection(_ added: Bool) -> some View {
        self
            .overlay {
                if added {
                    GeometryReader { geometry in
                        let size = geometry.size
                        self
                            .scaleEffect(y: -1)
                            .mask {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                .white,
                                                .white.opacity(0.7),
                                                .white.opacity(0.5),
                                                .white.opacity(0.3),
                                                .white.opacity(0.1),
                                                .white.opacity(0)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .offset(y: size.height + 5)
                            .opacity(0.5)
                            .allowsHitTesting(false)
                    }
                }
            }
    }
}

