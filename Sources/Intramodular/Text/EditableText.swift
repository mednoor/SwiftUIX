//
// Copyright (c) Vatsal Manot
//

#if !os(tvOS) && !os(watchOS) 

import SwiftUI

/// An interactive `Text` that can enter an edit-mode.
@available(iOS 15.0, macOS 12.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct EditableText: View {
    public enum Activation {
        case onDoubleTap
    }
    
    @Environment(\._SwiftUIX_controlActiveState) var controlActiveState
    @Environment(\.isFocused) var isFocused

    #if os(iOS)
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @Environment(\.editMode) var _editMode
    #endif
    
    /// Respect the `editMode` read from the view's environment.
    ///
    /// This is disabled by default because Apple can't fucking get `List` right.
    private var respectEditMode: Bool = false
        
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    private var editMode: Binding<EditMode>? {
        #if os(iOS)
        if respectEditMode {
            return _editMode
        } else {
            return nil
        }
        #else
        return nil
        #endif
    }

    private var placeholder: String?
    @Binding private var text: String
    private let activation: Set<Activation>
    private let onCommit: (String) -> Void
    
    @FocusState private var textFieldIsFocused: Bool
    @State private var textBeingEdited: String?
    @StateOrBinding private var isEditing: Bool

    private var lineLimit: Int? = 1
    
    public init(
        _ placeholder: String? = nil,
        text: Binding<String>,
        isEditing: Binding<Bool>? = nil,
        activation: Set<Activation> = [.onDoubleTap],
        onCommit: @escaping (String) -> Void = { _ in }
    ) {
        self.placeholder = placeholder
        self._text = text
        self._textBeingEdited = .init(initialValue: text.wrappedValue)
        self._isEditing = isEditing.map({ StateOrBinding($0) }) ?? StateOrBinding(false)
        self.activation = activation
        self.onCommit = onCommit
    }

    public init(
        _ placeholder: String? = nil,
        text: Binding<String?>,
        isEditing: Binding<Bool>? = nil
    ) {
        self.init(placeholder, text: text.withDefaultValue(""), isEditing: isEditing)
    }

    public var body: some View {
        withAppKitOrUIKitViewController { controller in
            #if !os(macOS)
            if let editMode, respectEditMode {
                editModeRespectingContent(editMode: editMode)
            } else {
                if !isEditing {
                    staticDisplay
                        .onTapGesture(count: 2) {
                            if let collectionView = controller?._SwiftUIX_findSubview(ofKind: UICollectionView.self) {
                                collectionView._deselectAllItems()
                            }
                            
                            beginEditing()
                        }
                } else {
                    editableDisplay
                }
            }
            #else
            nonEditModeContent()
            #endif
        }
        .onChange(of: isEditing) { isEditing in
            if isEditing {
                beginEditing()
            } else {
                endEditing()
            }
        }
        .onChange(of: textFieldIsFocused) { isFocused in
            if !isFocused {
                endEditing()
            }
        }
        .onChange(of: controlActiveState) { controlActiveState in
            if isFocused {
                endEditing()
            }
        }
    }
    
    @available(macOS, unavailable)
    @ViewBuilder
    private func editModeRespectingContent(editMode: Binding<EditMode>) -> some View {
        Group {
            switch editMode.wrappedValue {
                case .active:
                    editableDisplay
                case .inactive:
                    staticDisplay.onTapGesture(
                        count: 2,
                        disabled: !activation.contains(.onDoubleTap)
                    ) {
                        beginEditing()
                    }
                default:
                    staticDisplay
            }
        }
        .onChange(of: editMode.wrappedValue) { editMode in
            if editMode == .active {
                beginEditing()
            } else if editMode == .inactive {
                endEditing()
            }
        }
    }
    
    @ViewBuilder
    private func nonEditModeContent() -> some View {
        if !isEditing {
            staticDisplay
                .onTapGesture(
                    count: 2,
                    disabled: !activation.contains(.onDoubleTap)
                ) {
                    beginEditing()
                }
        } else {
            editableDisplay
                .focused($textFieldIsFocused)
                .modify(for: .macOS) {
                    $0.onExitCommand {
                        endEditing()
                    }
                }
        }
    }

    @ViewBuilder
    private var staticDisplay: some View {
        if let placeholder, text.isEmpty {
            Text(placeholder)
        } else {
            Text(text)
        }
    }

    @ViewBuilder
    private var editableDisplay: some View {
        Group {
            if lineLimit == 1 {
                TextField(
                    "",
                    text: $textBeingEdited,
                    onEditingChanged: { isEditing in
                        onEditingChanged(isEditing)
                    },
                    onCommit: {
                        endEditing()
                    }
                )
                .textFieldStyle(.roundedBorder)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(1)
            } else {
                TextView(
                    "",
                    text: $textBeingEdited,
                    onEditingChanged: { isEditing in
                        onEditingChanged(isEditing)
                    },
                    onCommit: {
                        endEditing()
                    }
                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        ._overrideOnExitCommand {
            endEditing()
        }
    }

    private func onEditingChanged(_ isEditing: Bool) {
        #if !os(macOS)
        if editMode == nil {
            if !isEditing {
                // endEditing()
            }
        }
        #endif
    }
    
    private func beginEditing() {
        guard !isEditing else {
            return
        }
        
        #if !os(macOS)
        if let editMode {
            guard editMode.wrappedValue != .active else {
                return
            }

            editMode.wrappedValue = .active
        } else {
            isEditing = true
        }
        #else
        isEditing = true
        #endif

        textBeingEdited = text
        textFieldIsFocused = true
    }

    private func endEditing() {
        guard isEditing else {
            return
        }

        #if !os(macOS)
        if let editMode {
            guard editMode.wrappedValue == .active else {
                return
            }

            editMode.wrappedValue = .inactive
        } else {
            isEditing = false
        }
        #else
        isEditing = false
        #endif

        guard let textBeingEdited else {
            #if !os(macOS)
            assertionFailure()
            #endif
            
            return
        }

        self.text = textBeingEdited
        self.textBeingEdited = nil
        
        onCommit(textBeingEdited)
    }
}

@available(iOS 15.0, macOS 12.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension EditableText {
    public func lineLimit(_ lineLimit: Int?) -> Self {
        then({ $0.lineLimit = lineLimit })
    }
}

#endif
