//
//  CovidDataFetcher.swift
//  DailyCovid
//
//  Created by Suyash Srijan on 01/11/2020.
//

import Combine
import Foundation

final class CovidDataFetcher : ObservableObject {
  private var cancellables: Set<AnyCancellable> = []
  private var publishers: [Publishers.ReceiveOn<AnyPublisher<CovidData, Error>, DispatchQueue>] = []
  static let shared = CovidDataFetcher()

  enum NationKind: String {
    case england
    case scotland
    case wales
    case northernIreland
  }

  enum AreaKind {
    case nation(NationKind)
    case region(String)

    var areaName: String {
      switch self {
        case let .nation(value):
          return value.rawValue
        case let .region(value):
          return value
      }
    }

    var isRegional: Bool {
      switch self {
        case .nation:
          return false
        case .region:
          return true
      }
    }
  }

  func getCovidData(forArea area: AreaKind, completion: @escaping ([CovidData.DataPoint]) -> Void) {
    let areaName = area.areaName
    let areaType = area.isRegional ? "ltla" : "nation"

    // The below is done because not every key is supported  for every region/area.
    let newDeathsKey = area.isRegional ? "newDeathsByPublishDate" : "newDeaths28DaysByPublishDate"
    let totalDeathsKey = area.isRegional ? "cumDeathsByPublishDate" : "cumDeaths28DaysByPublishDate"

    // FIXME: Spent hours trying to build this using URLComponents but either the URL
    // fails to build, or the GOV.UK server simply does not accept the URL for some
    // reason, so I have hardcoded it here like this, which I know is dirty but it
    // works for now.
    let urlString = "https://api.coronavirus.data.gov.uk/v1/data?filters=areaType=\(areaType);areaName=\(areaName)&structure={%22date%22:%22date%22,%22occupiedBedsWithVentilator%22:%22covidOccupiedMVBeds%22,%22newCases%22:%22newCasesByPublishDate%22,%22totalCases%22:%22cumCasesByPublishDate%22,%22newDeaths%22:%22\(newDeathsKey)%22,%22totalDeaths%22:%22\(totalDeathsKey)%22,%22newHospitalAdmissions%22:%22newAdmissions%22}".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    let publisher = URLSession.shared.dataTaskPublisherWithCaching(for: URL(string: urlString)!)
      .map(\.data)
      .decode(type: CovidData.self, decoder: JSONDecoder())
      .eraseToAnyPublisher()
      .receive(on: DispatchQueue.main)

    // The publisher needs to be retained otherwise it will be deallocated and
    // the completion handler won't run.
    publishers.append(publisher)
    publisher.sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
      completion($0.datapoints)
      _ = self?.publishers.removeFirst()
    }).store(in: &cancellables)
  }
}

// FIXME: Putting this in a separate file causes the compiler to complain about
// the method being missing.
private extension URLSession {
  func dataTaskPublisherWithCaching(for url: URL) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
    return self.dataTaskPublisher(for: url)
      .tryCatch { [weak self] (error) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Never> in
        guard let urlCache = self?.configuration.urlCache,
              let cachedResponse = urlCache.cachedResponse(for: URLRequest(url: url))
        else { throw error }
        return Just(URLSession.DataTaskPublisher.Output(
          data: cachedResponse.data,
          response: cachedResponse.response
        )).eraseToAnyPublisher()
      }.eraseToAnyPublisher()
  }
}
