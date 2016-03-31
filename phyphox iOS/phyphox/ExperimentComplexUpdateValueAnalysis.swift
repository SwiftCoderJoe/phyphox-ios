//
//  ExperimentComplexUpdateValueAnalysis.swift
//  phyphox
//
//  Created by Jonas Gessner on 31.01.16.
//  Copyright © 2016 RWTH Aachen. All rights reserved.
//

import Foundation

internal final class ValueSource : CustomStringConvertible {
    var vector: [Double]?
    var scalar: Double?
    
    init(scalar: Double) {
        self.scalar = scalar
    }
    
    init(vector: [Double]) {
        self.vector = vector
    }
    
    var description: String {
        get {
            if vector != nil {
                return "Vector: \(vector!)"
            }
            else {
                return "Scalar: \(scalar!)"
            }
        }
    }
}

class ExperimentComplexUpdateValueAnalysis: ExperimentAnalysisModule {
    
    func updateAllWithMethod(method: [ValueSource] -> ValueSource, priorityInputKey: String?) {
        var values: [ValueSource] = []
        var maxCount = 0
        var maxNonScalarCount = 0 //Scalar and an empty vector should give an empty result
        
        for input in inputs {
            if let fixed = input.value {
                let src = ValueSource(scalar: fixed)
                
                if priorityInputKey != nil && input.asString == priorityInputKey! {
                    values.insert(src, atIndex: 0)
                }
                else {
                    values.append(src)
                }
                
                maxCount = Swift.max(maxCount, 1)
            }
            else {
                let array = input.buffer!.toArray()
                
                let src = array.count == 1 ? ValueSource(scalar: array[0]) : ValueSource(vector: array)
                
                if priorityInputKey != nil && input.asString == priorityInputKey! {
                    values.insert(src, atIndex: 0)
                }
                else {
                    values.append(src)
                }
                
                maxNonScalarCount = Swift.max(maxNonScalarCount, array.count)
                maxCount = Swift.max(maxCount, array.count)
            }
        }
        
        let result: [Double]
        
        if values.count == 0 || maxCount == 0 || maxNonScalarCount == 0 {
            result = []
        }
        else {
            for valueSource in values {
                if var array = valueSource.vector {
                    let delta = maxCount-array.count
                    
                    if delta > 0 {
                        array.appendContentsOf([Double](count: delta, repeatedValue: array.last ?? 0.0))
                        valueSource.vector = array
                    }
                }
            }
            
            #if DEBUG_ANALYSIS
                debug_noteInputs(values.description)
            #endif
            
            let out = method(values)
            
            #if DEBUG_ANALYSIS
                debug_noteOutputs(out)
            #endif
            
            result = (out.scalar != nil ? [out.scalar!] : out.vector!)
        }
        
        for output in outputs {
            if output.clear {
                output.buffer!.replaceValues(result)
            }
            else {
                output.buffer!.appendFromArray(result)
            }
        }
    }
    
}
