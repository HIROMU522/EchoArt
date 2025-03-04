//
//  FloatingButton.swift
//  EchoArt
//
//  Created by 田中大夢 on 2025/02/07.
//

import SwiftUI

struct FloatingButton<Label: View>: View{
    
    var buttonSize: CGFloat
    var actions: [FloatingAction]
    var label: (Bool) -> Label
    init(buttonSize: CGFloat = 50, @FloatingActionBuilder actions: @escaping () -> [FloatingAction],  @ViewBuilder label: @escaping (Bool) -> Label) {
        self.buttonSize = buttonSize
        self.actions = actions()
        self.label = label
    }
    @State private var isExpanded: Bool = false
    @State private var dragLocation: CGPoint = .zero
    @State private var selectedAction: FloatingAction?
    @GestureState private var isDragging: Bool = false
    var body: some View{
        Button{
            isExpanded.toggle()
        }label: {
            label(isExpanded)
                .frame(width: buttonSize, height: buttonSize)
                .contentShape(.rect)
        }
        .buttonStyle(NoAnimationButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.3)
                .onEnded{ _ in
                    isExpanded = true
                }.sequenced(before: DragGesture().updating($isDragging, body: {_, out, _ in
                    out = true
                }).onChanged{ value in
                    guard isExpanded else { return }
                    dragLocation = value.location
                }.onEnded{ _ in
                    Task{
                        if let selectedAction {
                            isExpanded = false
                            selectedAction.action()
                        }
                        
                        selectedAction = nil
                        dragLocation = .zero
                    }

                })
        )
        .background{
            ZStack{
                ForEach(actions) { action in
                    ActionView(action)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
        }
        .coordinateSpace(.named("CustomFloatingSpace"))
        .animation(.snappy(duration: 0.4, extraBounce: 0),value: isExpanded)
    }
    
    @ViewBuilder
    func ActionView(_ action: FloatingAction) -> some View{
        Button{
            action.action()
            isExpanded = false
        }label:{
            Image(systemName: action.symbol)
                .font(action.font)
                .foregroundStyle(action.tint)
                .frame(width: buttonSize, height: buttonSize)
                .background(action.background, in: .circle)
                .contentShape(.circle)
            
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isExpanded)
        .animation(.snappy(duration: 0.3,extraBounce: 0)){ content in
            content
                .scaleEffect(selectedAction?.id == action.id ? 1.15 : 1)
            
        }
        .background{
            GeometryReader{
                let rect = $0.frame(in: .named("CustomFloatingSpace"))
                
                Color.clear
                    .onChange(of: dragLocation) { oldValue, newValue in
                        if isExpanded && isDragging{
                            if rect.contains(newValue){
                                selectedAction = action
                            } else {
                                if selectedAction?.id == action.id && !rect.contains(newValue)
                                {
                                    selectedAction = nil
                                }
                            }
                        }
                        
                        
                    }
            }
        }
        .rotationEffect(.init(degrees: progress(action) * -90))
        .offset(x: isExpanded ? -offset / 2 : 0)
        .rotationEffect(.init(degrees: progress(action) * 90))
    }
    
    private var offset: CGFloat {
        let buttonSize = buttonSize + 10
        return Double(actions.count) * (actions.count == 1 ? buttonSize * 2 : (actions.count == 2 ? buttonSize * 1.25 : buttonSize))
    }
    
    private func progress(_ action: FloatingAction) ->  CGFloat{
        let index = CGFloat(actions.firstIndex(where: { $0.id == action.id}) ?? 0)
        return actions.count == 1 ? 1 : (index / CGFloat(actions.count - 1))
    }
}

fileprivate struct NoAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

fileprivate struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0, extraBounce: 0), value:
                        configuration.isPressed)
    }
}


struct FloatingAction: Identifiable{
    private(set) var id: UUID = .init()
    var symbol: String
    var font: Font = .title3
    var tint: Color = .accentColor
    var background: Material = .ultraThinMaterial
    var action: () -> ()
}

@resultBuilder
struct FloatingActionBuilder {
    static func buildBlock(_ components: FloatingAction...) -> [FloatingAction] {
        components.compactMap ({ $0 })
    }
}

