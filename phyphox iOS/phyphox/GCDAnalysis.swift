//
//  GCDAnalysis.swift
//  phyphox
//
//  Created by Jonas Gessner on 06.12.15.
//  Copyright © 2015 Jonas Gessner. All rights reserved.
//  By Order of RWTH Aachen.
//


import Foundation

func gcd(u: UInt, _ v: UInt) -> UInt {
    // simple cases (termination)
    if (u == v) {
        return u
    }
    
    if (u == 0) {
        return v
    }
    
    if (v == 0) {
        return u
    }
    
    // look for factors of 2
    if (~u & 1) == 1 {// u is even
        if (v & 1) == 1 {// v is odd
            return gcd(u >> 1, v)
        }
        else {// both u and v are even
            return gcd(u >> 1, v >> 1) << 1
        }
    }
    
    if (~v & 1) == 1 { // u is odd, v is even
        return gcd(u, v >> 1)
    }
    
    // reduce larger argument
    if (u > v) {
        return gcd((u - v) >> 1, v)
    }
    
    return gcd((v - u) >> 1, u)
}

final class GCDAnalysis: ExperimentComplexUpdateValueAnalysis {
    
    override func update() {
        updateAllWithMethod({ inputs -> ValueSource in
            var main = inputs.first!
            
            for (i, input) in inputs.enumerate() {
                if i > 0 {
                    main = self.gcdValueSources(main, b: input)
                }
            }
            
            
            return main
            }, priorityInputKey: nil)
    }
    
    func gcdValueSources(a: ValueSource, b: ValueSource) -> ValueSource {
        if let scalarA = a.scalar, let scalarB = b.scalar { // gcd(scalar,scalar)
            if !isfinite(scalarA) || !isfinite(scalarB) {
                return ValueSource(scalar: Double.NaN)
            }
            
            let result = Double(gcd(UInt(scalarA), UInt(scalarB)))
            
            return ValueSource(scalar: result)
        }
        else if let scalar = a.scalar, let vector = b.vector { // gcd(scalar,vector)
            var out = [Double]()
            out.reserveCapacity(vector.count)
            
            for val in vector {
                if !isfinite(val) || !isfinite(scalar) {
                    out.append(Double.NaN)
                }
                else {
                    out.append(Double(gcd(UInt(scalar), UInt(val))))
                }
            }
            
            return ValueSource(vector: out)
        }
        else if let vector = a.vector, let scalar = b.scalar { // gcd(vector,scalar)
            var out = [Double]()
            out.reserveCapacity(vector.count)
            
            for val in vector {
                if !isfinite(val) || !isfinite(scalar) {
                    out.append(Double.NaN)
                }
                else {
                    out.append(Double(gcd(UInt(scalar), UInt(val))))
                }
            }
            
            return ValueSource(vector: out)
        }
        else if let vectorA = a.vector, let vectorB = b.vector { // gcd(vector,vector)
            var out = [Double]()
            out.reserveCapacity(vectorA.count)
            
            for (i, val) in vectorA.enumerate() {
                let valB = vectorB[i]
                
                if !isfinite(val) || !isfinite(valB) {
                    out.append(Double.NaN)
                }
                else {
                    out.append(Double(gcd(UInt(valB), UInt(val))))
                }
                
            }
            
            return ValueSource(vector: out)
        }
        
        assert(false, "Invalid value sources")
    }

}
