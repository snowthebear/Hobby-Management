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
        self.chartDescription.text = "Hobby Progress"
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

//    func updateChartData(dataEntries: [BarChartDataEntry]) {
//        let dataSet = BarChartDataSet(entries: dataEntries, label: "Hobbies")
//        dataSet.colors = ChartColorTemplates.colorful()
//        
//        let data = BarChartData(dataSets: [dataSet])
//        self.data = data
//        self.notifyDataSetChanged()
//    }

//    func setupChart() {
//        // Example data
//        let dataEntries = [
//            BarChartDataEntry(x: 0, yValues: [1, 2, 3]),
//            BarChartDataEntry(x: 1, yValues: [2, 1, 4])
//        ]
//        
//        // Create dataset with custom colors
//        let dataSet = BarChartDataSet(entries: dataEntries, label: "Hobbies")
//        dataSet.colors = [UIColor.red, UIColor.green, UIColor.blue]
//
//        // Create chart data and assign it to the chart view
//        let data = BarChartData(dataSets: [dataSet])
//        self.data = data
//
//        // Customize the chart
//        self.chartDescription.text = "Hobby Progress"
//    }
}
