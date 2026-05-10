//
//  Item.swift
//  MyRecaLLM
//
//  Created by Robert Goedman on 5/4/26.
//

import Foundation
import SwiftData

@Model
final class Item: Decodable, Encodable {
  enum CodingKeys: CodingKey {
    case timestamp
    case question
    case generatedAnswer
    case userAnswer
    case includedInRecall, lastRecallCycle, noOfRecallCycles
    case subTopic, recallTimeStamps
  }
  var timestamp: Date
  var question: String?
  var generatedAnswer: String?
  var userAnswer: String?

  var includedInRecall: Bool = true
  var lastRecallCycle: Date = Date()
  var noOfRecallCycles: Int = 0
  
  var subTopic: SubTopic?
  var recallTimeStamps: [Date]?
    
  init(_ timeStamp: Date = Date(),
       _ question: String = "",
       _ generatedAnswer: String = "",
       _ userAnswer: String = "",
       _ includedInRecall: Bool = true,
       _ lastRecallCycle: Date = Date(),
       _ noOfRecallCycles: Int = 0,
       _ subTopic: SubTopic? = nil,
       _ recallTimeStamps: [Date] = [Date()]) {
    self.timestamp = timeStamp
    self.question = question
    self.generatedAnswer = generatedAnswer
    self.userAnswer = userAnswer
    self.includedInRecall = includedInRecall
    self.lastRecallCycle = lastRecallCycle
    self.noOfRecallCycles = noOfRecallCycles
    self.subTopic = subTopic
    self.recallTimeStamps = recallTimeStamps
  }
  
  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    timestamp = try container.decode(Date.self, forKey: .timestamp)
    question = try container.decodeIfPresent(String.self, forKey: .question)
    generatedAnswer = try container.decodeIfPresent(String.self, forKey: .generatedAnswer)
    userAnswer = try container.decodeIfPresent(String.self, forKey: .userAnswer)
    includedInRecall = try container.decode(Bool.self, forKey: .includedInRecall)
    lastRecallCycle = try container.decode(Date.self, forKey: .lastRecallCycle)
    noOfRecallCycles = try container.decode(Int.self, forKey: .noOfRecallCycles)
    recallTimeStamps = try container.decodeIfPresent([Date].self, forKey: .recallTimeStamps)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(timestamp, forKey: .timestamp)
    try container.encodeIfPresent(question, forKey: .question)
    try container.encodeIfPresent(generatedAnswer, forKey: .generatedAnswer)
    try container.encodeIfPresent(userAnswer, forKey: .userAnswer)
    try container.encode(includedInRecall, forKey: .includedInRecall)
    try container.encode(lastRecallCycle, forKey: .lastRecallCycle)
    try container.encode(noOfRecallCycles, forKey: .noOfRecallCycles)
    try container.encodeIfPresent(recallTimeStamps, forKey: .recallTimeStamps)
  }
}

