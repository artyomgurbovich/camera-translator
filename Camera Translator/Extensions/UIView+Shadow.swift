//
//  UIView+Shadow.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 10/6/20.
//

import UIKit

extension UIView {
    public func addShadow() {
        layer.shadowOpacity = 1
        layer.shadowRadius = 1
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize()
    }
}
