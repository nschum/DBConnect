//
//  SNCFModel.swift
//  
//
//  Created by Leo Mehlig on 13.07.22.
//

import Foundation
import TrainConnect
import CoreLocation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - DetailsResponse
public struct DetailsResponse: Codable, TrainTrip {
    public var train: String {
        self.carrier
    }
    
    public var trainStops: [TrainStop] {
        self.stops
    }
    
    public var vzn: String {
        self.number
    }
    
    public let number: String
    public let carrier: String
    //  public let events: [Any]
//    public let onboardServices: [String]
//    public let additionalServices: AdditionalServices
    public let stops: [Stop]
    public let trainId: String
}

// MARK: - AdditionalServices
public struct AdditionalServices: Codable {
}

// MARK: - Stop
public struct Stop: Codable, TrainStop {
    
    public let id: UUID = UUID()
    
    public var trainStation: TrainStation {
        Station(code: self.code,
                name: self.label,
                coordinates: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude))
    }
    
    public var scheduledArrival: Date? {
        self.theoricDate
    }
    
    public var actualArrival: Date? {
        self.realDate
    }
    
    public var scheduledDeparture: Date? {
        self.scheduledArrival?.addingTimeInterval(TimeInterval(self.duration) * 60)
    }
    
    public var actualDeparture: Date? {
        self.actualArrival?.addingTimeInterval(TimeInterval(self.duration) * 60)
    }
    
    public var hasPassed: Bool {
        (self.progress?.progressPercentage ?? 0) >= 100
    }
    
    public var departureDelay: String {
        if isDelayed {
            "+\(self.delay)"
        } else {
            return ""
        }
    }
    
    public var arrivalDelay: String {
        self.departureDelay
    }
    
    public var trainTrack: TrainTrack? {
        if let platform = platform {
            return Track(scheduled: platform, actual: platform)
        }
        return nil
    }
    
    public let code: String
    public let label: String
//    public let services: Services
    public let coordinates: Coordinates
    public let progress: Progress?
    public let theoricDate, realDate: Date?
//    public let isRemoved, isCreated, isDiversion: Bool
    public let delay: Int
    public let isDelayed: Bool
    public let duration: Int
    public let platform: String?
}

struct Station: TrainStation {
    let code: String
    
    let name: String
    
    let coordinates: CLLocationCoordinate2D?
}

struct Track: TrainTrack {
    let scheduled: String
    
    let actual: String
}

// MARK: - Coordinates
public struct Coordinates: Codable {
    public let latitude, longitude: Double
}

// MARK: - Progress
public struct Progress: Codable {
    public let progressPercentage: Double
    public let traveledDistance: Double
    public let remainingDistance: Double
}

// MARK: - Services
public struct Services: Codable {
    public let driver: Bool?
}


struct Status: TrainStatus {
    
    let gps: GPSResponse
    let statistics: StatisticsResponse
    
    let trainId: String
    
    var latitude: Double {
        gps.latitude
    }
    
    var longitude: Double {
        gps.longitude
    }
    
    var speed: Double {
        gps.speed
    }
    
    
    var currentConnectivity: String? {
        var connectivity: String = ""
        for _ in 0..<statistics.quality {
            connectivity += "●"
        }
        for _ in 0..<max(0, 5 - statistics.quality) {
            connectivity += "○"
        }
        return connectivity
    }
    
    var connectedDevices: Int? {
        self.statistics.devices
    }
    
    var trainType: TrainType {
        TVGTrainType(trainId: self.trainId)
    }
}

struct TVGTrainType: TrainType {
    
    let trainId: String
    
    //Source: https://www.hunza.pro/differentes-rames-tgv-circulant-sur-reseau-sncf.html
    var trainModel: String {
        switch Int(self.trainId) ?? 0 {
        case 1...102:
            return "TGV PSE (bicourant)"
        case 110...118:
            return "TGV PSE (tricourant)"
        case 301...405, 105:
            return "TGV Atlantique"
        case 501...554:
            return "TGV Réseau (bicourant)"
        case 4501...4540:
            return "TGV Réseau (tricourant)"
        case 201...294:
            return "TGV Duplex"
        case 601...619:
            return "TGV Réseau Duplex"
        case 4401...4419:
            return "TGV Duplex POS"
        case 701...752:
            return "TGV DASYE"
        case 800...810:
            return "Euroduplex / TGV 2N2 (3UH)"
        case 811...852:
            return "Euroduplex / TGV 2N2 (3UF)"
        case 4701...4730:
            return "Euroduplex / TGV 2N2 (3UA)"
        case 826...894:
            return "Euroduplex / TGV 2N2 (3UFC Océane)"
        case 4301...4346:
            return "THALYS PBKA"
        default:
            return "Unknown" // Eurostar maybe?
        }
    }
    
    // Source: fr.wikipedia.org
//    var trainModel: String {
//        switch Int(self.trainId) ?? 0 {
//        case 301...405:
//            return "TGV Atlantique" // https://fr.wikipedia.org/wiki/TGV_Atlantique
//        case 4701...4730:
//            return "Euroduplex / TGV 2N2 (3UA 310000)" // https://fr.wikipedia.org/wiki/TGV_2N2
//        case 801...810:
//            return "Euroduplex / TGV 2N2 (3UH 310200)" // https://fr.wikipedia.org/wiki/TGV_2N2
//        case 811...825:
//            return "Euroduplex / TGV 2N2 (3UF 310200)" // https://fr.wikipedia.org/wiki/TGV_2N2
//        case 836...865, 867...891:
//            return "TGV L'Océane / TGV 2N2 (3UFC 310200)" // https://fr.wikipedia.org/wiki/TGV_2N2
//        case 1201...1212:
//            return "Euroduplex / Al Boraq" // https://fr.wikipedia.org/wiki/TGV_2N2
//        case 4532...4540, 4551:
//            return "TGV Thalys (PBA)" // https://fr.wikipedia.org/wiki/TGV_PBA
//        case 4301...4307, 4321...4322, 4331...4332, 4341...4346:
//            return "TGV Thalys (PBKA)" // https://fr.wikipedia.org/wiki/TGV_PBKA
//        case 501...554:
//            return "TGV Réseau (28000 bicourant)" // https://fr.wikipedia.org/wiki/TGV_Réseau
//        case 4501...4530:
//            return "TGV Réseau (380000 tricourant)" // https://fr.wikipedia.org/wiki/TGV_Réseau
//        case 4532...4540:
//            return "TGV Réseau (380000 tricourant PBA)" // https://fr.wikipedia.org/wiki/TGV_Réseau
//        case 4401...4419:
//            return "TGV POS (384000)" // https://fr.wikipedia.org/wiki/TGV_POS
//        case 1...37, 39...87, 89...98, 100...102:
//            return "TGV Sud-Est (23000 bicourant)" // https://fr.wikipedia.org/wiki/TGV_Sud-Est
//        case 110...118:
//            return "TGV Sud-Est (33000 tricourant)" // https://fr.wikipedia.org/wiki/TGV_Sud-Est
//        default:
//            return "Unknown \(self.trainId)"
//            /*
//             Unmatched:
//             - https://fr.wikipedia.org/wiki/TGV_Duplex
//             - https://fr.wikipedia.org/wiki/TGV_TMST
//             */
//        }
//    }
    
    var trainIcon: NSImage? {
        Bundle.module.image(forResource: "TGV_Placeholder")!
    }
    
    
}

// MARK: - GPSResponse
public struct GPSResponse: Codable {
    public let success: Bool
    public let fix, timestamp: Int
    public let latitude, longitude: Double
    public let altitude: Double
    public let speed, heading: Double
}

// MARK: - CoverageResponse
public struct CoverageResponse: Codable {
    public let type: String
    public let features: [Feature]
}

// MARK: - Feature
public struct Feature: Codable {
    public let type: FeatureType
    public let geometry: Geometry
    public let properties: Properties
}

// MARK: - Geometry
public struct Geometry: Codable {
    public let type: GeometryType
    public let coordinates: [[Double]]
}

public enum GeometryType: String, Codable {
    case lineString = "LineString"
}

// MARK: - Properties
public struct Properties: Codable {
    public let quality: Quality
}

public enum Quality: String, Codable {
    case big = "big"
    case small = "small"
    case tiny = "tiny"
    case tunnel = "tunnel"
}

public enum FeatureType: String, Codable {
    case feature = "Feature"
}

// MARK: - StatisticsResponse
public struct StatisticsResponse: Codable {
    public let quality, devices: Int
}