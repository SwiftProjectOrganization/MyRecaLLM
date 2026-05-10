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
public class Category: Codable, Identifiable, Equatable, Hashable {
  enum CodingKeys: CodingKey {
    case title, subTitle
    case includedInRecall, lastRecallCycle, noOfRecallCycles
    case topics, recallTimeStamps

  }
  
  var title: String?
  var subTitle: String?
  
  var includedInRecall: Bool = true
  var lastRecallCycle: Date = Date()
  var noOfRecallCycles: Int = 0
  var recallTimeStamps: [Date]?

  @Relationship(deleteRule: .cascade,
                inverse: \Topic.category)
  var topics: [Topic]?
  
  init(_ title: String = "",
       _ subTitle: String = "Available categories",
       _ includedInRecall: Bool = true,
       _ lastRecallCycle: Date = Date(),
       _ noOfRecallCycles: Int = 0,
       _ recallTimeStamps: [Date]? = [Date()],
       _ topics: [Topic] = []) {
    self.title = title
    self.subTitle = subTitle
    self.includedInRecall = includedInRecall
    self.lastRecallCycle = lastRecallCycle
    self.noOfRecallCycles = noOfRecallCycles
    self.topics = topics
  }
  
  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decodeIfPresent(String.self, forKey: .title)
    subTitle = try container.decodeIfPresent(String.self, forKey: .subTitle)
    includedInRecall = try container.decode(Bool.self, forKey: .includedInRecall)
    lastRecallCycle = try container.decode(Date.self, forKey: .lastRecallCycle)
    noOfRecallCycles = try container.decode(Int.self, forKey: .noOfRecallCycles)
    recallTimeStamps = try container.decodeIfPresent([Date].self, forKey: .recallTimeStamps)
    topics = try container.decodeIfPresent([Topic].self, forKey: .topics)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encodeIfPresent(subTitle, forKey: .subTitle)
    try container.encode(includedInRecall, forKey: .includedInRecall)
    try container.encode(lastRecallCycle, forKey: .lastRecallCycle)
    try container.encode(noOfRecallCycles, forKey: .noOfRecallCycles)
    try container.encodeIfPresent(recallTimeStamps, forKey: .recallTimeStamps)
    try container.encodeIfPresent(topics, forKey: .topics)
  }
}
