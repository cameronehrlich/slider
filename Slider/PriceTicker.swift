//
//  PriceTicker.swift
//  fair
//
//  Created by Cameron Ehrlich on 8/1/18.
//  Copyright © 2018 Fair. All rights reserved.
//

import UIKit

private let kAnimationDuration: Double = 0.6
private let kDigitWidth: CGFloat = 30
private let kMaxSupportedDigits = 5
private let kFont = UIFont.systemFont(ofSize: 45, weight: .light)

class PriceTicker: UIView {
    
    public private(set) var value: Int = 0
    
    private lazy var symbolView: UILabel = {
        let l = UILabel(frame: .zero)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "$"
        l.textAlignment = .right
        l.font = kFont
        return l
    }()
    
    private var digitViews: [DigitView] = []
    
    private var stackViewCenterXConstraint: NSLayoutConstraint?
    private lazy var stackView: UIStackView = {
       let s = UIStackView(frame: .zero)
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.distribution = .equalSpacing
        return s
    }()
    
    convenience init(frame: CGRect, initialValue: Int) {
        self.init(frame: frame)
        self.value = initialValue
        for _ in 0...kMaxSupportedDigits {
            let newDigitView = DigitView(frame: .zero)
            digitViews.append(newDigitView)
            stackView.addArrangedSubview(newDigitView)
        }
        setupUI()
    }
    
    private func setupUI() {
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: kDigitWidth / 2)
            ])
        
        addSubview(symbolView)
        NSLayoutConstraint.activate([
            symbolView.topAnchor.constraint(equalTo: topAnchor),
            symbolView.bottomAnchor.constraint(equalTo: bottomAnchor),
            symbolView.widthAnchor.constraint(equalToConstant: kDigitWidth),
            symbolView.trailingAnchor.constraint(equalTo: stackView.leadingAnchor)
            ])
        
        UIView.performWithoutAnimation {
            setValue(value)
        }
    }
    
    func setValue(_ value: Int, completion: ((Bool) ->())? = nil) {
        var previousDigits = "\(self.value)".compactMap { Int(String($0)) }
        var newDigits = "\(value)".compactMap { Int(String($0)) }
        
        self.value = value
        
        let digitsToRefresh = newDigits.count
        
        let updateStackView = { [weak self] in
            guard let strongSelf = self else { return }
            var i = 0
            strongSelf.digitViews.reversed().forEach { v in
                v.isHidden = !(i < digitsToRefresh)
                i += 1
            }
        }
        
        for view in digitViews.reversed() {
            let newValue = newDigits.popLast()
            let oldValue = previousDigits.popLast()
            view.transitionTo(
                newValue,
                from: oldValue,
                transitionDirection: .automatic,
                animated: true,
                midway: updateStackView,
                completion: completion)
        }
    }
}

private class DigitView: UIView {
    
    enum TransitionDirection {
        case up, down, automatic
    }
    
    private var labelCenterYConstraint: NSLayoutConstraint?
    private lazy var label: UILabel = {
        let l = UILabel(frame: .zero)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isUserInteractionEnabled = false
        l.textAlignment = .center
        l.textColor = .black
        l.font = kFont
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        label.backgroundColor = .clear
        addSubview(label)
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: kDigitWidth),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])
        labelCenterYConstraint = label.centerYAnchor.constraint(equalTo: centerYAnchor)
        labelCenterYConstraint?.isActive = true
    }
    
    public func transitionTo(_ toValue: Int?,
                             from fromValue: Int?,
                             transitionDirection: TransitionDirection,
                             animated: Bool,
                             midway: @escaping () -> (),
                             completion: ((Bool) -> ())? = nil) {
        
        let fromString = (fromValue != nil) ? "\(fromValue!)" : ""
        let toString = (toValue != nil) ? "\(toValue!)" : ""
        
        guard animated else {
            // return early, no animation needed
            label.text = toString
            completion?(true)
            return
        }
        
        var animatesUp: Bool = false
        
        if let toValue = toValue, let fromValue = fromValue {
            
            switch transitionDirection {
            case .up:
                animatesUp = true
            case .down:
                animatesUp = false
            case .automatic:
                animatesUp = (toValue > fromValue)
            }
        }
        
        let translationAmount = label.bounds.height / 2
        let hideDigitOffset = animatesUp ? -translationAmount : translationAmount
        let showDigitOffset = animatesUp ? translationAmount : -translationAmount
        
        let hideAnimations = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.label.alpha = 0
            strongSelf.labelCenterYConstraint?.constant = hideDigitOffset
            strongSelf.layoutIfNeeded()
        }
        
        let showAnimations = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.label.alpha = 1
            strongSelf.labelCenterYConstraint?.constant = 0
            strongSelf.layoutIfNeeded()
        }
        
        let hideOptions: UIViewAnimationOptions = [.beginFromCurrentState, .curveEaseIn]
        let showOptions: UIViewAnimationOptions = [.beginFromCurrentState, .curveEaseOut]
        
        label.text = fromString
        
        UIView.animate(
            withDuration: kAnimationDuration / 2,
            delay: 0,
            options: hideOptions,
            animations: hideAnimations) { [weak self] _ in
                guard let strongSelf = self else { return }
                
                strongSelf.labelCenterYConstraint?.constant = showDigitOffset
                strongSelf.label.text = toString
                strongSelf.layoutIfNeeded()
                
                midway()
                
                UIView.animate(
                    withDuration:
                    kAnimationDuration / 2,
                    delay: kAnimationDuration / 6,
                    options: showOptions,
                    animations: showAnimations,
                    completion: completion)
        }
    }
}
