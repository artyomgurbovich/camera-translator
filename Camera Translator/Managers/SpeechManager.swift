//
//  SpeechManager.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 10/11/20.
//

import AVFoundation

final class SpeechManager {
    private let queue = DispatchQueue(label: "SpeechManager", qos: .background)
    private let synthesizer: AVSpeechSynthesizer
    
    init?() {
        guard !SpeechManager.availableLanguages.isEmpty else { return nil }
        synthesizer = AVSpeechSynthesizer()
    }
    
    func speak(text: String, language: Language) {
        queue.async {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: language.code)
            utterance.rate = 0.45
            self.synthesizer.speak(utterance)
        }
    }
    
    func speak(textBoxes: [TextBox], language: Language) {
        queue.async {
            textBoxes.forEach{self.speak(text: $0.text, language: language)}
        }
    }
    
    func stopSpeaking() {
        queue.async {
            guard self.synthesizer.isSpeaking else { return }
            self.synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

extension SpeechManager {
    static var availableLanguages: [Language] {
        return Language.fromCodes(AVSpeechSynthesisVoice.speechVoices().map{$0.language}).sorted()
    }
}
