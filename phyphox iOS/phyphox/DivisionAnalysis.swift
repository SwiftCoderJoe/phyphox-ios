//
//  DivisionAnalysis.swift
//  phyphox
//
//  Created by Jonas Gessner on 05.12.15.
//  Copyright © 2015 Jonas Gessner. All rights reserved.
//  By Order of RWTH Aachen.
//


import Foundation
import Accelerate

final class DivisionAnalysis: ExperimentComplexUpdateValueAnalysis {
    
    override func update() {
        updateAllWithMethod({ (inputs) -> ValueSource in
            var main = inputs.first!
            
            for (i, input) in inputs.enumerate() {
                if i > 0 {
                    main = self.divideValueSources(main, b: input)
                }
            }
            
            return main
            },  priorityInputKey: "dividend")
    }
    
    func divideValueSources(a: ValueSource, b: ValueSource) -> ValueSource {
        if let scalarA = a.scalar, let scalarB = b.scalar { // scalar/scalar
            let result = scalarA/scalarB
            
            return ValueSource(scalar: result)
        }
        else if var scalar = a.scalar, let vector = b.vector { // scalar/vector
            var out = vector
            
            vDSP_svdivD(&scalar, vector, 1, &out, 1, vDSP_Length(out.count))
            
            return ValueSource(vector: out)
        }
        else if let vector = a.vector, var scalar = b.scalar { // vector/scalar
            var out = vector
            
            vDSP_vsdivD(vector, 1, &scalar, &out, 1, vDSP_Length(out.count))
            
            return ValueSource(vector: out)
        }
        else if let vectorA = a.vector, let vectorB = b.vector { // vector/vector
            var out = vectorA
            
            vDSP_vdivD(vectorB, 1, vectorA, 1, &out, 1, vDSP_Length(out.count))
            
            return ValueSource(vector: out)
        }
        
        assert(false, "Invalid value sources")
    }
}
