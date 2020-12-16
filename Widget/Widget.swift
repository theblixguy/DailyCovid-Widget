//
//  Widget.swift
//  Widget
//
//  Created by Suyash Srijan on 01/11/2020.
//

import WidgetKit
import SwiftUI
import Intents
import Charts

struct Provider: IntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    let intent = CovidLocationIntent()
    intent.locationType = .region
    intent.regionName = "Camden"
    return SimpleEntry(date: .init(), data: generateMockDataPoints(), configuration: intent)
  }

  func getSnapshot(for configuration: CovidLocationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    let intent = CovidLocationIntent()
    intent.locationType = .region
    intent.regionName = "Camden"
    let entry = SimpleEntry(date: .init(),
                            data: generateMockDataPoints(),
                            configuration: intent)
    completion(entry)
  }

  func getTimeline(for configuration: CovidLocationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [SimpleEntry] = []
    let kind: CovidDataFetcher.AreaKind
    switch configuration.locationType {
      case .nation:
        switch configuration.nationName {
          case .england:
            kind = .nation(.england)
          case .scotland:
            kind = .nation(.scotland)
          case .wales:
            kind = .nation(.wales)
          case .northernIreland:
            kind = .nation(.northernIreland)
          case .unknown:
            kind = .nation(.england)
        }
      case .region:
        kind = .region(configuration.regionName ?? "Camden")
      case .unknown:
        kind = .nation(.england)
    }
    CovidDataFetcher.shared.getCovidData(forArea: kind) { response in
      entries.append(.init(date: .init(), data: response.sorted { $0.date.compare($1.date) == .orderedDescending }, configuration: configuration))
      let currentDatePlusFiveHours = Calendar.current.date(byAdding: .hour, value: 5, to: Date())!
      let timeline = Timeline(entries: entries, policy: .after(currentDatePlusFiveHours))
      completion(timeline)
    }
  }

  func generateMockDataPoints() -> [CovidData.DataPoint] {
    var datapoints: [CovidData.DataPoint] = []
    datapoints.append(.init(newCases: 6000, totalCases: 30000, newDeaths: 30, totalDeaths: 600, newHospitalAdmissions: 200, occupiedBedsWithVentilator: 300))
    datapoints.append(.init(newCases: 5000, totalCases: 24000, newDeaths: 25, totalDeaths: 570, newHospitalAdmissions: 250, occupiedBedsWithVentilator: 550))
    datapoints.append(.init(newCases: 4000, totalCases: 19000, newDeaths: 20, totalDeaths: 545, newHospitalAdmissions: 300, occupiedBedsWithVentilator: 850))
    datapoints.append(.init(newCases: 3000, totalCases: 15000, newDeaths: 15, totalDeaths: 525, newHospitalAdmissions: 350, occupiedBedsWithVentilator: 1200))
    datapoints.append(.init(newCases: 2000, totalCases: 12000, newDeaths: 10, totalDeaths: 510, newHospitalAdmissions: 400, occupiedBedsWithVentilator: 1600))
    datapoints.append(.init(newCases: 1000, totalCases: 10000, newDeaths: 5, totalDeaths: 500, newHospitalAdmissions: 450, occupiedBedsWithVentilator: 2050))
    datapoints.append(.init(newCases: 500, totalCases: 9000, newDeaths: 5, totalDeaths: 500, newHospitalAdmissions: 500, occupiedBedsWithVentilator: 2550))
    return datapoints
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let data: [CovidData.DataPoint]
  let configuration: CovidLocationIntent
}

struct WidgetEntryView : View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family

  var body: some View {
    ZStack {
      Color.black
      switch family {
        case .systemSmall:
          createSmallWidgetView()
        case .systemMedium:
          createMediumWidgetView()
        default:
          fatalError("Unsupported widget family")
      }
    }
  }

  private func createSmallWidgetView() -> some View {
    HStack {
      VStack {
        ZStack {
          Chart(data: entry.data.getSmoothNewCases())
            .chartStyle(
              LineChartStyle(.quadCurve, lineColor: .blue, lineWidth: 5))
          Chart(data: entry.data.getRawNewCases())
            .chartStyle(
              ColumnChartStyle(column: Capsule().foregroundColor(.red).blendMode(.screen), spacing: 0.5))
        }.frame(minHeight: 40, maxHeight: .infinity).padding([.leading, .top, .trailing])
        Text(getLocationName(from: entry.configuration)).foregroundColor(.white).font(.subheadline)
        HStack {
          VStack(alignment: .leading) {
            Text("+ \(entry.data.first?.newCases ?? 0)").foregroundColor(.white).font(.caption).fontWeight(.semibold)
            Text("\(formatNumber(entry.data.first?.totalCases ?? 0))").foregroundColor(.gray).font(.caption2)
          }
          Spacer()
          VStack(alignment: .leading) {
            Text("+ \(entry.data.first?.newDeaths ?? 0)").foregroundColor(.white).font(.caption).fontWeight(.semibold)
            Text("\(formatNumber(entry.data.first?.totalDeaths ?? 0))").foregroundColor(.gray).font(.caption2)
          }
        }.padding([.leading, .bottom, .trailing]).padding(.top, 2)
      }
    }
  }

  // FIXME: Merge with above
  private func createMediumWidgetView() -> some View {
    HStack {
      VStack {
        ZStack {
          HStack {
            ZStack {
              Chart(data: entry.data.getSmoothNewCases())
                .chartStyle(
                  LineChartStyle(.quadCurve, lineColor: .blue, lineWidth: 5))
              Chart(data: entry.data.getRawNewCases())
                .chartStyle(
                  ColumnChartStyle(column: Capsule().foregroundColor(.red).blendMode(.screen), spacing: 0.5))
            }
            ZStack {
              Chart(data: entry.data.getSmoothNewDeaths())
                .chartStyle(
                  LineChartStyle(.quadCurve, lineColor: .blue, lineWidth: 5))
              Chart(data: entry.data.getRawNewDeaths())
                .chartStyle(
                  ColumnChartStyle(column: Capsule().foregroundColor(.red).blendMode(.screen), spacing: 0.5))
            }
          }
        }.frame(minHeight: 40, maxHeight: .infinity).padding([.leading, .top, .trailing])
        Text(getLocationName(from: entry.configuration)).foregroundColor(.white).font(.subheadline)
        HStack {
          VStack(alignment: .leading) {
            Text("+ \(entry.data.first?.newCases ?? 0)").foregroundColor(.white).font(.caption).fontWeight(.semibold)
            Text("\(formatNumber(entry.data.first?.totalCases ?? 0))").foregroundColor(.gray).font(.caption2)
          }
          Spacer()
          VStack(alignment: .center) {
            Text("+ \(entry.data.first?.newHospitalAdmissions ?? 0) admissions").foregroundColor(.white).font(.caption).fontWeight(.semibold)
            Text("\(formatNumber(entry.data.getMostRecentNumPatientsOnVentilators())) patients on ventilator").foregroundColor(.gray).font(.caption2)
          }
          Spacer()
          VStack(alignment: .trailing) {
            Text("+ \(entry.data.first?.newDeaths ?? 0)").foregroundColor(.white).font(.caption).fontWeight(.semibold)
            Text("\(formatNumber(entry.data.first?.totalDeaths ?? 0))").foregroundColor(.gray).font(.caption2)
          }
        }.padding([.leading, .bottom, .trailing]).padding(.top, 2)
      }
    }
  }

  private func getLocationName(from intent: CovidLocationIntent) -> String {
    switch intent.locationType {
      case .region:
        return intent.regionName ?? "No region selected!"
      case .nation:
        switch intent.nationName {
          case .unknown:
            return "No location selected!"
          case .england:
            return "England"
          case .scotland:
            return "Scotland"
          case .wales:
            return "Wales"
          case .northernIreland:
            return "Northern Ireland"
        }
      case .unknown:
        return "No location selected!"
    }
  }

  private func formatNumber(_ number: Int) -> String {
    let numberAsDouble = abs(Double(number))
    let sign = (number > 0) ? "" : "-"

    switch numberAsDouble {
      case 0...999:
        return "\(number)"

      case 1_000...999_999:
        var formattedNumber = numberAsDouble / 1_000
        formattedNumber = Double(Int(formattedNumber * 10)) / 10
        return "\(sign)\(formattedNumber)K"

      case 1_000_000...999_999_999:
        var formattedNumber = numberAsDouble / 1_000_000
        formattedNumber = Double(Int(formattedNumber * 10)) / 10
        return "\(sign)\(formattedNumber)M"

      default:
        return "\(sign)\(number)"
    }
  }
}

@main
struct Widget: SwiftUI.Widget {
  let kind: String = "Widget"

  var body: some WidgetConfiguration {
    IntentConfiguration(kind: kind, intent: CovidLocationIntent.self, provider: Provider()) { entry in
      return WidgetEntryView(entry: entry)
    }
    .configurationDisplayName("DailyCovid Widget")
    .description("See daily stats like new cases and deaths, plus graphs!")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct Widget_Previews: PreviewProvider {
  static var previews: some View {
    WidgetEntryView(entry: SimpleEntry(date: Date(), data: Provider().generateMockDataPoints(), configuration: CovidLocationIntent()))
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
