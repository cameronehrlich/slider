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
        let frame = CGRect(x: 0,
                           y: view.bounds.height/2,
                           width: view.bounds.width,
                           height: 100)
        let slider = StartSlider(frame: frame)
        view.addSubview(slider)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

