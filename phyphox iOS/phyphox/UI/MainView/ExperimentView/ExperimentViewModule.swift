//
//  ExperimentViewModule.swift
//  phyphox
//
//  Created by Jonas Gessner on 13.01.16.
//  Copyright © 2016 Jonas Gessner. All rights reserved.
//  By Order of RWTH Aachen.
//

import UIKit

protocol Activatable {
    var active: Bool { get set }
}

typealias ExperimentViewModuleView = Activatable & UIView

class ExperimentViewModule<Descriptor: ViewDescriptor>: UIView, Activatable {
    let descriptor: Descriptor
    
    let label: UILabel
    var active = false {
        didSet {
            if active {
                setNeedsUpdate()
            }
        }
    }

    var wantsUpdatesWhenInactive = false
    
    var delegate: ModuleExclusiveViewDelegate? = nil

    required init?(descriptor: Descriptor) {
        label = UILabel()
        label.numberOfLines = 0
        
        label.text = descriptor.localizedLabel

        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        label.textColor = kTextColor
        
        self.descriptor = descriptor
        
        super.init(frame: CGRect.zero)
        
        addSubview(label)
    }

    func registerInputBuffer(_ buffer: DataBuffer) {
        buffer.addObserver(self, alwaysNotify: true)
    }
    
    private var updateScheduled: Bool = false
    
    func setNeedsUpdate() {
        if (active || wantsUpdatesWhenInactive) && !updateScheduled {
            updateScheduled = true
            triggerUpdate()
        }
    }
    
    private func triggerUpdate() {
        if updateScheduled {
            //60fps max
            after(1.0/60.0) {
                self.update()
                self.updateScheduled = false
            }
        }
    }
    
    func update() {}
    
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ExperimentViewModule: DataBufferObserver {
    func dataBufferUpdated(_ buffer: DataBuffer) {
        setNeedsUpdate()
    }
}
