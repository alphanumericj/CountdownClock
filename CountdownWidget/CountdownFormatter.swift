//
//  CountdownFormatter.swift
//  CountdownClock
//
//  Created by Laure Chipman on 12/18/25.
//


import Foundation

/// Break down the difference between two dates into Y, M, D, h, m components
func breakdownCountdown(from start: Date, to end: Date) -> [(String, Int)] {
    let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: start,
        to: end
    )
    var parts: [(String, Int)] = []
    if let y = components.year, y > 0 { parts.append(("Y ", y)) }
    if let M = components.month, M > 0 { parts.append(("M ", M)) }
    if let d = components.day, d > 0 { parts.append(("D ", d)) }
    if let h = components.hour, h > 0 { parts.append(("h ", h)) }
    if let m = components.minute, m > 0 { parts.append(("m", m)) }
    return parts
}

/// Short string: 2 largest components
func shortCountdownString(from start: Date, to end: Date) -> String {
    let parts = breakdownCountdown(from: start, to: end)
    return parts.prefix(2).map { "\($0.1)\($0.0)" }.joined(separator: " ")
}

/// Long string: up to 4 components
func longCountdownString(from start: Date, to end: Date) -> String {
    let parts = breakdownCountdown(from: start, to: end)
    return parts.prefix(4).map { "\($0.1)\($0.0)" }.joined(separator: " ")
}
