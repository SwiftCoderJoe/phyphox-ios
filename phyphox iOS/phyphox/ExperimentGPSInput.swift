//
//  ExperimentGPSInput.swift
//  phyphox
//
//  Created by Sebastian Kuhlen on 31.05.17.
//  Copyright © 2017 RWTH Aachen. All rights reserved.
//

import Foundation
import CoreLocation

final class ExperimentGPSInput : NSObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    fileprivate(set) weak var latBuffer: DataBuffer?
    fileprivate(set) weak var lonBuffer: DataBuffer?
    fileprivate(set) weak var zBuffer: DataBuffer?
    fileprivate(set) weak var vBuffer: DataBuffer?
    fileprivate(set) weak var dirBuffer: DataBuffer?
    fileprivate(set) weak var accuracyBuffer: DataBuffer?
    fileprivate(set) weak var zAccuracyBuffer: DataBuffer?
    fileprivate(set) weak var tBuffer: DataBuffer?
    
    fileprivate(set) weak var statusBuffer: DataBuffer?
    fileprivate(set) weak var satellitesBuffer: DataBuffer?
    
    fileprivate(set) var startTimestamp: TimeInterval?
    fileprivate var pauseBegin: TimeInterval = 0.0
    
    fileprivate let queue = DispatchQueue(label: "de.rwth-aachen.phyphox.gpsQueue", attributes: [])
    
    init (latBuffer: DataBuffer?, lonBuffer: DataBuffer?, zBuffer: DataBuffer?, vBuffer: DataBuffer?, dirBuffer: DataBuffer?, accuracyBuffer: DataBuffer?, zAccuracyBuffer: DataBuffer?, tBuffer: DataBuffer?, statusBuffer: DataBuffer?, satellitesBuffer: DataBuffer?) {
        self.latBuffer = latBuffer
        self.lonBuffer = lonBuffer
        self.zBuffer = zBuffer
        self.vBuffer = vBuffer
        self.dirBuffer = dirBuffer
        self.accuracyBuffer = accuracyBuffer
        self.zAccuracyBuffer = zAccuracyBuffer
        self.tBuffer = tBuffer
        
        self.statusBuffer = statusBuffer
        self.satellitesBuffer = satellitesBuffer
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            let z = location.altitude
            let v = location.speed
            let dir = location.course
            let accuracy = location.horizontalAccuracy
            let zAccuracy = location.horizontalAccuracy
            let t = location.timestamp.timeIntervalSinceReferenceDate
            let status = location.horizontalAccuracy > 0 ? 1.0 : 0.0
            let satellites = 0.0
            self.dataIn(lat, lon: lon, z:z, v: v, dir: dir, accuracy: accuracy, zAccuracy: zAccuracy, t: t, status: status, satellites: satellites)
        }
    }
    
    func clear() {
        self.startTimestamp = nil
    }
    
    func start() {
        if pauseBegin > 0 && startTimestamp != nil {
            startTimestamp! += CFAbsoluteTimeGetCurrent()-pauseBegin
            pauseBegin = 0.0
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        } else {
            let status = -1.0
            self.dataIn(nil, lon: nil, z:nil, v: nil, dir: nil, accuracy: nil, zAccuracy: nil, t: nil, status: status, satellites: nil)

        }
    }
    
    func stop() {
        pauseBegin = CFAbsoluteTimeGetCurrent()
        
        locationManager.stopUpdatingLocation()
    }
    
    fileprivate func writeToBuffers(_ lat: Double?, lon: Double?, z: Double?, v: Double?, dir: Double?, accuracy: Double?, zAccuracy: Double?, t: TimeInterval?, status: Double?, satellites: Double?) {
        if lat != nil && self.latBuffer != nil {
            self.latBuffer!.append(lat)
        }
        if lon != nil && self.lonBuffer != nil {
            self.lonBuffer!.append(lon)
        }
        if z != nil && self.zBuffer != nil {
            self.zBuffer!.append(z)
        }
        
        if v != nil && self.vBuffer != nil {
            self.vBuffer!.append(v)
        }
        if dir != nil && self.dirBuffer != nil {
            self.dirBuffer!.append(dir)
        }
        
        if accuracy != nil && self.accuracyBuffer != nil {
            self.accuracyBuffer!.append(accuracy)
        }
        
        if zAccuracy != nil && self.zAccuracyBuffer != nil {
            self.zAccuracyBuffer!.append(zAccuracy)
        }
        
        if t != nil && self.tBuffer != nil {
            if startTimestamp == nil {
                startTimestamp = t
            }
            
            let relativeT = t!-self.startTimestamp!
            
            self.tBuffer!.append(relativeT)
        }
        
        if status != nil && self.statusBuffer != nil {
            self.statusBuffer!.append(status)
        }
        
        if satellites != nil && self.satellitesBuffer != nil {
            self.satellitesBuffer!.append(satellites)
        }
    }
    
    fileprivate func dataIn(_ lat: Double?, lon: Double?, z: Double?, v: Double?, dir: Double?, accuracy: Double?, zAccuracy: Double?, t: TimeInterval?, status: Double?, satellites: Double?) {
        
        queue.async {
            autoreleasepool(invoking: {
                self.writeToBuffers(lat, lon: lon, z: z, v: v, dir: dir, accuracy: accuracy, zAccuracy: zAccuracy, t: t, status: status, satellites: satellites)
            })
        }
    }
}
