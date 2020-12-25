//
//  TextBox.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 10/19/20.
//

import CoreGraphics

public class TextBox {
    public var text: String
    public var rect: CGRect
    
    init(text: String, rect: CGRect) {
        self.text = text
        self.rect = rect
    }
}
