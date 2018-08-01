//
//  StartSlider.swift
//  Slider
//
//  Created by Cameron Ehrlich on 7/19/18.
//  Copyright © 2018 Fair. All rights reserved.
//

import UIKit

protocol StartSliderDelegate: class {
    func startSlider(_ startSlider: StartSlider, didChangeSelection selection: StartSlider.StartSliderSelection)
}

class StartSlider: UIControl {
    
    enum StartSliderSelection {
        case up
        case down
    }
    
    var delegate: StartSliderDelegate?

    private var kTrackHeightSmall: CGFloat = 20
    private var kTrackHeightLarge: CGFloat = 50
    private var kTrackInset: CGFloat = 30
    private var kThumbSize: CGFloat = 50
    private var kThumbScaleRatio: CGFloat = 1.3
    private var kSideIconImageSize: CGFloat = 20
    private var kSelectionThreshold: CGFloat = 0.5
    private var kSelectionPauseDuration: Double = 0.15
    private var kAnimateToCenterDuration: Double = 0.3
    private var kAnimateToEdgeDuration: Double = 0.25
    private var kSelectionAnimationOvershoot: CGFloat = 9
    
    private var startingValue = 0.5
    private var hasAnimatedSideIconsForSwipe: Bool = false
    
    private var feedbackGenerator: UISelectionFeedbackGenerator?
    
    private var isFingerDown: Bool = false {
        willSet {
            if newValue != isFingerDown {
                animateTrack(fingerDown: newValue)
            }
        }
        didSet {
            if !isFingerDown {
                hasAnimatedSideIconsForSwipe = false
                UIView.animate(withDuration: 0.2) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.leadingIconImageView.transform = .identity
                    strongSelf.leadingIconImageView.tintColor = strongSelf.darkGray
                    strongSelf.trailingIconImageView.transform = .identity
                    strongSelf.trailingIconImageView.tintColor = strongSelf.darkGray
                }
            } else {
                feedbackGenerator = UISelectionFeedbackGenerator()
                feedbackGenerator?.prepare()
            }
        }
    }
    
    private var trackHeightConstraint: NSLayoutConstraint?
    private lazy var trackView: UIView = {
        let v = UIView()
        v.backgroundColor = lightGray
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = kTrackHeightSmall / 2
        v.isUserInteractionEnabled = false
        return v
    }()
    
    private var thumbHorizontalConstraint: NSLayoutConstraint?
    private var thumbHeightConstraint: NSLayoutConstraint?
    private var thumbWidthConstraint: NSLayoutConstraint?
    private lazy var thumbView: StartSliderThumbView = {
        let v = StartSliderThumbView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = lightGray
        v.isUserInteractionEnabled = false
       return v
    }()
    
    private var blobHeightConstraint: NSLayoutConstraint?
    private var blobWidthConstraint: NSLayoutConstraint?
    private var blobCenterXConstraint: NSLayoutConstraint?
    private lazy var blobView: UIView = {
        let v = UIView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .red
        v.isUserInteractionEnabled = false
        v.clipsToBounds = true
        return v
    }()
    
    private lazy var blobTailView: TailView = {
        let v = TailView(frame: .zero)
        v.tailDirection = .left
        v.tailDelta = kThumbScaleRatio
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = false
        v.clipsToBounds = true
        return v
    }()

    private lazy var leadingIconImageView: UIImageView = {
        let v = UIImageView (frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.image = UIImage(named: "start-slider-small-minus")?.withRenderingMode(.alwaysTemplate)
        v.tintColor = darkGray
        v.contentMode = .center
        v.isUserInteractionEnabled = true
        return v
    }()

    private lazy var trailingIconImageView: UIImageView = {
        let v = UIImageView (frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.image = UIImage(named: "start-slider-small-plus")?.withRenderingMode(.alwaysTemplate)
        v.tintColor = darkGray
        v.contentMode = .center
        v.isUserInteractionEnabled = true
        return v
    }()
    
    private var thumbPosition: CGFloat {
        get {
            return thumbHorizontalConstraint?.constant ?? 0
        }
        set {
            thumbHorizontalConstraint?.constant = newValue
            
            if newValue < startingPoint.x {
                thumbView.thumbImageStyle = .minus
            } else if newValue > startingPoint.x  {
                thumbView.thumbImageStyle = .plus
            } else {
                // Leave it alone
            }
        }
    }
    
    private var currentOffsetFromCenter: CGFloat {
        return (thumbPosition - startingPoint.x) / (trackView.bounds.width / 2)
    }
    
    private var minValue: CGFloat {
        return kTrackInset + kThumbSize + kSelectionAnimationOvershoot
    }
    
    private var maxValue: CGFloat {
        return bounds.width - kTrackInset - kThumbSize - kSelectionAnimationOvershoot
    }
    
    private var startingPoint: CGPoint {
        return CGPoint(x: (minValue + maxValue) / 2, y: bounds.height / 2)
    }
    
    private var trackWidth: CGFloat {
        return bounds.width - (2 * kTrackInset) - (2 * kThumbSize) + (2 * kSelectionAnimationOvershoot)
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(trackView)
        trackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        trackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        trackView.widthAnchor.constraint(equalToConstant: trackWidth).isActive = true
        trackHeightConstraint = trackView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0, constant: kTrackHeightSmall)
        trackHeightConstraint?.isActive = true
        
        addSubview(leadingIconImageView)
        leadingIconImageView.widthAnchor.constraint(equalToConstant: kSideIconImageSize).isActive = true
        leadingIconImageView.heightAnchor.constraint(equalToConstant: kSideIconImageSize).isActive = true
        leadingIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        leadingIconImageView.trailingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: 0).isActive = true
        
        addSubview(trailingIconImageView)
        trailingIconImageView.widthAnchor.constraint(equalToConstant: kSideIconImageSize).isActive = true
        trailingIconImageView.heightAnchor.constraint(equalToConstant: kSideIconImageSize).isActive = true
        trailingIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        trailingIconImageView.leadingAnchor.constraint(equalTo: trackView.trailingAnchor, constant: 0).isActive = true
        
        addSubview(thumbView)
        thumbView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        thumbWidthConstraint = thumbView.widthAnchor.constraint(equalToConstant: kThumbSize)
        thumbWidthConstraint?.isActive = true
        thumbHeightConstraint = thumbView.heightAnchor.constraint(equalToConstant: kThumbSize)
        thumbHeightConstraint?.isActive = true
        thumbHorizontalConstraint = thumbView.centerXAnchor.constraint(equalTo: leadingAnchor)
        thumbHorizontalConstraint?.isActive = true
        
        insertSubview(blobView, belowSubview: thumbView)
        blobView.centerYAnchor.constraint(equalTo: thumbView.centerYAnchor).isActive = true
        blobCenterXConstraint = blobView.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor)
        blobCenterXConstraint?.isActive = true
        blobWidthConstraint = blobView.widthAnchor.constraint(equalToConstant: kTrackHeightSmall)
        blobWidthConstraint?.isActive = true
        blobHeightConstraint = blobView.heightAnchor.constraint(equalToConstant: kTrackHeightSmall)
        blobHeightConstraint?.isActive = true
        blobView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor).isActive = true
        
        insertSubview(blobTailView, aboveSubview: blobView)
        blobTailView.trailingAnchor.constraint(equalTo: blobView.centerXAnchor, constant: 0).isActive = true
        blobTailView.leadingAnchor.constraint(equalTo: trackView.centerXAnchor, constant: 0).isActive = true
        blobTailView.heightAnchor.constraint(equalTo: blobView.heightAnchor, constant: 0).isActive = true
        blobTailView.centerYAnchor.constraint(equalTo: blobView.centerYAnchor, constant: 0).isActive = true

        thumbPosition = positionForValue(startingPoint)
    }
    
    // MARK: Touch handling
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)
        if thumbView.frame.contains(touchPoint) {
            isFingerDown = true
            
            // Update thumb position
            let touchPoint = touch.location(in: self)
            thumbPosition = positionForValue(touchPoint)
            
        }
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isFingerDown else {
            return false
        }
        
        // Update thumb position
        let touchPoint = touch.location(in: self)
        thumbPosition = positionForValue(touchPoint)
        
        // Animate large plus/minus icon on the button
        let normalizedValue: CGFloat = min(1, abs(currentOffsetFromCenter))
        thumbView.overlayImageView.alpha = normalizedValue
        thumbView.overlayImageView.transform = {
            CGAffineTransform(scaleX: normalizedValue, y: normalizedValue)
        }()
        
        let sideIconAnimationThreshold: CGFloat = 0.4
        
        // Animate side icons
        if abs(currentOffsetFromCenter) > sideIconAnimationThreshold {
            if !hasAnimatedSideIconsForSwipe {
                hasAnimatedSideIconsForSwipe = true
                UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    let scaleUpTransform = CGAffineTransform(scaleX: 1.4, y: 1.4)
                    
                    if strongSelf.currentOffsetFromCenter > 0 {
                        strongSelf.leadingIconImageView.transform = .identity
                        strongSelf.leadingIconImageView.tintColor = strongSelf.darkGray
                        strongSelf.trailingIconImageView.transform = scaleUpTransform
                        strongSelf.trailingIconImageView.tintColor = strongSelf.orange
                    } else {
                        strongSelf.leadingIconImageView.transform = scaleUpTransform
                        strongSelf.leadingIconImageView.tintColor = strongSelf.orange
                        strongSelf.trailingIconImageView.transform = .identity
                        strongSelf.trailingIconImageView.tintColor = strongSelf.darkGray
                    }
                    }, completion: nil)
            }
        }
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        guard isFingerDown, let touch = touch else {
            return
        }
        let touchPoint = touch.location(in: self)
        let currentOffsetFromCenter: CGFloat = (touchPoint.x - startingPoint.x) / (trackView.bounds.width/2)
        completeDrag(fromOffset: currentOffsetFromCenter)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        guard isFingerDown else {
            return
        }
        completeDrag(fromOffset: 0)
    }
    
    // MARK: Helpers

    private func positionForValue(_ touchPoint: CGPoint) -> CGFloat {
        if touchPoint.x <= minValue {
            return minValue
        } else if touchPoint.x >= maxValue {
            return maxValue
        } else {
            return touchPoint.x
        }
    }
    
    private func animateThumbToEdge(fromOffset offset: CGFloat, completion: ((Bool) -> Void)?) {
        
        let animationBlock = { [weak self] in
            guard let strongSelf = self else { return }
            let transform = CGAffineTransform(scaleX: 1, y: 1)
            strongSelf.thumbView.overlayImageView.transform = transform
            strongSelf.thumbPosition = {
                if offset > 0 {
                    return strongSelf.maxValue + strongSelf.kSelectionAnimationOvershoot
                } else {
                    return strongSelf.minValue - strongSelf.kSelectionAnimationOvershoot
                }
            }()
            strongSelf.updateUI()
            strongSelf.thumbView.setNeedsDisplay()
            strongSelf.layoutIfNeeded()
        }
        
        let options: UIViewAnimationOptions = [
            .beginFromCurrentState,
            .layoutSubviews,
            .curveEaseOut
        ]
        
        UIView.animate(
            withDuration: kAnimateToEdgeDuration,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.8,
            options: options,
            animations: animationBlock,
            completion: completion
        )
    }
    
    private func animateThumbToCenter(fromOffset offset: CGFloat, completion: ((Bool) -> Void)?) {
        
        isFingerDown = false
        
        let animationBlock = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.thumbPosition = strongSelf.startingPoint.x
            let transform = CGAffineTransform(scaleX: 0.01, y: 0.01) // Bug where (0, 0) doesn't animate?
            strongSelf.thumbView.overlayImageView.transform = transform
            strongSelf.thumbView.overlayImageView.alpha = 0
            strongSelf.thumbView.setNeedsDisplay()
            strongSelf.layoutIfNeeded()
        }
        
        let options: UIViewAnimationOptions = [
            .beginFromCurrentState,
            .curveEaseIn
        ]
        
        UIView.animate(
            withDuration: kAnimateToCenterDuration,
            delay: kSelectionPauseDuration,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.7,
            options: options,
            animations: animationBlock,
            completion: completion
        )
    }

    private func completeDrag(fromOffset offset: CGFloat) {
        if offset > kSelectionThreshold {
            feedbackGenerator?.selectionChanged()
            animateThumbToEdge(fromOffset: offset) { [weak self] success in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.startSlider(strongSelf, didChangeSelection: .up)
                print("up")
                strongSelf.feedbackGenerator?.selectionChanged()
                strongSelf.animateThumbToCenter(fromOffset: offset, completion: { success in
                    //
                })
            }
        } else if offset < -kSelectionThreshold {
            feedbackGenerator?.selectionChanged()
            animateThumbToEdge(fromOffset: offset) { [weak self] success in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.startSlider(strongSelf, didChangeSelection: .down)
                print("down")
                strongSelf.feedbackGenerator?.selectionChanged()
                strongSelf.animateThumbToCenter(fromOffset: offset, completion: { success in
                    //
                })
            }
        }
        else {
            animateThumbToCenter(fromOffset: offset) { success in
                //
            }
        }
    }
    
    private func animateTrack(fingerDown: Bool) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .beginFromCurrentState, animations: { [weak self] in
            guard let strongSelf = self else { return }
            
            let newHeight = strongSelf.isFingerDown ? strongSelf.kTrackHeightSmall : strongSelf.kTrackHeightLarge
            let newCornerRadius = strongSelf.isFingerDown ? strongSelf.kTrackHeightSmall / 2 : strongSelf.kTrackHeightLarge / 2
            strongSelf.trackHeightConstraint?.constant = newHeight
            strongSelf.trackView.layer.cornerRadius = newCornerRadius
            strongSelf.layoutIfNeeded()
            }, completion: nil)
    }
    
    private func updateUI() {
        thumbView.layer.cornerRadius = thumbView.bounds.height / 2
        blobView.layer.cornerRadius = blobView.bounds.height / 2
        
        // Animate blob offset
        blobCenterXConstraint?.constant = { [weak self] in
            guard let strongSelf = self else { return 0 }
            let normalizedValue: CGFloat = min(1, abs(strongSelf.currentOffsetFromCenter))
            return ((currentOffsetFromCenter > 0) ? -normalizedValue : normalizedValue) * (kTrackHeightLarge / 2)
            }()
        
        // Animate blob width
        blobWidthConstraint?.constant = { [weak self] in
            guard let strongSelf = self else { return 0 }
            let normalizedValue: CGFloat = min(1, abs(strongSelf.currentOffsetFromCenter))
            return (normalizedValue * kTrackHeightLarge) + (kTrackHeightLarge + kThumbSize) / 2
            }()
        
        // Animate blob height
        blobHeightConstraint?.constant = { [weak self] in
            guard let strongSelf = self else { return 0 }
            let normalizedValue: CGFloat = min(1, abs(strongSelf.currentOffsetFromCenter))
            return (normalizedValue * kThumbScaleRatio) * kTrackHeightLarge
            }()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }
}

extension StartSlider: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

private class StartSliderThumbView: UIView {
    
    private let kOverlayAnimationDuration: TimeInterval = 0.3
    
    enum ThumbImageStyle {
        case plus
        case minus
        case none
    }
    
    private let mainImageView = UIImageView(frame: .zero)
    internal let overlayImageView = UIImageView(frame: .zero)
    
    private var isAnimating: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    var trackColor: UIColor {
        return UIColor(red: 246/255, green: 246/255 , blue: 246/255, alpha: 1)
    }
    
    var thumbImageStyle: ThumbImageStyle = .plus {
        didSet {
            switch thumbImageStyle {
            case .plus:
                overlayImageView.image = UIImage(named: "start-slider-large-plus")
            case .minus:
                overlayImageView.image = UIImage(named: "start-slider-large-minus")
            case .none:
                overlayImageView.image = nil
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
    }
}

class TailView: UIView {
    
    enum TailDirection: UInt {
        case left, right
    }
    
    public var tailDirection: TailDirection = .left {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var tailDelta: CGFloat = 1.1 {
        didSet {
            setNeedsDisplay()
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
    
    private func setupUI() {
        backgroundColor = .clear
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        context?.clear(rect)
        context?.setFillColor(UIColor.yellow.cgColor)
        var startingPoint: CGPoint?
        var edgePoint1: CGPoint?
        var controlPoint1: CGPoint?
        var edgePoint2: CGPoint?
        var controlPoint2: CGPoint?
        var endingPoint: CGPoint?
        
        switch tailDirection {
        case .left:
            startingPoint = CGPoint(
                x: rect.maxX,
                y: rect.minY
            )
            edgePoint1 = CGPoint(
                x: rect.minX,
                y: rect.size.height - (rect.size.height / tailDelta)
            )
            controlPoint1 = CGPoint(
                x: rect.midX,
                y: rect.size.height - (rect.size.height / tailDelta)
            )
            edgePoint2 = CGPoint(
                x: rect.minX,
                y: rect.size.height / tailDelta
            )
            controlPoint2 = CGPoint(
                x: rect.midX,
                y: rect.size.height / tailDelta
            )
            endingPoint = CGPoint(
                x: rect.maxX,
                y: rect.maxY
            )
        case .right:
            startingPoint = CGPoint(
                x: rect.minX,
                y: rect.minY
            )
            edgePoint1 = CGPoint(
                x: rect.maxX,
                y: rect.size.height - (rect.size.height / tailDelta)
            )
            controlPoint1 = CGPoint(
                x: rect.midX,
                y: rect.size.height - (rect.size.height / tailDelta)
            )
            edgePoint2 = CGPoint(
                x: rect.maxX,
                y: (rect.size.height / tailDelta)
            )
            controlPoint2 = CGPoint(
                x: rect.midX,
                y: (rect.size.height / tailDelta)
            )
            endingPoint = CGPoint(
                x: rect.minX,
                y: rect.maxY
            )
        }
        
        guard
            let ctx = context,
            let s = startingPoint,
            let e1 = edgePoint1,
            let c1 = controlPoint1,
            let e2 = edgePoint2,
            let c2 = controlPoint2,
            let e = endingPoint
            else {
                return
        }
        
        ctx.move(to: s)
        ctx.addQuadCurve(to: e1, control: c1)
        ctx.addLine(to: e2)
        ctx.addQuadCurve(to: e, control: c2)
        ctx.closePath()
        ctx.drawPath(using: .fill)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    private var lightGray: UIColor {
        return UIColor(red: 246/255, green: 246/255 , blue: 246/255, alpha: 1)
    }
    
    private var darkGray: UIColor {
        return UIColor(red: 166/255, green: 166/255, blue: 166/255, alpha: 1)
    }
}
