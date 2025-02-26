//
//  MinAnalysis.swift
//  phyphox
//
//  Created by Sebastian Kuhlen on 02.05.16.
//  Copyright © 2016 RWTH Aachen. All rights reserved.
//


import Foundation
import Accelerate

final class MinAnalysis: AutoClearingExperimentAnalysisModule {
    private var xIn: MutableDoubleArray?
    private var yIn: MutableDoubleArray!
    private var thresholdIn: ExperimentAnalysisDataIO?
    
    private var minOut: ExperimentAnalysisDataIO?
    private var positionOut: ExperimentAnalysisDataIO?
    
    private var multiple: Bool
    
    required init(inputs: [ExperimentAnalysisDataIO], outputs: [ExperimentAnalysisDataIO], additionalAttributes: AttributeContainer) throws {
        let attributes = additionalAttributes.attributes(keyedBy: String.self)

        multiple = try attributes.optionalValue(for: "multiple") ?? false
        
        for input in inputs {
            if input.asString == "x" {
                switch input {
                case .buffer(buffer: _, data: let data, usedAs: _, clear: _):
                    xIn = data
                case .value(value: _, usedAs: _):
                    break
                }
            }
            else if input.asString == "y" {
                switch input {
                case .buffer(buffer: _, data: let data, usedAs: _, clear: _):
                    yIn = data
                case .value(value: _, usedAs: _):
                    break
                }
            }
            else if input.asString == "threshold" {
                thresholdIn = input
            }
            else {
                print("Error: Invalid analysis input: \(String(describing: input.asString))")
            }
        }
        
        for output in outputs {
            if output.asString == "min" {
                minOut = output
            }
            else if output.asString == "position" {
                positionOut = output
            }
            else {
                print("Error: Invalid analysis output: \(String(describing: output.asString))")
            }
        }
        
        try super.init(inputs: inputs, outputs: outputs, additionalAttributes: additionalAttributes)
    }
    
    override func update() {
        #if DEBUG_ANALYSIS
            if xIn != nil && thresholdIn != nil {
                debug_noteInputs(["valIn" : yIn, "posIn" : xIn, "thresholdIn" : thresholdIn])
            }
            else if xIn != nil {
                debug_noteInputs(["valIn" : yIn, "posIn" : xIn])
            }
            else if thresholdIn != nil {
                debug_noteInputs(["valIn" : yIn, "thresholdIn" : thresholdIn])
            }
            else {
                debug_noteInputs(["valIn" : yIn])
            }
        #endif
        
        let inArray = yIn.data
        
        if positionOut == nil && !multiple {
            var min = 0.0
            
            vDSP_minvD(inArray, 1, &min, vDSP_Length(inArray.count))
                        
            if let minOut = minOut {
                switch minOut {
                case .buffer(buffer: let buffer, data: _, usedAs: _, clear: _):
                    buffer.append(min)
                case .value(value: _, usedAs: _):
                    break
                }
            }
            #if DEBUG_ANALYSIS
                debug_noteOutputs(min)
            #endif
            
        }
        else if multiple {
            var min = [Double]()
            var x = [Double]()
            let threshold = thresholdIn?.getSingleValue() ?? 0.0
            
            var thisMin = Double.infinity
            var thisX = -Double.infinity
            for (i, v) in inArray.enumerated() {
                if v > threshold {
                    if (thisX.isFinite) {
                        min.append(thisMin)
                        x.append(thisX)
                        thisMin = Double.infinity
                        thisX = -Double.infinity
                    }
                } else if v < thisMin {
                    thisMin = v
                    thisX = xIn?.data[i] ?? Double(i)
                }
            }
                        
            if let minOut = minOut {
                switch minOut {
                case .buffer(buffer: let buffer, data: _, usedAs: _, clear: _):
                    buffer.appendFromArray(min)
                case .value(value: _, usedAs: _):
                    break
                }
            }

            if let positionOut = positionOut {
                switch positionOut {
                case .buffer(buffer: let buffer, data: _, usedAs: _, clear: _):
                    buffer.appendFromArray(x)
                case .value(value: _, usedAs: _):
                    break
                }
            }
        }
        else {
            var min = -Double.infinity
            var index: vDSP_Length = 0
            
            vDSP_minviD(inArray, 1, &min, &index, vDSP_Length(inArray.count))
            
            let x: Double
            
            if xIn != nil {
                x = xIn!.data[Int(index)]
            }
            else {
                x = Double(index)
            }
                        
            if let minOut = minOut {
                switch minOut {
                case .buffer(buffer: let buffer, data: _, usedAs: _, clear: _):
                    buffer.append(min)
                case .value(value: _, usedAs: _):
                    break
                }
            }
            
            if let positionOut = positionOut {
                switch positionOut {
                case .buffer(buffer: let buffer, data: _, usedAs: _, clear: _):
                    buffer.append(x)
                case .value(value: _, usedAs: _):
                    break
                }
            }

            #if DEBUG_ANALYSIS
                debug_noteOutputs(["min" : min, "pos" : x])
            #endif
            
        }
    }
}
