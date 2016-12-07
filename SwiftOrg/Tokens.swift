//
//  Tokens.swift
//  CocoaOrg
//
//  Created by Xiaoxing Hu on 13/09/16.
//  Copyright © 2016 Xiaoxing Hu. All rights reserved.
//

import Foundation


public struct TokenMeta {
    public let raw: String?
    public let lineNumber: Int
}

typealias TokenWithMeta = (TokenMeta, Token)

public enum Token {
    case setting(key: String, value: String?)
    case headline(stars: Int, text: String?)
    case blank
    case horizontalRule
    case blockBegin(name: String, params: [String]?)
    case blockEnd(name: String)
    case drawerBegin(name: String)
    case drawerEnd
    case listItem(indent: Int, text: String?, ordered: Bool, checked: Bool?)
    case comment(String?)
    case line(text: String)
    case footnote(label: String, content: String?)
}

typealias TokenGenerator = ([String?]) -> Token?

var tokenList: [(String, NSRegularExpression.Options, TokenGenerator)] = []

func define(_ pattern: String, options: NSRegularExpression.Options = [], generator: @escaping TokenGenerator) {
    tokenList.append((pattern, options, generator))
}

func defineTokens() {
    if tokenList.count > 0 {return}
    
    define("^\\s*$") { _ in .blank }
    define("^#\\+([a-zA-Z_]+):\\s*(.*)$") { matches in
        .setting(key: matches[1]!, value: matches[2]) }
    define("^(\\*+)\\s+(.*)$") { matches in
        .headline(stars: matches[1]!.characters.count, text: matches[2]) }
    define("^(\\s*)#\\+begin_([a-z]+)(?:\\s+(.*))?$", options: [.caseInsensitive]) { matches in
        var params: [String]?
        if let m3 = matches[3] {
            params = m3.characters.split{$0 == " "}.map(String.init)
        }
        return .blockBegin(name: matches[2]!, params: params) }
    define("^(\\s*)#\\+end_([a-z]+)$", options: [.caseInsensitive]) { matches in
        .blockEnd(name: matches[2]!) }
    define("^(\\s*):end:\\s*$", options: [.caseInsensitive]) { _ in .drawerEnd }
    define("^(\\s*):([a-z]+):\\s*$", options: [.caseInsensitive]) { matches in
        .drawerBegin(name: matches[2]!) }
    define("^(\\s*)([-+*]|\\d+(?:\\.|\\)))\\s+(?:\\[([ X-])\\]\\s+)?(.*)$") { matches in
        var ordered = true
        if let m = matches[2] {
            ordered = !["-", "+", "*"].contains(m)
        }
        var checked: Bool? = nil
        if let m = matches[3] {
            checked = m == "X"
        }
        return .listItem(indent: length(matches[1]), text: matches[4], ordered: ordered, checked: checked) }
    define("^\\s*-{5,}$") { _ in .horizontalRule }
    define("^\\s*#\\s+(.*)$") { matches in
        .comment(matches[1]) }
    define("^\\[fn:(\\d+)\\](?:\\s+(.*))?$") { matches in
        .footnote(label: matches[1]!, content: matches[2])
    }
    define("^(\\s*)(.*)$") { matches in
        .line(text: matches[2]!) }
}
