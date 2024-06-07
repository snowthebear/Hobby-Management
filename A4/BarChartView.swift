//
//  BarChartView.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 05/05/24.
//

import Foundation
import UIKit
import Charts

class CustomBarChartView: BarChartView {
    
    private var hobbyColors: [String: UIColor] = [:]
    
    func setupChart() {
        self.chartDescription.text = "Minutes / Hobby Progress"
        self.noDataText = "No data available."
    }
    
    func updateChartData(dataEntries: [BarChartDataEntry], hobbyColors: [String: UIColor]) {
        let dataSet = BarChartDataSet(entries: dataEntries, label: "Hobbies")
        dataSet.colors = dataEntries.map { entry -> UIColor in
            if let hobbyName = entry.data as? String, let color = hobbyColors[hobbyName] {
                return color
            } else {
                return .gray // default color if no specific color is assigned
            }
        }
        
        let data = BarChartData(dataSets: [dataSet])
        self.data = data
        self.notifyDataSetChanged()
    }

}
