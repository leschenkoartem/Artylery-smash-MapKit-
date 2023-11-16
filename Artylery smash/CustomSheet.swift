//
//  CustomSheet.swift
//  Artylery smash
//
//  Created by Artem Leschenko on 15.11.2023.
//

import Foundation
import SwiftUI

public enum PresentationDetentReference: Hashable {

    case large

    case medium

    case fraction(_ value: CGFloat)

    case height(_ value: CGFloat)

    var swiftUIDetent: PresentationDetent {
        switch self {
        case .large: return .large
        case .medium: return .medium
        case .fraction(let value): return .fraction(value)
        case .height(let value): return .height(value)
        }
    }

    var uiKitIdentifier: UISheetPresentationController.Detent.Identifier {
        switch self {
        case .large: return .large
        case .medium: return .medium
        case .fraction(let value): return .fraction(value)
        case .height(let value): return .height(value)
        }
    }
}

extension UISheetPresentationController.Detent.Identifier {

    static func fraction(_ value: CGFloat) -> Self {
        .init("Fraction:\(String(format: "%.1f", value))")
    }

    static func height(_ value: CGFloat) -> Self {
        .init("Height:\(value)")
    }
}

extension Collection where Element == PresentationDetentReference {

    var swiftUISet: Set<PresentationDetent> {
        Set(map { $0.swiftUIDetent })
    }
}

private class UndimmedDetentViewController: UIViewController {

    var largestUndimmedDetent: PresentationDetentReference?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avoidDimmingParent()
        avoidDisablingControls()
    }

    func avoidDimmingParent() {
        let id = largestUndimmedDetent?.uiKitIdentifier
        sheetPresentationController?.largestUndimmedDetentIdentifier = id
    }

    func avoidDisablingControls() {
        presentingViewController?.view.tintAdjustmentMode = .normal
    }
}

private struct UndimmedDetentView: UIViewControllerRepresentable {

    var largestUndimmed: PresentationDetentReference?

    func makeUIViewController(
        context: Context
    ) -> UndimmedDetentViewController {
        let result = UndimmedDetentViewController()
        result.largestUndimmedDetent = largestUndimmed
        return result
    }

    func updateUIViewController(
        _ controller: UndimmedDetentViewController,
        context: Context
    ) {
        controller.largestUndimmedDetent = largestUndimmed
    }
}

public struct PresentationDetentsViewModifier: ViewModifier {

    public init(
        presentationDetents: [PresentationDetentReference],
        largestUndimmed: PresentationDetentReference,
        selection: Binding<PresentationDetent>? = nil
    ) {
        self.presentationDetents = presentationDetents + [largestUndimmed]
        self.largestUndimmed = largestUndimmed
        self.selection = selection
    }

    private let presentationDetents: [PresentationDetentReference]
    private let largestUndimmed: PresentationDetentReference
    private let selection: Binding<PresentationDetent>?

    public func body(content: Content) -> some View {
        if let selection = selection {
            content
                .background(background)
                .presentationDetents(
                    Set(presentationDetents.swiftUISet),
                    selection: selection)
        } else {
            content
                .background(background)
                .presentationDetents(Set(presentationDetents.swiftUISet))
        }
    }
}

private extension PresentationDetentsViewModifier {

    var background: some View {
        UndimmedDetentView(
            largestUndimmed: largestUndimmed
        )
    }
}

public extension View {

    func presentationDetents(
        _ detents: [PresentationDetentReference],
        largestUndimmed: PresentationDetentReference,
        selection: Binding<PresentationDetent>? = nil
    ) -> some View {
        self.modifier(
            PresentationDetentsViewModifier(
                presentationDetents: detents + [largestUndimmed],
                largestUndimmed: largestUndimmed,
                selection: selection
            )
        )
    }
}
