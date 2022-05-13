//
//  CGRect+Extension.swift
//  PDFZoomKit
//
//  Created by Trung on 14/08/2021.
//

import UIKit

extension CGRect {
    func same(width cGPoint: CGPoint) -> Bool {
        if abs(self.origin.x - cGPoint.x) > 50 {
            return false
        }
        
        if abs(self.origin.y - cGPoint.y) > 50 {
            return false
        }
        
        return true
    }
    
    var center: CGPoint {
        .init(x: midX, y: midY)
    }
    
    func scale(ratio: CGFloat) -> CGRect {
        return CGRect(x: origin.x * ratio, y: origin.y * ratio, width: width * ratio, height: height * ratio)
    }
    
    func moveDown(deltaY: CGFloat) -> CGRect {
        return CGRect(x: origin.x , y: origin.y + deltaY, width: width, height: height)
    }
}
