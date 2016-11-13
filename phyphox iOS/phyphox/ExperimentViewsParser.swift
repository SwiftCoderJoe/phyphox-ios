//
//  ExperimentViewsParser.swift
//  phyphox
//
//  Created by Jonas Gessner on 10.12.15.
//  Copyright © 2015 Jonas Gessner. All rights reserved.
//  By Order of RWTH Aachen.
//

import Foundation

final class ExperimentViewsParser: ExperimentMetadataParser {
    var views: [NSDictionary]?
    
    required init(_ data: NSDictionary) {
        views = getElementsWithKey(data, key: "view") as! [NSDictionary]?
    }
    
    enum GraphAxis {
        case x
        case y
    }
    
    func stringToGraphAxis(string: String) -> GraphAxis? {
        if string.lowercaseString == "x" {
            return .x
        }
        else if string.lowercaseString == "y" {
            return .y
        }
        
        return nil
    }
    
    func parse(buffers: [String: DataBuffer], analysis: ExperimentAnalysis?, translation: ExperimentTranslationCollection?) throws -> [ExperimentViewCollectionDescriptor]? {
        if views == nil {
            return nil
        }
        
        var viewDescriptors: [ExperimentViewCollectionDescriptor] = []
        
        for view in views! {
            let attributes = view[XMLDictionaryAttributesKey] as! [String: String]
            
            let label = attributes["label"]!
            
            var views = [ViewDescriptor!](count: (view["__count"] as! NSNumber).integerValue, repeatedValue: nil)
            
            func handleEdit(edit: [String: AnyObject]) throws -> EditViewDescriptor? {
                let attributes = edit[XMLDictionaryAttributesKey] as! [String: String]
                
                let label = attributes["label"]!
                
                let signed = boolFromXML(attributes, key: "signed", defaultValue: true)
                
                let decimal = boolFromXML(attributes, key: "decimal", defaultValue: true)
                
                let unit = attributes["unit"]
                
                let factor = floatTypeFromXML(attributes, key: "factor", defaultValue: 1.0)
                
                let min = floatTypeFromXML(attributes, key: "min", defaultValue: -Double.infinity)
                let max = floatTypeFromXML(attributes, key: "max", defaultValue: Double.infinity)
                
                let defaultValue = floatTypeFromXML(attributes, key: "default", defaultValue: 0.0)
                
                var outputBuffer: DataBuffer? = nil
                
                if let output = getElementsWithKey(edit, key: "output") {
                    let first = output.first!
                    
                    if first is NSDictionary {
                        let bufferName = (first as! NSDictionary)[XMLDictionaryTextKey] as! String
                        
                        outputBuffer = buffers[bufferName]
                    }
                    else if first is NSString {
                        outputBuffer = buffers[first as! String]
                    }
                }
                
                if outputBuffer == nil {
                    throw SerializationError.InvalidExperimentFile(message: "No output buffer for edit view.")
                }
                
                //Register for updates
                if analysis != nil {
                    analysis!.registerEditBuffer(outputBuffer!)
                }
                
                outputBuffer!.attachedToTextField = true
                
                if outputBuffer!.last == nil {
                    outputBuffer!.append(defaultValue) //Set the default value.
                }
                
                return EditViewDescriptor(label: label, translation: translation, signed: signed, decimal: decimal, unit: unit, factor: factor, min: min, max: max, defaultValue: defaultValue, buffer: outputBuffer!)
            }
            
            func handleValue(value: [String: AnyObject]) throws -> ValueViewDescriptor? {
                let attributes = value[XMLDictionaryAttributesKey] as! [String: String]
                
                let label = attributes["label"]!
                
                let scientific = boolFromXML(attributes, key: "scientific", defaultValue: false)
                let precision = intTypeFromXML(attributes, key: "precision", defaultValue: 2)
                
                let unit = attributes["unit"]
                
                let factor = floatTypeFromXML(attributes, key: "factor", defaultValue: 1.0)
                
                let size = floatTypeFromXML(attributes, key: "size", defaultValue: 1.0)
                
                var inputBuffer: DataBuffer? = nil
                
                if let input = getElementsWithKey(value, key: "input") {
                    let first = input.first!
                    
                    if first is NSDictionary {
                        let bufferName = (first as! NSDictionary)[XMLDictionaryTextKey] as! String
                        
                        inputBuffer = buffers[bufferName]
                    }
                    else if first is NSString {
                        inputBuffer = buffers[first as! String]
                    }
                }
                
                if inputBuffer == nil {
                    throw SerializationError.InvalidExperimentFile(message: "No input buffer for value view.")
                }
                
                let requiresAnalysis = inputBuffer!.dataFromAnalysis
                
                return ValueViewDescriptor(label: label, translation: translation, requiresAnalysis: requiresAnalysis, size: size, scientific: scientific, precision: precision, unit: unit, factor: factor, buffer: inputBuffer!)
            }
            
            func handleGraph(graph: [String: AnyObject]) throws -> GraphViewDescriptor? {
                let attributes = graph[XMLDictionaryAttributesKey] as! [String: String]
                
                let label = attributes["label"]!
                
                let aspectRatio = CGFloatFromXML(attributes, key: "aspectRatio", defaultValue: 2.5)
                let dots = stringFromXML(attributes, key: "style", defaultValue: "line") == "dots"
                let partialUpdate = boolFromXML(attributes, key: "partialUpdate", defaultValue: false)
                let forceFullDataset = boolFromXML(attributes, key: "forceFullDataset", defaultValue: false)
                let history = intTypeFromXML(attributes, key: "history", defaultValue: UInt(1))
                let lineWidth = CGFloatFromXML(attributes, key: "lineWidth", defaultValue: 1.0)
                let color = try UIColorFromXML(attributes, key: "color", defaultValue: kHighlightColor)
                
                let logX = boolFromXML(attributes, key: "logX", defaultValue: false)
                let logY = boolFromXML(attributes, key: "logY", defaultValue: false)
                let xPrecision = UInt(intTypeFromXML(attributes, key: "xPrecision", defaultValue: 3))
                let yPrecision = UInt(intTypeFromXML(attributes, key: "yPrecision", defaultValue: 3))
                
                let scaleMinX: GraphViewDescriptor.scaleMode
                switch stringFromXML(attributes, key: "scaleMinX", defaultValue: "auto") {
                    case "auto": scaleMinX = GraphViewDescriptor.scaleMode.auto
                    case "extend": scaleMinX = GraphViewDescriptor.scaleMode.extend
                    case "fixed": scaleMinX = GraphViewDescriptor.scaleMode.fixed
                    default:
                        scaleMinX = GraphViewDescriptor.scaleMode.auto
                        throw SerializationError.InvalidExperimentFile(message: "Unknown value for scaleMinX.")
                }
                let scaleMaxX: GraphViewDescriptor.scaleMode
                switch stringFromXML(attributes, key: "scaleMaxX", defaultValue: "auto") {
                    case "auto": scaleMaxX = GraphViewDescriptor.scaleMode.auto
                    case "extend": scaleMaxX = GraphViewDescriptor.scaleMode.extend
                    case "fixed": scaleMaxX = GraphViewDescriptor.scaleMode.fixed
                    default:
                        scaleMaxX = GraphViewDescriptor.scaleMode.auto
                        throw SerializationError.InvalidExperimentFile(message: "Error! Unknown value for scaleMaxX.")
                }
                let scaleMinY: GraphViewDescriptor.scaleMode
                switch stringFromXML(attributes, key: "scaleMinY", defaultValue: "auto") {
                    case "auto": scaleMinY = GraphViewDescriptor.scaleMode.auto
                    case "extend": scaleMinY = GraphViewDescriptor.scaleMode.extend
                    case "fixed": scaleMinY = GraphViewDescriptor.scaleMode.fixed
                    default:
                        scaleMinY = GraphViewDescriptor.scaleMode.auto
                        throw SerializationError.InvalidExperimentFile(message: "Error! Unknown value for scaleMinY.")
                }
                let scaleMaxY: GraphViewDescriptor.scaleMode
                switch stringFromXML(attributes, key: "scaleMaxY", defaultValue: "auto") {
                    case "auto": scaleMaxY = GraphViewDescriptor.scaleMode.auto
                    case "extend": scaleMaxY = GraphViewDescriptor.scaleMode.extend
                    case "fixed": scaleMaxY = GraphViewDescriptor.scaleMode.fixed
                    default:
                        scaleMaxY = GraphViewDescriptor.scaleMode.auto
                        throw SerializationError.InvalidExperimentFile(message: "Error! Unknown value for scaleMaxY.")
                }
                
                let minX = CGFloatFromXML(attributes, key: "minX", defaultValue: 0.0)
                let maxX = CGFloatFromXML(attributes, key: "maxX", defaultValue: 0.0)
                let minY = CGFloatFromXML(attributes, key: "minY", defaultValue: 0.0)
                let maxY = CGFloatFromXML(attributes, key: "maxY", defaultValue: 0.0)
                
                
                let xLabel = attributes["labelX"]!
                let yLabel = attributes["labelY"]!
                
                var xInputBuffer: DataBuffer?
                var yInputBuffer: DataBuffer?
                
                if let inputs = getElementsWithKey(graph, key: "input") {
                    for input_ in inputs {
                        if let input = input_ as? [String: AnyObject] {
                            let attributes = input[XMLDictionaryAttributesKey] as! [String: AnyObject]
                            
                            let axisString = attributes["axis"] as! String
                            
                            let axis = stringToGraphAxis(axisString)
                            
                            if axis == nil {
                                throw SerializationError.InvalidExperimentFile(message: "Error! Invalid graph axis: \(axisString)")
                            }
                            
                            let bufferName = input[XMLDictionaryTextKey] as! String
                            
                            let buffer = buffers[bufferName]
                            
                            if buffer == nil {
                                throw SerializationError.InvalidExperimentFile(message: "Error! Unknown buffer name: \(bufferName)")
                            }
                            else {
                                switch axis! {
                                case .y:
                                    yInputBuffer = buffer
                                    break
                                case .x:
                                    xInputBuffer = buffer
                                    break
                                }
                            }
                        }
                        else if input_ is NSString {
                            yInputBuffer = buffers[input_ as! String]
                        }
                    }
                }
                
                if yInputBuffer == nil {
                    throw SerializationError.InvalidExperimentFile(message: "Error! No Y axis input buffer!")
                }
                
                let requiresAnalysis = (yInputBuffer!.dataFromAnalysis || xInputBuffer?.dataFromAnalysis ?? false)
                
                return GraphViewDescriptor(label: label, translation: translation, requiresAnalysis: requiresAnalysis, xLabel: xLabel, yLabel: yLabel, xInputBuffer: xInputBuffer, yInputBuffer: yInputBuffer!, logX: logX, logY: logY, xPrecision: xPrecision, yPrecision: yPrecision, scaleMinX: scaleMinX, scaleMaxX: scaleMaxX, scaleMinY: scaleMinY, scaleMaxY: scaleMaxY, minX: minX, maxX: maxX, minY: minY, maxY: maxY, aspectRatio: aspectRatio, drawDots: dots, partialUpdate: partialUpdate, forceFullDataset: forceFullDataset, history: history, lineWidth: lineWidth, color: color)
            }
            
            func handleInfo(info: [String: AnyObject]) -> InfoViewDescriptor? {
                let attributes = info[XMLDictionaryAttributesKey] as! [String: String]
                
                let label = attributes["label"]!
                
                return InfoViewDescriptor(label: label, translation: translation)
            }
            
            func handleButton(button: [String: AnyObject]) throws -> ButtonViewDescriptor? {
                let attributes = button[XMLDictionaryAttributesKey] as! [String: String]
                
                let label = attributes["label"]!
                var inputList : [ExperimentAnalysisDataIO] = []
                var outputList : [DataBuffer] = []
                
                if let inputs = getElementsWithKey(button, key: "input") {
                    for input_ in inputs {
                        if let input = input_ as? [String: AnyObject] {
                            inputList.append(ExperimentAnalysisDataIO(dictionary: input, buffers: buffers))
                        }
                    }
                }
                if let outputs = getElementsWithKey(button, key: "output") {
                    for output in outputs {
                        if let bufferName = output as? String {
                            let buffer = buffers[bufferName]
                            
                            if buffer == nil {
                                throw SerializationError.InvalidExperimentFile(message: "Error! Unknown buffer name: \(bufferName)")
                            }

                            if analysis != nil {
                                analysis!.registerEditBuffer(buffer!)
                            }
                            outputList.append(buffer!)
                        }
                    }
                }
                
                return ButtonViewDescriptor(label: label, translation: translation, inputs: inputList, outputs: outputList)
            }
            
            var deleteIndices: [Int] = []
            
            for (key, child) in view {
                if key as! String == "graph" {
                    for g in getElemetArrayFromValue(child) as! [[String: AnyObject]] {
                        let index = (g["__index"] as! NSNumber).integerValue
                        
                        if let graph = try handleGraph(g) {
                            views[index] = graph
                        }
                        else {
                            deleteIndices.append(index)
                        }
                    }
                }
                else if key as! String == "value" {
                    for g in getElemetArrayFromValue(child) as! [[String: AnyObject]] {
                        let index = (g["__index"] as! NSNumber).integerValue
                        
                        if let graph = try handleValue(g) {
                            views[index] = graph
                        }
                        else {
                            deleteIndices.append(index)
                        }
                    }
                }
                else if key as! String == "edit" {
                    for g in getElemetArrayFromValue(child) as! [[String: AnyObject]] {
                        let index = (g["__index"] as! NSNumber).integerValue
                        
                        if let graph = try handleEdit(g) {
                            views[index] = graph
                        }
                        else {
                            deleteIndices.append(index)
                        }
                    }
                }
                else if key as! String == "info" {
                    for g in getElemetArrayFromValue(child) as! [[String: AnyObject]] {
                        let index = (g["__index"] as! NSNumber).integerValue
                        
                        if let graph = handleInfo(g) {
                            views[index] = graph
                        }
                        else {
                            deleteIndices.append(index)
                        }
                    }
                }
                else if key as! String == "button" {
                    for g in getElemetArrayFromValue(child) as! [[String: AnyObject]] {
                        let index = (g["__index"] as! NSNumber).integerValue
                        
                        if let button = try handleButton(g) {
                            views[index] = button
                        }
                        else {
                            deleteIndices.append(index)
                        }
                    }
                }
                else if !(key as! String).hasPrefix("__") {
                    throw SerializationError.InvalidExperimentFile(message: "Error! Unknown view element: \(key as! String)")
                }
            }
            
            if deleteIndices.count > 0 {
                views.removeAtIndices(deleteIndices)
            }
            
            let viewDescriptor = ExperimentViewCollectionDescriptor(label: label, translation: translation, views: views as! [ViewDescriptor])
            
            viewDescriptors.append(viewDescriptor)
        }
        
        return (viewDescriptors.count > 0 ? viewDescriptors : nil)
    }
}
