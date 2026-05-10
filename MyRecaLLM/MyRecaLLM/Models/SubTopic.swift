//
//  SubTopic.swift
//  MyRecallApp_v3
//
//  Created by Robert Goedman on 12/29/24.
//

import Foundation
import SwiftUI
import SwiftData

@Model
public class SubTopic: Codable, Identifiable, Equatable, Hashable {
  enum CodingKeys: CodingKey {
    case title, subTitle
    case includedInRecall, lastRecallCycle, noOfRecallCycles
    case topic, questions, recallTimeStamps
  }
  
  var title: String?
  var subTitle: String?
  
  var includedInRecall: Bool = true
  var lastRecallCycle: Date = Date()
  var noOfRecallCycles: Int = 0
  var recallTimeStamps: [Date]?

  var topic: Topic?
  
  @Relationship(deleteRule: .cascade,
                inverse: \Item.subTopic)
  var questions: [Item]?
  
  
  init(_ title: String = "",
       _ subTitle: String = "",
       _ topic: Topic? = nil,
       _ includedInRecall: Bool = true,
       _ lastRecallCycle: Date = Date(),
       _ noOfRecallCycles: Int = 0,
       _ questions: [Item] = [],
       _ recallTimeStamps: [Date] = [Date()]) {
    self.title = title
    self.subTitle = subTitle
    self.includedInRecall = includedInRecall
    self.lastRecallCycle = lastRecallCycle
    self.noOfRecallCycles = noOfRecallCycles
    self.topic = topic
    self.questions = questions
    self.recallTimeStamps = recallTimeStamps
  }

  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decodeIfPresent(String.self, forKey: .title)
    subTitle = try container.decodeIfPresent(String.self, forKey: .subTitle)
    includedInRecall = try container.decode(Bool.self, forKey: .includedInRecall)
    lastRecallCycle = try container.decode(Date.self, forKey: .lastRecallCycle)
    noOfRecallCycles = try container.decode(Int.self, forKey: .noOfRecallCycles)
    questions = try container.decodeIfPresent([Item].self, forKey: .questions)
    recallTimeStamps = try container.decodeIfPresent([Date].self, forKey: .recallTimeStamps)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encodeIfPresent(subTitle, forKey: .subTitle)
    try container.encode(includedInRecall, forKey: .includedInRecall)
    try container.encode(lastRecallCycle, forKey: .lastRecallCycle)
    try container.encode(noOfRecallCycles, forKey: .noOfRecallCycles)
    try container.encodeIfPresent(questions, forKey: .questions)
    try container.encodeIfPresent(recallTimeStamps, forKey: .recallTimeStamps)
  }
}
