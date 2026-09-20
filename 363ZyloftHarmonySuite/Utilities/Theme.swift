import Foundation
import SwiftUI
import UIKit

enum AppLinks {
    static let privacy = "https://zyloftharmony363suite.site/privacy/475"
    static let terms = "https://zyloftharmony363suite.site/terms/475"
}

extension View {
    func canvasBackground(_ image: String = "bg_living") -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image(image)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.08)
                    }
                    .overlay { ColumnRules() }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

enum Keyboard {
    static func hide() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

final class KeyboardDismissInstaller: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissInstaller()

    func attach(to window: UIWindow?) {
        guard let window else { return }
        if window.gestureRecognizers?.contains(where: { $0.name == "studio.keyboard.dismiss" }) == true {
            return
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.name = "studio.keyboard.dismiss"
        tap.delegate = self
        window.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        Keyboard.hide()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView {
                return false
            }
            view = current.superview
        }
        return true
    }
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

struct ColumnRules: View {
    var body: some View {
        Canvas { context, size in
            let gutter = size.width / 3
            var path = Path()
            path.move(to: CGPoint(x: gutter, y: 40))
            path.addLine(to: CGPoint(x: gutter, y: size.height - 24))
            path.move(to: CGPoint(x: gutter * 2, y: 40))
            path.addLine(to: CGPoint(x: gutter * 2, y: size.height - 24))
            context.stroke(path, with: .color(Color.black.opacity(0.06)), lineWidth: 0.6)
        }
        .allowsHitTesting(false)
    }
}
