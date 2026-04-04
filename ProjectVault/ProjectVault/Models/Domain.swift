import Foundation
import SwiftUI

enum ExamDomain: String, CaseIterable, Identifiable, Sendable {
    case domain1 = "1.0"
    case domain2 = "2.0"
    case domain3 = "3.0"
    case domain4 = "4.0"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .domain1: return "Project Management Concepts"
        case .domain2: return "Project Life Cycle Phases"
        case .domain3: return "Tools and Documentation"
        case .domain4: return "Basics of IT and Governance"
        }
    }

    var shortTitle: String {
        switch self {
        case .domain1: return "PM Concepts"
        case .domain2: return "Life Cycle"
        case .domain3: return "Tools & Docs"
        case .domain4: return "IT & Governance"
        }
    }

    var examWeight: Int {
        switch self {
        case .domain1: return 33
        case .domain2: return 30
        case .domain3: return 19
        case .domain4: return 18
        }
    }

    var icon: String {
        switch self {
        case .domain1: return "gearshape.2.fill"
        case .domain2: return "arrow.triangle.2.circlepath"
        case .domain3: return "doc.text.magnifyingglass"
        case .domain4: return "shield.checkered"
        }
    }

    var color: Color {
        switch self {
        case .domain1: return Color("VaultGold")
        case .domain2: return .cyan
        case .domain3: return .mint
        case .domain4: return .purple
        }
    }

    var domainPrefix: String {
        rawValue + " "
    }

    static func from(domainString: String) -> ExamDomain? {
        allCases.first { domainString.hasPrefix($0.rawValue) }
    }
}
