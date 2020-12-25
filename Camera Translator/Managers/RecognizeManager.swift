//
//  RecognizeManager.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 11/2/20.
//

import Vision

final class RecognizeManager {
    var onRecognize: (([TextBox]) -> Void)?
    private(set) var isRecognizing = false
    private let mainQueue = DispatchQueue.main
    private let queue = DispatchQueue(label: "RecognizeManager", qos: .background)
    private let recognizeRectSize: CGSize
    private var request: VNRecognizeTextRequest!
    
    init?(recognizeRectSize: CGSize) {
        guard let firstLanguage = RecognizeManager.availableLanguages.first else { return nil }
        self.recognizeRectSize = recognizeRectSize
        setRecognizeLanguage(firstLanguage)
    }
    
    func setRecognizeLanguage(_ language: Language) {
        queue.async {
            guard let languageCode = RecognizeManager.supportedLanguageCodes?.filter({$0.hasPrefix(language.code)}).first else { return }
            self.request = VNRecognizeTextRequest(completionHandler: self.handleRecognizedText)
            self.request.recognitionLevel = .fast
            self.request.recognitionLanguages = [languageCode]
        }
    }
    
    func recognize(by pixelBuffer: CVPixelBuffer) {
        queue.async {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            try? imageRequestHandler.perform([self.request])
        }
    }
    
    private func handleRecognizedText(request: VNRequest, error: Error?) {
        queue.async {
            guard error == nil,
                  let observations = request.results?.compactMap({$0 as? VNRecognizedTextObservation}),
                  observations.filter({$0.confidence < 0.97}).count == .zero else {
                self.onRecognize?([])
                return
            }
            self.mainQueue.sync {
                self.isRecognizing = true
            }
            var textBoxes = [TextBox]()
            for observation in observations {
                let recognizedText = observation.topCandidates(1)[.zero].string
                let convertedBoundingBox = self.convertCoordinates(of: observation.boundingBox)
                let textBox = TextBox(text: recognizedText, rect: convertedBoundingBox)
                textBoxes.append(textBox)
            }
            self.mainQueue.sync {
                self.onRecognize?(textBoxes)
                self.isRecognizing = false
            }
        }
    }
    
    private func convertCoordinates(of recognizedBoundingBox: CGRect) -> CGRect {
        let x = recognizedBoundingBox.minX * recognizeRectSize.width
        let y = (1 - recognizedBoundingBox.maxY) * recognizeRectSize.height
        let width = (recognizedBoundingBox.maxX - recognizedBoundingBox.minX) * recognizeRectSize.width
        let height = (recognizedBoundingBox.maxY - recognizedBoundingBox.minY) * recognizeRectSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

extension RecognizeManager {
    static var supportedLanguageCodes: [String]? {
        return try? VNRecognizeTextRequest.supportedRecognitionLanguages(for: .fast, revision: 2)
    }
    
    static var availableLanguages: [Language] {
        guard let languagesCodes = supportedLanguageCodes else { return [] }
        return Language.fromCodes(languagesCodes)
    }
}
