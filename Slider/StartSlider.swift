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
    private var kTrackHeightLarge: CGFloat = 45
    private var kTrackInset: CGFloat = 40
    private var kThumbSize: CGFloat = 50
    private var kSideIconImageSize: CGFloat = 30
    private var kSelectionThreshold: CGFloat = 0.8
    
    private var startingValue = 0.5
    private var hasAnimatedSideIconsForSwipe: Bool = false
    
    private var animator: UIDynamicAnimator?
    private var feedbackGenerator: UISelectionFeedbackGenerator?
    
    private lazy var snapBehavior: UISnapBehavior = {
        let b = UISnapBehavior(item: thumbView, snapTo: startingPoint)
        b.damping = 0.3
        return b
    }()
    
    private lazy var noRotationBehavior: UIDynamicItemBehavior = {
        let b = UIDynamicItemBehavior(items: [thumbView])
        b.allowsRotation = false
        return b
    }()
    
    private var isFingerDown: Bool = false {
        willSet {
            if newValue != isFingerDown {
                animateTrack(fingerDown: newValue)
                animateThumb(fingerDown: newValue)
            }
        }
        didSet {
            if !isFingerDown {
                hasAnimatedSideIconsForSwipe = false
                UIView.animate(withDuration: 0.2) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.thumbView.overlayImageView.alpha = 0
                    strongSelf.leadingIconImageView.transform = .identity
                    strongSelf.leadingIconImageView.tintColor = strongSelf.darkGray
                    strongSelf.trailingIconImageView.transform = .identity
                    strongSelf.trailingIconImageView.tintColor = strongSelf.darkGray
                }
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
    private lazy var thumbView: StartSliderThumbView = {
        let v = StartSliderThumbView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = lightGray
        v.isUserInteractionEnabled = false
       return v
    }()
    
    private lazy var leadingIconImageView: UIImageView = {
        let v = UIImageView (frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.image = UIImage(named: "start-slider-small-minus")?.withRenderingMode(.alwaysTemplate)
        v.tintColor = darkGray
        v.contentMode = .center
        return v
    }()

    private lazy var trailingIconImageView: UIImageView = {
        let v = UIImageView (frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.image = UIImage(named: "start-slider-small-plus")?.withRenderingMode(.alwaysTemplate)
        v.tintColor = darkGray
        v.contentMode = .center
        return v
    }()
    
    private var minValue: CGFloat {
        return kTrackInset + kThumbSize
    }
    
    private var maxValue: CGFloat {
        return bounds.width - kTrackInset - kThumbSize
    }
    
    private var startingPoint: CGPoint {
        return CGPoint(x: (minValue + maxValue) / 2, y: bounds.height / 2)
    }
    
    private var trackWidth: CGFloat {
        return bounds.width - (2 * kTrackInset) - (2 * kThumbSize)
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
        trackHeightConstraint = trackView.heightAnchor.constraint( equalTo: heightAnchor, multiplier: 0, constant: kTrackHeightSmall)
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
        thumbView.widthAnchor.constraint(equalToConstant: kThumbSize).isActive = true
        thumbView.heightAnchor.constraint(equalToConstant: kThumbSize).isActive = true
        thumbHorizontalConstraint = thumbView.centerXAnchor.constraint(equalTo: leadingAnchor)
        thumbHorizontalConstraint?.isActive = true

        animator = UIDynamicAnimator(referenceView: self)
        thumbHorizontalConstraint?.constant = positionForValue(startingPoint)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        thumbView.layer.cornerRadius = thumbView.bounds.width/2
    }
    
    // MARK: Touch handling
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)
        if thumbView.frame.contains(touchPoint) {
            isFingerDown = true
            animator?.removeAllBehaviors()
            feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator?.prepare()
        }
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isFingerDown else {
            return false
        }
        
        let touchPoint = touch.location(in: self)
        thumbHorizontalConstraint?.constant = positionForValue(touchPoint)
        
        var newimage: UIImage?
        if touchPoint.x < startingPoint.x {
            newimage = UIImage(named: "start-slider-large-minus")
        } else {
            newimage = UIImage(named: "start-slider-large-plus")
        }
        
        if thumbView.overlayImageView.image != newimage {
           thumbView.overlayImageView.image = newimage
        }
        
        let currentOffsetFromCenter: CGFloat = (touchPoint.x - startingPoint.x) / (trackView.bounds.width/2)
        let thumbImageAlpha: CGFloat = abs(currentOffsetFromCenter)
        thumbView.overlayImageView.alpha = thumbImageAlpha
        
        let sideIconAnimationThreshold: CGFloat = 0.4
        
        if abs(currentOffsetFromCenter) > sideIconAnimationThreshold {
            if !hasAnimatedSideIconsForSwipe {
                hasAnimatedSideIconsForSwipe = true
                UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
                    guard let strongSelf = self else { return }
                    let scaleUpTransform = CGAffineTransform(scaleX: 1.4, y: 1.4)
                    
                    if currentOffsetFromCenter > 0 {
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
        guard let touch = touch else {
            completeDragWithOffset(0)
            return
        }
        let touchPoint = touch.location(in: self)
        let currentOffsetFromCenter: CGFloat = (touchPoint.x - startingPoint.x) / (trackView.bounds.width/2)
        completeDragWithOffset(currentOffsetFromCenter)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        completeDragWithOffset(0)
    }
    
    // MARK: Helpers

    private func positionForValue(_ touchPoint: CGPoint) -> CGFloat {
        if touchPoint.x <= minValue {
            return minValue
        }
        else if touchPoint.x >= maxValue {
            return maxValue
        }
        else {
            return touchPoint.x
        }
    }
    
    private func completeDragWithOffset(_ offset: CGFloat) {
        
        isFingerDown = false
        
        animator?.addBehavior(snapBehavior)
        animator?.addBehavior(noRotationBehavior)
        
        if offset > kSelectionThreshold {
            feedbackGenerator?.selectionChanged()
            delegate?.startSlider(self, didChangeSelection: .up)
        }
        else if offset < -kSelectionThreshold {
            feedbackGenerator?.selectionChanged()
            delegate?.startSlider(self, didChangeSelection: .up)
        }
    }
    
    private func animateTrack(fingerDown: Bool) {
        setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .beginFromCurrentState, animations: { [weak self] in
            guard let strongSelf = self else { return }
            
            let newHeight = strongSelf.isFingerDown ? strongSelf.kTrackHeightSmall : strongSelf.kTrackHeightLarge
            let newCornerRadius = strongSelf.isFingerDown ? strongSelf.kTrackHeightSmall / 2 : strongSelf.kTrackHeightLarge / 2
            strongSelf.trackHeightConstraint?.constant = newHeight
            strongSelf.trackView.layer.cornerRadius = newCornerRadius
            
            strongSelf.layoutIfNeeded()
            }, completion: nil)
    }
    
    private func animateThumb(fingerDown: Bool) {
        setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .beginFromCurrentState, animations: { [weak self] in
            guard let strongSelf = self else { return }
            if fingerDown {
                let t = CGAffineTransform(scaleX: 1.3, y: 1.3)
                strongSelf.thumbView.backgroundColorView.transform = t
            } else {
                let t: CGAffineTransform = .identity
                strongSelf.thumbView.backgroundColorView.transform = t
            }
            strongSelf.layoutIfNeeded()
            }, completion: nil)
    }
}

extension StartSlider: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

private class StartSliderThumbView: UIView {
    
    internal let backgroundColorView = UIView()
    internal let mainImageView = UIImageView(frame: .zero)
    internal let overlayImageView = UIImageView(frame: .zero)
    
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
    
    private func setupUI() {
        
        addSubview(backgroundColorView)
        backgroundColorView.backgroundColor = trackColor
        backgroundColorView.translatesAutoresizingMaskIntoConstraints = false
        backgroundColorView.widthAnchor.constraint(equalTo: widthAnchor, constant: 0).isActive = true
        backgroundColorView.heightAnchor.constraint(equalTo: heightAnchor, constant: 0).isActive = true
        backgroundColorView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        backgroundColorView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        
        addSubview(mainImageView)
        mainImageView.image = #imageLiteral(resourceName: "start-slider-thumb")
        mainImageView.contentMode = .scaleAspectFill
        mainImageView.translatesAutoresizingMaskIntoConstraints = false
        mainImageView.widthAnchor.constraint(equalTo: widthAnchor, constant: 0).isActive = true
        mainImageView.heightAnchor.constraint(equalTo: heightAnchor, constant: 0).isActive = true
        mainImageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        mainImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        mainImageView.layer.shadowColor = UIColor.black.cgColor
        mainImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        mainImageView.layer.shadowRadius = 4
        mainImageView.layer.shadowOpacity = 0.2
        
        addSubview(overlayImageView)
        mainImageView.contentMode = .scaleAspectFit
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayImageView.widthAnchor.constraint(equalTo: widthAnchor, constant: 0).isActive = true
        overlayImageView.heightAnchor.constraint(equalTo: widthAnchor, constant: 0).isActive = true
        overlayImageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        overlayImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColorView.layer.cornerRadius = backgroundColorView.bounds.width/2
    }
}
