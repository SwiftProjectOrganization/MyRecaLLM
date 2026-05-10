//
//  Topics.swift
//  MyRecallApp
//
//  Created by Robert Goedman on 2/6/25.
//

import Foundation
import SwiftUI
import SwiftData

@Model
public class Topic: Codable, Identifiable, Equatable, Hashable {
  enum CodingKeys: CodingKey {
    case title, subTitle
    case includedInRecall, lastRecallCycle, noOfRecallCycles
    case category, subTopics, recallTimeStamps
  }
  
  var title: String?
  var subTitle: String?
  
  var includedInRecall: Bool = true
  var lastRecallCycle: Date = Date()
  var noOfRecallCycles: Int = 0
  var recallTimeStamps: [Date]?

  var category: Category?
  
  @Relationship(deleteRule: .cascade,
                inverse: \SubTopic.topic)
  var subTopics: [SubTopic]?
  
  
  init(_ title: String = "",
       _ subTitle: String = "",
       _ includedInRecall: Bool = true,
       _ lastRecallCycle: Date = Date(),
       _ noOfRecallCycles: Int = 0,
       _ recallTimeStamps: [Date]? = [Date()],
       _ category: Category? = nil,
       _ subTopics: [SubTopic] = []) {
    self.title = title
    self.subTitle = subTitle
    self.includedInRecall = includedInRecall
    self.lastRecallCycle = lastRecallCycle
    self.noOfRecallCycles = noOfRecallCycles
    self.recallTimeStamps = recallTimeStamps
    self.category = category
    self.subTopics = subTopics
  }

  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decodeIfPresent(String.self, forKey: .title)
    subTitle = try container.decodeIfPresent(String.self, forKey: .subTitle)
    includedInRecall = try container.decode(Bool.self, forKey: .includedInRecall)
    lastRecallCycle = try container.decode(Date.self, forKey: .lastRecallCycle)
    noOfRecallCycles = try container.decode(Int.self, forKey: .noOfRecallCycles)
    recallTimeStamps = try container.decodeIfPresent([Date].self, forKey: .recallTimeStamps)
    subTopics = try container.decodeIfPresent([SubTopic].self, forKey: .subTopics)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encodeIfPresent(subTitle, forKey: .subTitle)
    try container.encode(includedInRecall, forKey: .includedInRecall)
    try container.encode(lastRecallCycle, forKey: .lastRecallCycle)
    try container.encode(noOfRecallCycles, forKey: .noOfRecallCycles)
    try container.encodeIfPresent(recallTimeStamps, forKey: .recallTimeStamps)
    try container.encodeIfPresent(subTopics, forKey: .subTopics)
  }
}
