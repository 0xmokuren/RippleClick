import AppKit
import QuartzCore

@MainActor
final class RippleView: NSView {
    private static let initialRadius: CGFloat = 5
    private static let strokeWidth: CGFloat = 3.0
    private static let fillOpacity: CGFloat = 0.15
    private var rippleColor: NSColor
    private var maxSize: CGFloat
    private var animationDuration: CFTimeInterval
    private var rippleOpacity: CGFloat
    private var ringCount: Int
    private var strokeMultiplier: CGFloat

    init(
        frame: NSRect,
        color: NSColor,
        maxSize: CGFloat,
        duration: CFTimeInterval = 0.5,
        opacity: CGFloat = 1.0,
        ringCount: Int = 1,
        strokeMultiplier: CGFloat = 1.0
    ) {
        self.rippleColor = color
        self.maxSize = maxSize
        self.animationDuration = duration
        self.rippleOpacity = opacity
        self.ringCount = ringCount
        self.strokeMultiplier = strokeMultiplier
        super.init(frame: frame)
        wantsLayer = true
    }

    func clearLayers() {
        if let sublayers = layer?.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
        layer?.removeAllAnimations()
    }

    func reset(
        color: NSColor, maxSize: CGFloat, duration: CFTimeInterval, opacity: CGFloat,
        ringCount: Int = 1, strokeMultiplier: CGFloat = 1.0
    ) {
        self.rippleColor = color
        self.maxSize = maxSize
        self.animationDuration = duration
        self.rippleOpacity = opacity
        self.ringCount = ringCount
        self.strokeMultiplier = strokeMultiplier
        clearLayers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func startAnimation() {
        guard let layer = self.layer else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        for ringIndex in 0..<ringCount {
            let ringFraction: CGFloat = (ringCount > 1 && ringIndex == 0) ? 0.6 : 1.0
            let ringOpacityScale: CGFloat = (ringCount > 1 && ringIndex == 0) ? 0.7 : 1.0
            let finalRadius: CGFloat = (maxSize / 2) * ringFraction

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
            let fillAlpha = Self.fillOpacity * rippleOpacity * ringOpacityScale
            circleLayer.fillColor = rippleColor.withAlphaComponent(fillAlpha).cgColor
            let strokeAlpha = rippleOpacity * ringOpacityScale
            circleLayer.strokeColor = rippleColor.withAlphaComponent(strokeAlpha).cgColor
            circleLayer.lineWidth = Self.strokeWidth * strokeMultiplier
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
            group.duration = animationDuration
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            group.fillMode = .forwards
            group.isRemovedOnCompletion = false

            circleLayer.add(group, forKey: "ripple\(ringIndex)")
        }
    }
}
