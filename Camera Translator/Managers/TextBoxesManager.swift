//
//  TextBlocksManager.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 11/2/20.
//

import UIKit

final class TextBoxesManager {
    private let rectWidth: CGFloat

    init?(rectWidth: CGFloat) {
        guard rectWidth > .zero else { return nil }
        self.rectWidth = rectWidth
    }
    
    func updateLayout(textBoxes: [TextBox]) -> [CATextLayer] {
        var layers = [CATextLayer]()
        for i in 0..<textBoxes.count {
            var leftFreeSpace: CGFloat = .zero
            var rightFreeSpace: CGFloat = .zero
            if i > .zero && (abs(textBoxes[i].rect.midY - textBoxes[i - 1].rect.midY) < (textBoxes[i].rect.height / 2 + textBoxes[i - 1].rect.height / 2)) {
                leftFreeSpace = textBoxes[i].rect.minX - textBoxes[i - 1].rect.maxX
            } else {
                leftFreeSpace = textBoxes[i].rect.minX
            }
            if i < textBoxes.count - 1 && (abs(textBoxes[i].rect.midY - textBoxes[i + 1].rect.midY) < (textBoxes[i].rect.height / 2 + textBoxes[i + 1].rect.height / 2)) {
                rightFreeSpace = textBoxes[i + 1].rect.minX - textBoxes[i].rect.maxX
            } else {
                rightFreeSpace = rectWidth - textBoxes[i].rect.maxX
            }
            let layer = CATextLayer()
            layer.alignmentMode = .center
            layer.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6669910282)
            layer.foregroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            layer.string = textBoxes[i].text
            layer.font = UIFont(name: "Menlo", size: .zero)
            layer.fontSize = textBoxes[i].rect.height * 0.99
            while (textBoxes[i].text as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "Menlo", size: layer.fontSize)!]).width > (textBoxes[i].rect.width + rightFreeSpace + leftFreeSpace) || layer.fontSize > 14 {
                layer.fontSize *= 0.99
            }
            var missingWidth = layer.preferredFrameSize().width - textBoxes[i].rect.width
            if missingWidth > .zero {
                var leftAddSpace: CGFloat = .zero
                var rightAddSpace: CGFloat = .zero
                if leftFreeSpace >= missingWidth / 2 && rightFreeSpace >= missingWidth / 2 {
                    leftAddSpace = leftFreeSpace - missingWidth / 2
                    rightAddSpace = rightFreeSpace - missingWidth / 2
                } else if leftFreeSpace >= missingWidth / 2 {
                    missingWidth -= rightFreeSpace
                    leftAddSpace = missingWidth
                    rightAddSpace = rightFreeSpace
                } else if rightFreeSpace >= missingWidth / 2 {
                    missingWidth -= leftFreeSpace
                    rightAddSpace = missingWidth
                    leftAddSpace = leftFreeSpace
                }
                let newWidth = leftAddSpace + textBoxes[i].rect.width + rightAddSpace
                print(newWidth)
                let newX = textBoxes[i].rect.minX - ((leftAddSpace + rightAddSpace) / 2)
                layer.frame = CGRect(x: newX, y: textBoxes[i].rect.midY, width: newWidth, height: layer.preferredFrameSize().height)
            } else {
                layer.frame = CGRect(x: textBoxes[i].rect.minX, y: textBoxes[i].rect.minY, width: textBoxes[i].rect.width, height: layer.preferredFrameSize().height)
            }
            layer.cornerRadius = layer.bounds.height / 8
            layers.append(layer)
        }
        return layers
    }
}
