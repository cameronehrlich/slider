//
//  ViewController.swift
//  Slider
//
//  Created by Cameron Ehrlich on 7/19/18.
//  Copyright © 2018 Fair. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let values = [200, 252, 253, 750, 1000, 1500, 2000, 22000]
    var selectedIndex = 0
    
    lazy var ticker = PriceTicker(frame: .zero, initialValue: values[selectedIndex])
    lazy var recurringPaymentLabel = PaymentLoadingView(frame: .zero, initialValue: values[selectedIndex])

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let slider2 = ToggleSlider(frame: .zero)
        slider2.delegate = self
        slider2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider2)
        slider2.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        slider2.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        slider2.widthAnchor.constraint(equalToConstant: view.bounds.width).isActive = true
        slider2.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        ticker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ticker)
        ticker.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        ticker.heightAnchor.constraint(equalToConstant: 50).isActive = true
        ticker.bottomAnchor.constraint(equalTo: slider2.topAnchor).isActive = true
        
        view.addSubview(recurringPaymentLabel)
        recurringPaymentLabel.translatesAutoresizingMaskIntoConstraints = false
        recurringPaymentLabel.widthAnchor.constraint(equalToConstant: 250).isActive = true
        recurringPaymentLabel.heightAnchor.constraint(equalToConstant: 55).isActive = true
        recurringPaymentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        recurringPaymentLabel.bottomAnchor.constraint(equalTo: ticker.topAnchor, constant: -80).isActive = true
    }
}

extension ViewController: ToggleSliderDelegate {
    func toggleSlider(_ toggleSlider: ToggleSlider, didChangeSelection selection: ToggleSlider.SliderSelection) {
        switch selection {
        case .up:
            if selectedIndex + 1 < values.count {
                selectedIndex += 1
                print("up")
            }
        case .down:
            if selectedIndex - 1 >= 0 {
                selectedIndex -= 1
                print("down")
            }
        }
        
        let newValue = values[selectedIndex]
        ticker.setValue(newValue)
        recurringPaymentLabel.setValue(newValue)
    }
}

