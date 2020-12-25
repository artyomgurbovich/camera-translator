//
//  UIViewController+Alert.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 10/11/20.
//

import UIKit

extension UIViewController {
    public func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alertController, animated: true)
    }
}
