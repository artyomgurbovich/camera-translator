//
//  Language.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 9/24/20.
//

import Foundation

public struct Language {
    let name: String
    let code: String
    
    init?(code: String) {
        guard let name = Locale(identifier: "en").localizedString(forLanguageCode: code) else { return nil }
        guard let formattedCode = Language.formatCode(code: code) else { return nil }
        self.name = name
        self.code = formattedCode
    }
}

extension Language: Hashable, Equatable, Comparable {
    public static func fromCodes(_ codes: [String]) -> [Language] {
        return Array(Set(codes.compactMap{Language(code: $0)}))
    }
    
    public static func formatCode(code: String) -> String? {
        guard let codeWithoutDash = code.split(separator: "-").first else { return nil }
        guard let codeWithoutUnderscore = codeWithoutDash.split(separator: "_").first else { return nil }
        return String(codeWithoutUnderscore)
    }
    
    public static func < (lhs: Language, rhs: Language) -> Bool {
        return lhs.name != rhs.name ? lhs.name < rhs.name : lhs.code < rhs.code
    }
}
