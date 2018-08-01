//
//  ViewController.swift
//  Slider
//
//  Created by Cameron Ehrlich on 7/19/18.
//  Copyright © 2018 Fair. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        let frame1 = CGRect(x: 0,
//                           y: view.bounds.height/2,
//                           width: view.bounds.width,
//                           height: 100)
//        let slider1 = StartSlider(frame: frame1)
//        view.addSubview(slider1)
        
        let slider2 = ToggleSlider(frame: .zero)
        slider2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider2)
        slider2.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        slider2.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        slider2.widthAnchor.constraint(equalToConstant: view.bounds.width).isActive = true
        slider2.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

