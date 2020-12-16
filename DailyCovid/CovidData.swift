//
//  CovidData.swift
//  DailyCovid
//
//  Created by Suyash Srijan on 01/11/2020.
//

import Foundation

struct CovidData: Decodable {
  let datapoints: [DataPoint]

  private enum CodingKeys: String, CodingKey {
    case datapoints = "data"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    datapoints = try container.decodeIfPresent([DataPoint].self, forKey: .datapoints) ?? []
  }

  struct DataPoint: Decodable {
    let date: Date
    let newCases: Int
    let totalCases: Int
    let newDeaths: Int
    let totalDeaths: Int
    let newHospitalAdmissions: Int
    let occupiedBedsWithVentilator: Int

    private enum CodingKeys: String, CodingKey {
      case date
      case newCases
      case totalCases
      case newDeaths
      case totalDeaths
      case newHospitalAdmissions
      case occupiedBedsWithVentilator
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      let dateString = try container.decode(String.self, forKey: .date)
      date = formatter.date(from: dateString)!
      newCases = try container.decodeIfPresent(Int.self, forKey: .newCases) ?? 0
      totalCases = try container.decodeIfPresent(Int.self, forKey: .totalCases) ?? 0
      newDeaths = try container.decodeIfPresent(Int.self, forKey: .newDeaths) ?? 0
      totalDeaths = try container.decodeIfPresent(Int.self, forKey: .totalDeaths) ?? 0
      newHospitalAdmissions = try container.decodeIfPresent(Int.self, forKey: .newHospitalAdmissions) ?? 0
      occupiedBedsWithVentilator = try container.decodeIfPresent(Int.self, forKey: .occupiedBedsWithVentilator) ?? 0
    }

    init(date: Date = .init(),
         newCases: Int = 0,
         totalCases: Int = 0,
         newDeaths: Int = 0,
         totalDeaths: Int = 0,
         newHospitalAdmissions: Int = 0,
         occupiedBedsWithVentilator: Int = 0) {
      self.date = date
      self.newCases = newCases
      self.totalCases = totalCases
      self.newDeaths = newDeaths
      self.totalDeaths = totalDeaths
      self.newHospitalAdmissions = newHospitalAdmissions
      self.occupiedBedsWithVentilator = occupiedBedsWithVentilator
    }
  }
}

extension Array where Element == CovidData.DataPoint {
  func getSmoothNewCases() -> [Float] {
    let lastSevenDays = scaleArray(prefix(7).map(\.newCases)).smoothed()
    return lastSevenDays
  }

  func getRawNewCases() -> [Float] {
    let lastSevenDays = scaleArray(prefix(21).map(\.newCases))
    return lastSevenDays
  }

  func getSmoothNewDeaths() -> [Float] {
    let lastSevenDays = scaleArray(prefix(7).map(\.newDeaths)).smoothed()
    return lastSevenDays
  }

  func getRawNewDeaths() -> [Float] {
    let lastSevenDays = scaleArray(prefix(21).map(\.newDeaths))
    return lastSevenDays
  }

  func getMostRecentNumPatientsOnVentilators() -> Int {
    return first { $0.occupiedBedsWithVentilator != 0 }?.occupiedBedsWithVentilator ?? 0
  }

  func scaleArray(_ array: [Int]) -> [Float] {
    guard let maxValue = array.max() else { return .init() }
    return array.map { Float($0) / Float(maxValue) }
  }
}

extension Array where Element == Double {

  func movingAverage(forDays days: Int) -> [Double] {
    var result = [Double]()
    for index in indices {
      let daysMinusOne = days - 1
      if index < daysMinusOne {
        result.append(self[index])
        continue
      }
      let slice = self[(index - daysMinusOne)...index]
      let partialSum = slice.reduce(0, +)
      let average = partialSum / Double(days)
      result.append(average)
    }
    return result
  }

  func toFloat() -> [Float] {
    map(Float.init)
  }
}

extension Array where Element == Float {
  func smoothed() -> [Float] {
    return toDouble().movingAverage(forDays: 7).toFloat()
  }

  func toDouble() -> [Double] {
    map(Double.init)
  }
}
