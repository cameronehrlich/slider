//
//  ToggleSlider.swift
//  Slider
//
//  Created by Cameron Ehrlich on 7/26/18.
//  Copyright © 2018 Fair. All rights reserved.
//

import UIKit
import QuartzCore

private let kAnimateToCenterDuration: Double = 0.50
private let kSideIconImageSize: CGFloat = 15
private let kSideIconImagePadding: CGFloat = 5
private let kSideIconScaleAmount: CGFloat = 1.4
private let kSideIconAnimationDuration: Double = 0.25
private let kSideIconSelectionDetectionRatio: CGFloat = 0.05
private let kTrackSideInset: CGFloat = 55
private let kTrackHeightSmall: CGFloat = 20
private let kTrackHeightLarge: CGFloat = 50
private let kThumbScaleAnimationDuration: Double = 0.4
private let kThumbScaleAmount: CGFloat = 1.1
private let kThumbOverlayAnimationDuration: Double = (kAnimateToCenterDuration / 2.6)
private let kEdgeOvershootAmount: CGFloat = 40
private let kSelectionDetectionRatio: CGFloat = 0.55
private var kBlobHeightDelta: CGFloat = 15
private var kGrowShrinkDuration: Double = (kAnimateToCenterDuration / 2)
private var kHapticDelay: Double = 0.175

protocol ToggleSliderDelegate: class {
    func toggleSlider(_ toggleSlider: ToggleSlider, didChangeSelection selection: ToggleSlider.SliderSelection)
}

class ToggleSlider: UIControl {
    
    enum SliderSelection {
        case up
        case down
    }
    
    public weak var delegate: ToggleSliderDelegate?
    
    private lazy var currentPoint: CGPoint = centerPoint
    private var isAnimating: Bool = false
    private var feedbackGenerator: UISelectionFeedbackGenerator?
    
    private var centerPoint: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.minY)
    }
    
    private var maxValue: CGFloat {
        return bounds.width - kTrackSideInset - (blobHeight / 2)
    }
    
    private var minValue: CGFloat {
        return bounds.origin.x + kTrackSideInset + (blobHeight / 2)
    }
    
    private var trackHeight: CGFloat {
        return (isTracking) ? kTrackHeightLarge * 0.9 : kTrackHeightSmall
    }
    
    private var blobHeight: CGFloat {
        return isTracking ? kTrackHeightLarge + kBlobHeightDelta : trackHeight
    }
    
    private var trackOrigin: CGPoint {
        return CGPoint(x: kTrackSideInset, y: (bounds.height / 2) - (trackHeight / 2))
    }
    
    private var trackSize: CGSize {
        return CGSize(width: bounds.width - (2 * kTrackSideInset), height: trackHeight)
    }
    
    private var percentageFromCenter: CGFloat {
        let distanceFromCenter = abs(currentPoint.x - centerPoint.x)
        return distanceFromCenter / (trackSize.width / 2)
    }
    
    private var lightGray: UIColor {
        return UIColor(red: 246/255, green: 246/255 , blue: 246/255, alpha: 1)
    }
    
    private var darkGray: UIColor {
        return UIColor(red: 166/255, green: 166/255, blue: 166/255, alpha: 1)
    }
    
    private var orange: UIColor {
        return UIColor(red: 255/255, green: 90/255, blue: 0/255, alpha: 1)
    }
    
    // MARK: Views
    
    private lazy var layerWrapperView: UIView = {
        let v = UIView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return v
    }()
    
    private var leadingIconSelected: Bool = false
    private lazy var leadingIconView: UIImageView = {
        let v = UIImageView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.image = UIImage(named: "start-slider-small-minus")?.withRenderingMode(.alwaysTemplate)
        v.tintColor = darkGray
        v.contentMode = .center
        v.isUserInteractionEnabled = false
        return v
    }()

    private var trailingIconSelected: Bool = false
    private lazy var trailingIconView: UIImageView = {
        let v = UIImageView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.image = UIImage(named: "start-slider-small-plus")?.withRenderingMode(.alwaysTemplate)
        v.tintColor = darkGray
        v.contentMode = .center
        v.isUserInteractionEnabled = false
        return v
    }()

    private var trackViewHeightConstraint: NSLayoutConstraint?
    private lazy var trackView: UIView = {
        let v = UIView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = lightGray
        v.isUserInteractionEnabled = false
        return v
    }()
    
    private var thumbCenterXConstraint: NSLayoutConstraint?
    private lazy var thumbView: ThumbView = {
        let v = ThumbView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = false
        return v
    }()
    
    // MARK: Layers
    
    private lazy var trackGuideLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = UIColor.clear.cgColor
        return l
    }()
    
    private lazy var blobLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = lightGray.cgColor
        return l
    }()
    
    private lazy var blobLeftTailLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = lightGray.cgColor
        return l
    }()
    
    private lazy var blobRightTailLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = lightGray.cgColor
        return l
    }()

    // MARK: Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        backgroundColor = .clear
        
        addSubview(layerWrapperView)
        NSLayoutConstraint.activate([
            layerWrapperView.leadingAnchor.constraint(equalTo: leadingAnchor),
            layerWrapperView.trailingAnchor.constraint(equalTo: trailingAnchor),
            layerWrapperView.topAnchor.constraint(equalTo: topAnchor),
            layerWrapperView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

        layerWrapperView.layer.addSublayer(trackGuideLayer)
        layerWrapperView.layer.addSublayer(blobLeftTailLayer)
        layerWrapperView.layer.addSublayer(blobRightTailLayer)
        layerWrapperView.layer.addSublayer(blobLayer)
        
        addSubview(trackView)
        trackViewHeightConstraint = trackView.heightAnchor.constraint(equalToConstant: kTrackHeightSmall)
        trackViewHeightConstraint?.isActive = true
        let trackWidthInset = (2 * -kTrackSideInset)
        trackView.widthAnchor.constraint(equalTo: widthAnchor, constant: trackWidthInset).isActive = true
        trackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        trackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        insertSubview(leadingIconView, belowSubview: layerWrapperView)
        NSLayoutConstraint.activate([
            leadingIconView.widthAnchor.constraint(equalToConstant: kSideIconImageSize),
            leadingIconView.heightAnchor.constraint(equalToConstant: kSideIconImageSize),
            leadingIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leadingIconView.trailingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: -kSideIconImagePadding)
            ])
        
        insertSubview(trailingIconView, belowSubview: layerWrapperView)
        NSLayoutConstraint.activate([
            trailingIconView.widthAnchor.constraint(equalToConstant: kSideIconImageSize),
            trailingIconView.heightAnchor.constraint(equalToConstant: kSideIconImageSize),
            trailingIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trailingIconView.leadingAnchor.constraint(equalTo: trackView.trailingAnchor, constant: kSideIconImagePadding)
            ])
        
        addSubview(thumbView)
        thumbView.heightAnchor.constraint(equalToConstant: kTrackHeightLarge).isActive = true
        thumbView.widthAnchor.constraint(equalTo: thumbView.heightAnchor).isActive = true
        thumbCenterXConstraint = thumbView.centerXAnchor.constraint(equalTo: centerXAnchor)
        thumbCenterXConstraint?.isActive = true
        thumbView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        setNeedsDisplay()
    }
    
    // MARK: Touch handling
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        currentPoint = pointForTouch(touch)
        
        guard !isAnimating && thumbView.frame.contains(currentPoint) else {
            return false
        }
        
        // Animate track expansion
        animateTrack(expand: true, duration: kGrowShrinkDuration, delay: 0)
        
        // Animate thumb expansion
        animateThumbScale(true)
        
        // Prepare haptic feedback
        feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator?.prepare()
        
        setNeedsDisplay()
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        currentPoint = pointForTouch(touch)
        
        // Update thumb view position
        let distanceFromCenter = (currentPoint.x - centerPoint.x)
        thumbCenterXConstraint?.constant = distanceFromCenter
        
        // Update thumb view overlay transform
        if currentPoint.x > centerPoint.x {
            thumbView.thumbImageStyle = .plus
        } else {
            thumbView.thumbImageStyle = .minus
        }
        
        // Update side icons
        if percentageFromCenter > kSideIconSelectionDetectionRatio {
            if currentPoint.x > centerPoint.x {
                animateTrailingIcon(true)
            } else {
                animateLeadingIcon(true)
            }
        } else {
            animateTrailingIcon(false)
            animateLeadingIcon(false)
        }
        
        setNeedsDisplay()
        return true
    }
    
    override func cancelTracking(with event: UIEvent?) {
        endTracking(nil, with: event)
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        
        guard let touch = touch else { return }
        
        currentPoint = pointForTouch(touch)
        
        let isPastSelectionThreshhold = percentageFromCenter > kSelectionDetectionRatio
        
        // Call delegate
        if isPastSelectionThreshhold {
            let selection: SliderSelection = (currentPoint.x > centerPoint.x) ? .up : .down
            delegate?.toggleSlider(self, didChangeSelection: selection)
            
            // Trigger first haptic
            feedbackGenerator?.selectionChanged()
            DispatchQueue.main.asyncAfter(deadline: .now() + kHapticDelay) { [weak self] in
                guard let strongSelf = self else { return }
                // Trigger second haptic
                strongSelf.feedbackGenerator?.selectionChanged()
            }
        }
        
        // Animate thumb view position
        animateThumb(selected: isPastSelectionThreshhold) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.setNeedsDisplay()
        }
        
        // Animate plus/minus scale
        if isPastSelectionThreshhold {
            thumbView.animateOverlayToProgress(1) { [weak self] _ in
                guard let strongSelf = self else { return }
                // Hide side icons
                strongSelf.leadingIconView.alpha = 0
                strongSelf.trailingIconView.alpha = 0
                strongSelf.thumbView.animateOverlayToProgress(0, completion: { _ in
                    guard let strongSelf = self else { return }
                    // Animate side icons fade back in
                    UIView.animate(withDuration: 0.3, delay: 0, options: [], animations: {
                        strongSelf.leadingIconView.alpha = 1
                        strongSelf.trailingIconView.alpha = 1
                    }, completion: nil)
                })
            }
        } else {
            thumbView.animateOverlayToProgress(0)
        }

        // Animate blob position and scale
        animateBlob { [weak self] in
            self?.setNeedsDisplay()
        }
        
        // Animate side icons down
        animateLeadingIcon(false)
        animateTrailingIcon(false)
        
        // Animate thumb expansion
        animateThumbScale(false)
    }
    
    private func pointForTouch(_ touch: UITouch) -> CGPoint {
        let location = touch.location(in: self)
        if location.x >= maxValue {
            return CGPoint(x: maxValue, y: bounds.midY)
        }
        else if location.x <= minValue  {
            return CGPoint(x: minValue , y: bounds.midY)
        }
        else {
            return location
        }
    }
    
    // MARK: Animations
    
    private func animateLeadingIcon(_ selected: Bool, completion: ((Bool) -> ())? = nil) {
        if selected != leadingIconSelected {
            leadingIconSelected = selected
            UIView.animate(withDuration: kSideIconAnimationDuration, animations: { [weak self] in
                guard let strongSelf = self else { return }
                let scale = CGAffineTransform(scaleX: kSideIconScaleAmount, y: kSideIconScaleAmount)
                strongSelf.leadingIconView.transform = selected ? scale : .identity
                strongSelf.leadingIconView.tintColor = selected ? strongSelf.orange : strongSelf.darkGray
                }, completion: completion)
        }
    }
    
    private func animateTrailingIcon(_ selected: Bool, completion: ((Bool) -> ())? = nil) {
        if selected != trailingIconSelected {
            trailingIconSelected = selected
            UIView.animate(withDuration: kSideIconAnimationDuration, animations: { [weak self] in
                guard let strongSelf = self else { return }
                let scale = CGAffineTransform(scaleX: kSideIconScaleAmount, y: kSideIconScaleAmount)
                strongSelf.trailingIconView.transform = selected ? scale : .identity
                strongSelf.trailingIconView.tintColor = selected ? strongSelf.orange : strongSelf.darkGray
                }, completion: completion)
        }
    }
    
    private func animateThumbScale(_ selected: Bool) {
        let animations = { [weak self] in
            guard let strongSelf = self else { return }
            if selected {
                strongSelf.thumbView.transform = CGAffineTransform(scaleX: kThumbScaleAmount, y: kThumbScaleAmount)
            } else {
                strongSelf.thumbView.transform = .identity
            }
        }
        UIView.animate(
            withDuration: kThumbScaleAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.7,
            options: [.beginFromCurrentState],
            animations: animations,
            completion: nil)
    }
    
    private func animateTrack(expand: Bool, duration: Double, delay: Double) {
        let animations = { [weak self] in
            guard let strongSelf = self else { return }
            if expand {
                strongSelf.trackViewHeightConstraint?.constant = kTrackHeightLarge
            } else {
                strongSelf.trackViewHeightConstraint?.constant = kTrackHeightSmall
            }
            strongSelf.layoutIfNeeded()
        }
        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.8,
                       options: [.beginFromCurrentState, .curveEaseOut],
                       animations: animations,
                       completion: nil)
    }
    
    private func animateThumb(selected: Bool, _ completion: @escaping () -> ()) {
        let isOffsetToRight = (currentPoint.x > centerPoint.x)
        
        let offsetAmount = (trackSize.width / 2) - (kTrackSideInset / 2) + kEdgeOvershootAmount
        let edgeX = isOffsetToRight ? offsetAmount : -offsetAmount
        
        func animateThumbToEdge(_ edgeCompletion: @escaping (Bool) -> ()) {
            let animationOptions: UIViewAnimationOptions = [.beginFromCurrentState, .curveEaseOut]

            let animations = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.thumbCenterXConstraint?.constant = edgeX
                strongSelf.layoutIfNeeded()
            }
            UIView.animate(
                withDuration: kAnimateToCenterDuration / 2,
                delay: 0,
                options: animationOptions,
                animations: animations,
                completion: edgeCompletion
            )
        }
        
        func animateThumbToCenter(_ centerCompletion: @escaping (Bool) -> ()) {
            let animationOptions: UIViewAnimationOptions = [.beginFromCurrentState, .curveEaseIn]
            let animations = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.thumbCenterXConstraint?.constant = 0
                strongSelf.layoutIfNeeded()
            }
            UIView.animate(
                withDuration: kAnimateToCenterDuration / 2,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.8,
                options: animationOptions,
                animations: animations,
                completion: centerCompletion
            )
        }
        
        if selected {
            animateThumbToEdge { _ in
                animateThumbToCenter { _ in
                    completion()
                }
            }
        } else {
            animateThumbToCenter { _ in
                completion()
            }
        }
    }
    
    private func animateBlob(_ completion: @escaping () -> ()) {
        
        let isOffsetToRight = (currentPoint.x > centerPoint.x)
        
        let edgePoint = CGPoint(
            x: isOffsetToRight ? maxValue + kEdgeOvershootAmount : minValue - kEdgeOvershootAmount,
            y: bounds.midY
        )
        
        var keyTimes: [NSNumber]?
        var keyPoints: [CGPoint]?
        
        let isPastSelectionThreshhold = percentageFromCenter > kSelectionDetectionRatio
        if isPastSelectionThreshhold {
            keyTimes = [
                NSNumber(value: 0.00),
                NSNumber(value: 0.40),
                NSNumber(value: 0.65),
                NSNumber(value: 0.85),
            ]
            keyPoints = [
                currentPoint,
                edgePoint,
                edgePoint,
                centerPoint
            ]
        } else {
            keyTimes  = [
                NSNumber(value: 0.0),
                NSNumber(value: 0.7),
            ]
            keyPoints = [
                currentPoint,
                centerPoint
            ]
        }
        
        guard let times = keyTimes, let points = keyPoints else { return }

        let animationDuration =  isPastSelectionThreshhold ? kAnimateToCenterDuration : kAnimateToCenterDuration / 2
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        
        // Animate track
        let trackAnimation = CAKeyframeAnimation(keyPath: #keyPath(CAShapeLayer.path))
        trackAnimation.keyTimes = times
        trackAnimation.values = points.map { pathForTrack(inRect: bounds, atPoint: $0) }
        trackGuideLayer.add(trackAnimation, forKey: "trackAnimation")
        
        // Animate blob
        let blobKeyFrameAnimation = CAKeyframeAnimation(keyPath: #keyPath(CAShapeLayer.path))
        blobKeyFrameAnimation.delegate = self // Use the blob animation delegate methods to set isAnimating
        blobKeyFrameAnimation.keyTimes = times
        blobKeyFrameAnimation.values = points.map { pathForBlob(inRect: bounds, atPoint: $0) }
        blobLayer.add(blobKeyFrameAnimation, forKey: "blobAnimation")
        
        // Animate right tail
        let rightTailAnimation = CAKeyframeAnimation(keyPath: #keyPath(CAShapeLayer.path))
        rightTailAnimation.keyTimes = times
        rightTailAnimation.values = points.map { pathForRightTail(inRect: bounds, atPoint: $0) }
        blobRightTailLayer.add(rightTailAnimation, forKey: "rightTailAnimation")
        
        // Animate left tail
        let leftTailAnimation = CAKeyframeAnimation(keyPath: #keyPath(CAShapeLayer.path))
        leftTailAnimation.keyTimes = times
        leftTailAnimation.values = points.map { pathForLeftTail(inRect: bounds, atPoint: $0) }
        blobLeftTailLayer.add(leftTailAnimation, forKey: "leftTailAnimation")
        
        CATransaction.setCompletionBlock { [weak self] in
            guard let strongSelf = self else { return }
            completion()
            strongSelf.setNeedsDisplay()
            strongSelf.animateTrack(
                expand: false,
                duration: kGrowShrinkDuration,
                delay: animationDuration
            )
        }
        CATransaction.commit()
        
        currentPoint = centerPoint
    }
    
    // MARK: Paths
    private func pathForTrack(inRect rect: CGRect, atPoint point: CGPoint) -> CGPath {
        let size = CGSize(
            width: trackSize.width,
            height: trackSize.height
        )
        let trackRect = CGRect(origin: trackOrigin, size: size)
        return UIBezierPath(roundedRect: trackRect, cornerRadius: size.height / 2).cgPath
    }
    
    private func pathForBlob(inRect rect: CGRect, atPoint point: CGPoint) -> CGPath {
        let blobCenter = CGPoint(x: point.x, y: bounds.midY)
        let radius = blobHeight / 2
        return UIBezierPath(arcCenter: blobCenter,radius: radius, startAngle: 0, endAngle: (2 * .pi), clockwise: true).cgPath
    }
    
    private func pathForLeftTail(inRect rect: CGRect, atPoint point: CGPoint) -> CGPath {
        let origin = CGPoint(
            x: rect.midX - (trackSize.width / 2) + (trackSize.height / 2),
            y: rect.midY - (blobHeight / 2)
        )

        let size = CGSize(
            width: point.x - origin.x,
            height: blobHeight
        )
        
        let tailFrame = CGRect(
            origin: origin,
            size: size
        )
        
        let isPointBeyondOrigin = point.x < origin.x
        
        let path = UIBezierPath()
        
        // Starting top left
        let topLeft = CGPoint(
            x: origin.x,
            y: rect.midY - (trackHeight / 2)
        )
        path.move(to: topLeft)
        
        // Draw curve to right side
        let topRight = CGPoint(
            x: origin.x + size.width,
            y: origin.y
        )
        let controlPointTop = CGPoint(
            x: tailFrame.midX,
            y: isPointBeyondOrigin ? rect.midY : rect.midY - (trackHeight / 2)
        )
        path.addQuadCurve(to: topRight, controlPoint: controlPointTop)
        
        // Draw line down
        let bottomRight = CGPoint(
            x: topRight.x,
            y: origin.y + size.height
        )
        path.addLine(to: bottomRight)
        
        // Draw curve back to left side
        let bottomLeft = CGPoint(
            x: origin.x,
            y: rect.midY + (trackHeight / 2)
        )
        let controlPointBottom = CGPoint(
            x: tailFrame.midX,
            y: isPointBeyondOrigin ? rect.midY : rect.midY + (trackHeight / 2)
        )
        path.addQuadCurve(to: bottomLeft, controlPoint: controlPointBottom)
        path.close()
        return path.cgPath
    }
    
    private func pathForRightTail(inRect rect: CGRect, atPoint point: CGPoint) -> CGPath {
        let origin = CGPoint(
            x: point.x,
            y: rect.midY - (blobHeight / 2)
        )
        
        let size = CGSize(
            width: (trackSize.width / 2) + (rect.midX - point.x) - (trackSize.height / 2),
            height: blobHeight
        )
        
        let tailFrame = CGRect(
            origin: origin,
            size: size
        )
        
        let isPointBeyondOrigin = point.x > origin.x + size.width
        
        let path = UIBezierPath()
        
        let topRight = CGPoint(
            x: origin.x,
            y: origin.y
        )
        path.move(to: topRight)
        
        let topLeft = CGPoint(
            x: origin.x + size.width,
            y: rect.midY - (trackHeight / 2)
        )
        
        let controlPointTop = CGPoint(
            x: tailFrame.midX,
            y: isPointBeyondOrigin ? rect.midY : rect.midY - (trackHeight / 2)
        )
        path.addQuadCurve(to: topLeft, controlPoint: controlPointTop)
        
        let bottomRight = CGPoint(
            x: topLeft.x,
            y: rect.midY + (trackHeight / 2)
        )
        path.addLine(to: bottomRight)
        
        let bottomLeft = CGPoint(
            x: origin.x,
            y: origin.y + size.height
        )
        let controlPointBottom = CGPoint(
            x: tailFrame.midX,
            y: isPointBeyondOrigin ? rect.midY : rect.midY + (trackHeight / 2)
        )
        path.addQuadCurve(to: bottomLeft, controlPoint: controlPointBottom)
        path.close()
        return path.cgPath
    }
    
    // MARK: Overrides
    
    override func draw(_ rect: CGRect) {
        if !isAnimating {
            // Track
            trackGuideLayer.path = pathForTrack(inRect: rect, atPoint: currentPoint)
            
            // Blob
            blobLayer.path = pathForBlob(inRect: rect, atPoint: currentPoint)
            
            // Left tail
            blobLeftTailLayer.path = pathForLeftTail(inRect: rect, atPoint: currentPoint)
            
            // Right tail
            blobRightTailLayer.path = pathForRightTail(inRect: rect, atPoint: currentPoint)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Track view corner radius
        trackView.layer.cornerRadius = trackView.frame.size.height / 2
    }
}

extension ToggleSlider: CAAnimationDelegate {
    func animationDidStart(_ anim: CAAnimation) {
        isAnimating = true
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        isAnimating = false
        setNeedsDisplay()
    }
}

private class ThumbView: UIView {

    private let mainImageView = UIImageView(frame: .zero)
    private let overlayImageView = UIImageView(frame: .zero)
    public var progress: CGFloat = 0 { // [-1, 1]
        didSet {
            switch progress {
            case 0...1:
                thumbImageStyle = .plus
            case -1...0:
                thumbImageStyle = .minus
            default: break
            }
            
            let scale = CGAffineTransform(scaleX: abs(progress), y: abs(progress))
            overlayImageView.transform = scale
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    enum ThumbImageStyle {
        case plus
        case minus
    }
    
    var thumbImageStyle: ThumbImageStyle = .plus {
        didSet {
            switch thumbImageStyle {
            case .plus:
                overlayImageView.image = UIImage(named: "start-slider-large-plus")
            case .minus:
                overlayImageView.image = UIImage(named: "start-slider-large-minus")
            }
        }
    }
    
    private func setupUI() {
        addSubview(mainImageView)
        mainImageView.image = #imageLiteral(resourceName: "start-slider-thumb")
        mainImageView.contentMode = .scaleAspectFill
        mainImageView.translatesAutoresizingMaskIntoConstraints = false
        mainImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mainImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        mainImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mainImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        mainImageView.layer.shadowColor = UIColor.black.cgColor
        mainImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        mainImageView.layer.shadowRadius = 4
        mainImageView.layer.shadowOpacity = 0.2
        
        addSubview(overlayImageView)
        overlayImageView.contentMode = .scaleAspectFit
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        overlayImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        overlayImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        overlayImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        animateOverlayToProgress(0)
    }
    
    func animateOverlayToProgress(_ progress: CGFloat, completion: ((Bool) -> ())? = nil) {
        let scaleBy = max(0.5, abs(progress)) // CA bug animating to 0
        let animations = { [weak self] in
            guard let strongSelf = self else { return }
            let scale = CGAffineTransform(scaleX: scaleBy, y: scaleBy)
            strongSelf.overlayImageView.transform = scale
            strongSelf.overlayImageView.alpha = progress
        }
        UIView.animate(
            withDuration: kThumbOverlayAnimationDuration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseOut],
            animations: animations,
            completion: completion
        )
    }
}
