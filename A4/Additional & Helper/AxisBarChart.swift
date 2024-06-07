//
//  AxisBarChart.swift
//  A4
//
//  Created by Yenny Fransisca Halim on 06/06/24.
//

import Foundation
import Charts

class AxisBarChart: IndexAxisValueFormatter {
    override func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return "\(Int(value))"
    }
}
