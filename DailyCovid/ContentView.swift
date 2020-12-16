//
//  ContentView.swift
//  DailyCovid
//
//  Created by Suyash Srijan on 01/11/2020.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
      Text("""
How to use:\n\n1. Add the widget via home screen or widget screen.\n2. Long press the widget and select 'Edit Widget' to access configuration options.\n\nWidget description:\n\n< Small widget >\n1) Top: A graph that shows cases in last 21 days (red) and 7 day rolling average (blue).\n2) Bottom left: New cases and total cases.\n3) Bottom right: New deaths and total deaths.\n\n< Medium Widget >\n1) Top left: A graph that shows cases in last 21 days (red) and 7-day rolling average (blue).\n2) Top right: A graph that shows deaths in the last 21 days (red) and 7-day rolling average (blue).\n3) Bottom left: New cases and new deaths.\n4) Bottom middle: New hospital admissions and patients on ventilators.\n5) Bottom left: New deaths and total deaths
""")
        .foregroundColor(.black)
        .multilineTextAlignment(.center)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
