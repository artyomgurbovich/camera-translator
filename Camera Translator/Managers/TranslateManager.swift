//
//  TranslateManager.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 11/5/20.
//

import Foundation
import Alamofire
import SwiftyJSON

final class TranslateManager {
    let fromLanguages: [Language]
    let toLanguages: [Language]
    var onTranslate: (([TextBox]) -> Void)?
    private(set) var currentFromLanguage: Language!
    private(set) var currentToLanguage: Language!
    private(set) var isTranslating = false
    private let mainQueue = DispatchQueue.main
    private let queue = DispatchQueue(label: "TranslateManager", qos: .background)
    private var currentTranslatingTextBoxes = [TextBox]()
    private let translateURL = "https://api.mymemory.translated.net/get"
    private let email = ""
    
    init?(fromLanguages: [Language], toLanguages: [Language]) {
        guard !fromLanguages.isEmpty, !toLanguages.isEmpty else { return nil }
        self.fromLanguages = fromLanguages.sorted()
        self.toLanguages = toLanguages.sorted()
        currentFromLanguage = self.fromLanguages.first
        currentToLanguage = self.toLanguages.first
    }
    
    func setCurrentLanguage(ofType type: LanguageTranslationType, by index: Int) {
        guard index >= .zero, (type == .from ? fromLanguages : toLanguages).count > index else { return }
        type == .from ? (currentFromLanguage = fromLanguages[index]) : (currentToLanguage = toLanguages[index])
    }
    
    func getLanguageIndex(ofType type: LanguageTranslationType, by code: String) -> Int? {
        guard let language = Language(code: code) else { return nil }
        return (type == .from ? fromLanguages : toLanguages).firstIndex(of: language)
    }
    
    func stopTranslate() {
        mainQueue.async {
            self.isTranslating = false
        }
    }
    
    func translate(textBoxes: [TextBox]) {
        mainQueue.async {
            guard !self.isTranslating else { return }
            self.isTranslating = true
            self.currentTranslatingTextBoxes = textBoxes
            self.translateNext(index: .zero)
        }
    }
    
    func translateNext(index: Int) {
        mainQueue.async {
            guard self.isTranslating else { return }
            guard index < self.currentTranslatingTextBoxes.count else {
                self.onTranslate?(self.currentTranslatingTextBoxes)
                self.isTranslating = false
                return
            }
            let parameters = ["q": self.currentTranslatingTextBoxes[index].text,
                              "langpair": "\(self.currentFromLanguage.code)|\(self.currentToLanguage.code)",
                              "de": self.email]
            self.queue.async {
                AF.request(self.translateURL, parameters: parameters).responseJSON { response in
                    self.mainQueue.async {
                        guard self.isTranslating,
                              let value = response.value,
                              let text = JSON(value)["responseData"]["translatedText"].string else { return }
                        self.currentTranslatingTextBoxes[index].text = text
                        self.translateNext(index: index + 1)
                    }
                }
            }
        }
    }
}

extension TranslateManager {
    enum LanguageTranslationType {
        case from, to
    }
}
