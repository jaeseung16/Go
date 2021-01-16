//
//  SGFDecoder.swift
//  Go
//
//  Created by Jae Seung Lee on 1/8/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

class SGFParser {
    static let gameTreeStart = "\\s*\\("
    static let gameTreeEnd = "\\s*\\)"
    static let gameTreeNext = "\\s*(;|\\(|\\))"
    static let nodeContents = "\\s*([A-Za-z]+(?=\\s*\\[))"
    static let propertyStart = "\\s*\\["
    static let propertyEnd = "\\]"
    static let escape = "\\\\"
    static let lineBreak = "\\r\\n?|\\n\\r"
    
    var data: String
    var dataLen: Int
    var index: Int
    var gameTrees: [SGFGameTree]
    
    init(_ data: String) {
        self.data = data
        self.dataLen = data.count
        self.index = 0
        self.gameTrees = [SGFGameTree]()
    }
    
    func parse() throws -> Void {
        while self.index < self.dataLen {
            let gameTree = try self.parseOneGame()
            if gameTree != nil {
                self.gameTrees.append(gameTree!)
            } else {
                break
            }
        }
    }
    
    func parseOneGame() throws -> SGFGameTree? {
        //print("** parseOneGame **")
        //print("self.index = \(self.index), self.dataLen = \(self.dataLen)")
        if self.index < self.dataLen {
            let reGameTreeStart = try NSRegularExpression(pattern: SGFParser.gameTreeStart)
            
            let match = reGameTreeStart.firstMatch(in: data, options: .anchored, range: NSMakeRange(self.index, self.dataLen - self.index))
    
            if match != nil {
                self.index = match!.range.upperBound
                let gameTree = try self.parseGameTree()
                return gameTree
            }
        }
        
        return nil
    }
    
    func parseGameTree() throws -> SGFGameTree {
        //print("** parseGameTree **")
        let gameTree = SGFGameTree()
        gameTree.nodelist = [SGFNode]()
        
        while self.index < self.dataLen {
            let reGameTreeNext = try NSRegularExpression(pattern: SGFParser.gameTreeNext)
            let match = reGameTreeNext.firstMatch(in: data, options: .anchored, range: NSMakeRange(self.index, self.dataLen - self.index))
            //print("match = \(match)")
            //print("self.index = \(self.index)")
            if match != nil {
                self.index = match!.range.upperBound
                let matchedString = data[Range(match!.range(at: 0), in: data)!]
                //print("matchedString = '\(matchedString)'")
                switch matchedString {
                case ";":
                    if !gameTree.variations.isEmpty {
                        throw SGFParserError.GameTreeParseError("A node was encountered after a variation at \(self.index)")
                    }
                    let node = try self.parseNode()
                    gameTree.nodelist?.append(node)
                case "(":
                    gameTree.variations = try self.parseVariations()
                    //print("gameTree.variations = \(gameTree.variations)")
                case ")":
                    //print("matchedString = \(matchedString)")
                    return gameTree
                default:
                    throw SGFParserError.GameTreeParseError("at \(self.index)")
                }
            } else {
                throw SGFParserError.GameTreeParseError("at \(self.index)")
            }
            
        }
        
        return gameTree
    }
    
    // TODO: Find an example
    func parseVariations() throws -> [SGFGameTree] {
        let reGameTreeStart = try NSRegularExpression(pattern: SGFParser.gameTreeStart)
        let reGameTreeEnd = try NSRegularExpression(pattern: SGFParser.gameTreeEnd)
        
        //print("** parseVariations **")
        var variations = [SGFGameTree]()
        //print("self.index = \(self.index)")
        while self.index < self.dataLen {
            //print("\(data[Range(NSMakeRange(self.index, 1), in: data)!])")
            let matchEnd = reGameTreeEnd.firstMatch(in: data, options: .anchored, range: NSMakeRange(self.index, self.dataLen - self.index))
            
            //print("matchEnd = \(String(describing: matchEnd))")
            //print("self.index = \(self.index)")
            
            if matchEnd != nil {
                return variations
            }
            
            let gameTree = try self.parseGameTree()
            //print("gameTree.nodelist.count = \(gameTree.nodelist!.count)")
            
            if gameTree.nodelist != nil && !gameTree.nodelist!.isEmpty {
                variations.append(gameTree)
            }
            
            let matchStart = reGameTreeStart.firstMatch(in: data, options: .anchored, range: NSMakeRange(self.index, self.dataLen - self.index))
            
            //print("matchStart = \(String(describing: matchStart))")
            //print("self.index = \(self.index)")
            if matchStart != nil {
                self.index = matchStart!.range.upperBound
            }
            
        }
        
        throw SGFParserError.EndOfDataParseError
    }
    
    func parseNode() throws -> SGFNode {
        //print("** parseNode **")
        let node = SGFNode(properties: [SGFProperty]())
        
        while self.index < self.dataLen {
            let reNodeContents = try NSRegularExpression(pattern: SGFParser.nodeContents)
            let match = reNodeContents.firstMatch(in: data, options:.anchored, range: NSMakeRange(self.index, self.dataLen - self.index))
            
            if match != nil {
                self.index = match!.range.upperBound
                let propertyValueList = try self.parsePropertyValue()

                if !propertyValueList.isEmpty {
                    let id = data[Range(match!.range(at: 0), in: data)!]
                    let property = node.makeProperty(id: String(id), values: propertyValueList)
                    node.addProperty(property: property)
                } else {
                    throw SGFParserError.NodePropertyParseError
                }
            } else {
                return node
            }
        }

        throw SGFParserError.EndOfDataParseError
    }
    
    func parsePropertyValue() throws -> [String] {
        var propertyValueList = [String]()
        
        while self.index < self.dataLen {
            let rePropertyStart = try NSRegularExpression(pattern: SGFParser.propertyStart)
            let match = rePropertyStart.firstMatch(in: data, options: .anchored, range: NSMakeRange(self.index, self.dataLen - self.index))
            
            if match != nil {
                self.index = match!.range.upperBound
                var value = ""
                
                let rePropertyEnd = try NSRegularExpression(pattern: SGFParser.propertyEnd)
                let reEscape = try NSRegularExpression(pattern: SGFParser.escape)
                
                var matchEnd = rePropertyEnd.firstMatch(in: data, options: [], range: NSMakeRange(self.index, self.dataLen - self.index))
                var matchEscape = reEscape.firstMatch(in: data, options: [], range: NSMakeRange(self.index, self.dataLen - self.index))
                
                while matchEscape != nil && matchEnd != nil && (matchEscape!.range.upperBound < matchEnd!.range.upperBound) {
                    let matchedString = data[Range(NSMakeRange(self.index, matchEscape!.range.lowerBound - self.index), in:data)!]
                    value += matchedString
                    
                    let reLineBreak = try NSRegularExpression(pattern: SGFParser.lineBreak)
                    let matchBreak = reLineBreak.firstMatch(in: data, options: [], range: NSMakeRange( matchEscape!.range.upperBound, self.dataLen - matchEscape!.range.upperBound))
                    
                    if matchBreak != nil {
                        self.index = matchBreak!.range.upperBound
                    } else {
                        value += data[Range(NSMakeRange(matchEscape!.range.upperBound, 1), in: data)!]
                        self.index = matchEscape!.range.upperBound + 1
                    }
                    
                    matchEnd = rePropertyEnd.firstMatch(in: data, options: [], range: NSMakeRange(self.index, self.dataLen - self.index))
                    matchEscape = reEscape.firstMatch(in: data, options: [], range: NSMakeRange(self.index, self.dataLen - self.index))
                }
                
                if matchEnd != nil {
                    value += data[Range(NSMakeRange(self.index, matchEnd!.range.lowerBound - self.index), in: data)!]
                    self.index = matchEnd!.range.upperBound
                    propertyValueList.append(convertControlChars(value))
                } else {
                    throw SGFParserError.PropertyValueParseError
                }
            } else {
                break
            }
        }
        if propertyValueList.count >= 1 {
            return propertyValueList
        } else {
            throw SGFParserError.PropertyValueParseError
        }
    }
    
    func convertControlChars(_ text: String) -> String {
        return text.map { character -> String in
            let singleCharacter = String(character)
            if SGFParser.escapingCharacters.contains(singleCharacter) {
                return " "
            } else {
                return singleCharacter
            }
        }.joined()
    }
    
    static let escapingCharacters = ["\u{000}", "\u{001}", "\u{002}", "\u{003}", "\u{004}", "\u{005}", "\u{006}", "\u{007}",
                                    "\u{008}", "\u{009}", "\u{00B}", "\u{00C}", "\u{00E}", "\u{00F}",
                                    "\u{010}", "\u{011}", "\u{012}", "\u{013}", "\u{014}", "\u{015}", "\u{016}", "\u{017}",
                                    "\u{018}", "\u{019}", "\u{01A}", "\u{01B}", "\u{01C}", "\u{01D}", "\u{01E}", "\u{01F}"]
}


