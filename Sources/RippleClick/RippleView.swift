import AppKit
import QuartzCore

@MainActor
final class RippleView: NSView {
    private static let initialRadius: CGFloat = 5
    private static let strokeWidth: CGFloat = 3.0
    private static let fillOpacity: CGFloat = 0.15
    private static let animationDuration: CFTimeInterval = 0.5

    private let rippleColor: NSColor
    private let maxSize: CGFloat

    init(frame: NSRect, color: NSColor, maxSize: CGFloat) {
        self.rippleColor = color
        self.maxSize = maxSize
        super.init(frame: frame)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func startAnimation() {
        guard let layer = self.layer else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let finalRadius: CGFloat = maxSize / 2

        let initialPath = CGPath(
            ellipseIn: CGRect(
                x: center.x - Self.initialRadius,
                y: center.y - Self.initialRadius,
                width: Self.initialRadius * 2,
                height: Self.initialRadius * 2
            ),
            transform: nil
        )
        let finalPath = CGPath(
            ellipseIn: CGRect(
                x: center.x - finalRadius,
                y: center.y - finalRadius,
                width: finalRadius * 2,
                height: finalRadius * 2
            ),
            transform: nil
        )

        let circleLayer = CAShapeLayer()
        circleLayer.path = initialPath
        circleLayer.fillColor = rippleColor.withAlphaComponent(Self.fillOpacity).cgColor
        circleLayer.strokeColor = rippleColor.cgColor
        circleLayer.lineWidth = Self.strokeWidth
        circleLayer.frame = bounds
        layer.addSublayer(circleLayer)

        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = initialPath
        pathAnimation.toValue = finalPath

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0

        let group = CAAnimationGroup()
        group.animations = [pathAnimation, opacityAnimation]
        group.duration = Self.animationDuration
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false

        circleLayer.add(group, forKey: "ripple")
    }
}
