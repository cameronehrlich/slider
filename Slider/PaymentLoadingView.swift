//
//  PaymentLoadingView.swift
//  fair
//
//  Created by Cameron Ehrlich on 8/1/18.
//  Copyright © 2018 Fair. All rights reserved.
//

import UIKit

private let kLabelFadeAnimationDuration: Double = 0.25
private let kWiggleAnimationDuration: Double = 1.55
private let kDotSize: CGFloat = 6

class PaymentLoadingView: UIView {

    private var currentValue: Int = 0

    private lazy var valueLabel: UILabel = {
        let l = UILabel(frame: .zero)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .left
        l.font = UIFont.systemFont(ofSize: 55, weight: .light)
        l.textColor = UIColor.orange
        return l
    }()
    
    private lazy var frequencyLabel: UILabel = {
        let l = UILabel(frame: .zero)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .left
        l.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        l.textColor = UIColor.gray
        l.text = "/ Mo."
        return l
    }()
    
    convenience init(frame: CGRect, initialValue: Int = 500) {
        self.init(frame: frame)
        currentValue = initialValue
        setupUI()
    }
    
    private func setupUI() {
        addSubview(valueLabel)
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            ])
        
        addSubview(frequencyLabel)
        NSLayoutConstraint.activate([
            frequencyLabel.topAnchor.constraint(equalTo: topAnchor),
            frequencyLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 20),
            frequencyLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            frequencyLabel.leadingAnchor.constraint(equalTo: valueLabel.trailingAnchor, constant: 2),
            frequencyLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
            ])
        
        valueLabel.text = "$\(currentValue)"
    }
    
    public func setValue(_ newValue: Int) {
        currentValue = newValue
        
        let hideLabelsAnimation = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.valueLabel.alpha = 0
            strongSelf.frequencyLabel.alpha = 0

        }
        
        let showLabelsAnimation = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.valueLabel.alpha = 1
            strongSelf.frequencyLabel.alpha = 1
        }
        
        animateWiggles { _ in
            //
        }
        
        UIView.animate(
            withDuration: kLabelFadeAnimationDuration,
            delay: 0,
            options: [],
            animations: hideLabelsAnimation) { [weak self] success in
                
                guard let strongSelf = self else { return }
                strongSelf.valueLabel.text = "$\(newValue)"
                
                UIView.animate(
                    withDuration: kLabelFadeAnimationDuration,
                    delay: kWiggleAnimationDuration - (kLabelFadeAnimationDuration / 2),
                    options: [],
                    animations: showLabelsAnimation,
                    completion: nil)
        }
    }
    
    private func animateWiggles(_ completion: @escaping (Bool) -> ()) {
        
        let dot1 = DotView(frame: .zero)
        let dot2 = DotView(frame: .zero)
        let dot3 = DotView(frame: .zero)
        let dot4 = DotView(frame: .zero)
        
        addSubview(dot1)
        addSubview(dot2)
        addSubview(dot3)
        addSubview(dot4)
        
        let dotWidth = valueLabel.frame.size.width / 4

        NSLayoutConstraint.activate([
            dot1.widthAnchor.constraint(equalToConstant: dotWidth),
            dot1.leadingAnchor.constraint(equalTo: valueLabel.leadingAnchor),
            dot1.topAnchor.constraint(equalTo: valueLabel.topAnchor),
            dot1.bottomAnchor.constraint(equalTo: valueLabel.bottomAnchor),
            
            dot2.widthAnchor.constraint(equalToConstant: dotWidth),
            dot2.leadingAnchor.constraint(equalTo: dot1.trailingAnchor),
            dot2.topAnchor.constraint(equalTo: valueLabel.topAnchor),
            dot2.bottomAnchor.constraint(equalTo: valueLabel.bottomAnchor),
            
            dot3.widthAnchor.constraint(equalToConstant: dotWidth),
            dot3.leadingAnchor.constraint(equalTo: dot2.trailingAnchor),
            dot3.topAnchor.constraint(equalTo: valueLabel.topAnchor),
            dot3.bottomAnchor.constraint(equalTo: valueLabel.bottomAnchor),
            
            dot4.widthAnchor.constraint(equalToConstant: dotWidth),
            dot4.leadingAnchor.constraint(equalTo: dot3.trailingAnchor),
            dot4.topAnchor.constraint(equalTo: valueLabel.topAnchor),
            dot4.bottomAnchor.constraint(equalTo: valueLabel.bottomAnchor),
            ])
        
        let dots = [dot1, dot2, dot3, dot4]
        for d in dots {
            d.wiggle()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + kWiggleAnimationDuration) {
            dots.forEach { $0.removeFromSuperview() }
            completion(true)
        }
    }
}

private class DotView: UIView {
    
    private var dotCenterYConstraint: NSLayoutConstraint?
    private lazy var dot: UIView = {
        let v = UIView(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.orange
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(dot)
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: kDotSize),
            dot.heightAnchor.constraint(equalToConstant: kDotSize),
            dot.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])
        dotCenterYConstraint = dot.centerYAnchor.constraint(equalTo: centerYAnchor)
        dotCenterYConstraint?.isActive = true
        
        // Put in initial state
        dot.alpha = 0
        dotCenterYConstraint?.constant = -randomInRange(range: 10...20)
        layoutIfNeeded()
    }
    
    public func wiggle() {
        
        let numFrames = 5
        let frameDuration = kWiggleAnimationDuration / Double(numFrames)
        let animations = {
            for i in 0...numFrames {
                UIView.addKeyframe(
                    withRelativeStartTime: Double(i) * frameDuration,
                    relativeDuration: frameDuration,
                    animations: {
                        if i == 0 {
                            self.dot.alpha = 1
                        }
                        else if i == numFrames {
                            self.dot.alpha = 0
                        }
                        
                        let amount = ((i % 2 == 0) ? 1 : -1) * self.randomInRange(range: 10...30)
                        self.dotCenterYConstraint?.constant = amount
                        self.layoutIfNeeded()
                })
            }
        }
        UIView.animateKeyframes(
            withDuration: kWiggleAnimationDuration,
            delay: Double(randomInRange(range: 1...2)) / 3,
            options: .beginFromCurrentState,
            animations: animations,
            completion: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dot.layer.cornerRadius = dot.frame.height / 2
    }
    
    func randomInRange(range: CountableClosedRange<Int>) -> CGFloat {
        return CGFloat(Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound))) + range.lowerBound)
    }
}
