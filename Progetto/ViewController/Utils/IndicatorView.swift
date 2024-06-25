//
//  IndicatorView.swift
//  AccessibleAR
//
//  Created by Kristian Keller on 08/08/23.
//

import Foundation
import UIKit

class IndicatorView: UIView {
    
    var xTopLeft: CGFloat = -100 {
        didSet {
            setNeedsDisplay()
        }
    }

    var yTopLeft: CGFloat = -100 {
        didSet {
            setNeedsDisplay()
        }
    }

    var width: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var height: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var color: UIColor = UIColor(named: "SelectionColor")! {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var lineWidth: CGFloat = 20 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func contains(point: CGPoint) -> Bool {
        let rect = CGRect(x: xTopLeft, y: yTopLeft, width: width, height: height)
        return rect.contains(point)
    }

    override func draw(_ rect: CGRect) {
        backgroundColor = .clear
    
        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(lineWidth)
            color.set()
            let rect = CGRect(x: xTopLeft, y: yTopLeft, width: width, height: height)
            context.addRect(rect)
            context.strokePath()
        }
    }
}
