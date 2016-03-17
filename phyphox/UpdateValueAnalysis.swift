//
//  UpdateValueAnalysis.swift
//  phyphox
//
//  Created by Jonas Gessner on 21.01.16.
//  Copyright © 2016 RWTH Aachen. All rights reserved.
//

import Foundation
import Surge

//TODO: Test performance iterative vs Surge

/**
 An abstract analysis module that takes one input and one output, writing each value of the input into the output (and clearing the output beforehand), after allowing a closure to update the value.
*/
class UpdateValueAnalysis: ExperimentAnalysisModule {
    
    internal func updateIterativelyWithMethod(method: (Double) -> Double) {
        let input = inputs.first!
        
        let outBuffer = outputs.first!.buffer!
        
        var append: [Double] = []
        
        var max: Double? = nil
        var min: Double? = nil
        
        func appendValue(rawValue value: Double) {
            let processed = method(value)
            
            if max == nil || processed > max {
                max = processed
            }
            
            if min == nil || processed < min {
                min = processed
            }
            
            append.append(processed)
        }
        
        if let buffer = input.buffer {
            for val in buffer {
                appendValue(rawValue: val)
            }
        }
        else {
            appendValue(rawValue: input.value!)
        }
        
        outBuffer.replaceValues(append, max: max, min: min)
    }
    
    internal func updateAllWithMethod(method: ([Double]) -> [Double]) {
        let input = inputs.first!
        
        let outBuffer = outputs.first!.buffer!
        
        var process: [Double] = []
        
        if let buffer = input.buffer {
            process.appendContentsOf(buffer)
        }
        else {
            process.append(input.value!)
        }
        
        let append = method(process)
        
        let max: Double? = Surge.max(append)
        let min: Double? = Surge.min(append)
        
        outBuffer.replaceValues(append, max: max, min: min)
    }

}
