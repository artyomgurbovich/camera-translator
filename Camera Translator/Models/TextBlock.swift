//
//  TextBlock.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 10/19/20.
//

import CoreGraphics

public class TextBox {
    public var text: String
    public var rect: CGRect
    private let defaultFontSize: CGFloat
    
    var hasEnoughtWidth: Bool {
        return missingWidth <= .zero
    }
    
    var missingWidth: CGFloat {
        return expectedWidth - rect.size.width
    }
    
    var expectedWidth: CGFloat {
        return defaultFontSize * CGFloat(text.count)
    }
    
    init(text: String, rect: CGRect) {
        self.text = text
        self.rect = rect
        defaultFontSize = rect.width / CGFloat(text.count) - 0.01
    }
    
    func replaceText(_ text: String) {
        self.text = text
    }
    
    func replaceRect(_ rect: CGRect) {
        self.rect = rect
    }
}
