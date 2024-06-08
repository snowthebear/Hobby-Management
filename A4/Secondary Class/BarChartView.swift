//
//  BarChartView.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 05/05/24.
//

import Foundation
import UIKit
import Charts


/**
 CustomBarChartView is a subclass of BarChartView that customizes the display of a bar chart.
 It includes setup methods for configuring chart appearance and updating chart data with specific hobby colors.
 */
class CustomBarChartView: BarChartView {
    
    private var hobbyColors: [String: UIColor] = [:] // Dictionary mapping hobby names to their respective colors
    
    /**
     Configures the initial settings of the bar chart.
     Sets the description text and the no data text.
     */
    func setupChart() {
        self.chartDescription.text = "Minutes / Hobby Progress"
        self.noDataText = "No data available."
    }
    
    /**
     Updates the chart data with the provided entries and hobby colors.
     - Parameters:
       - dataEntries: An array of `BarChartDataEntry` objects representing the data points for the chart.
       - hobbyColors: A dictionary mapping hobby names to their respective colors.
     */
    func updateChartData(dataEntries: [BarChartDataEntry], hobbyColors: [String: UIColor]) {
        // Create a dataset with the provided entries and label it as "Hobbies"
        let dataSet = BarChartDataSet(entries: dataEntries, label: "Hobbies")
        
        // Assign colors to each entry based on the hobby name
        dataSet.colors = dataEntries.map { entry -> UIColor in
            if let hobbyName = entry.data as? String, let color = hobbyColors[hobbyName] {
                return color
            } else {
                return .gray // default color if no specific color is assigned
            }
        }
        // Create BarChartData object with the dataset
        let data = BarChartData(dataSets: [dataSet])
        
        // Set the data for the chart and refresh the view
        self.data = data
        self.notifyDataSetChanged()
    }
}
