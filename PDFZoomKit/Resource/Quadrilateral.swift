//
//  Quadrilateral.swift
//  PDFZoomKit
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
import AVFoundation
import Vision
import UIKit
import CoreImage

/// A data structure representing a quadrilateral and its position. This class exists to bypass the fact that CIRectangleFeature is read-only.
public struct Quadrilateral: Transformable {
    
    /// A point that specifies the top left corner of the quadrilateral.
    public var topLeft: CGPoint

    public var description: String {
        return "topLeft: \(topLeft)"
    }

    /// The perimeter of the Quadrilateral
    var perimeter: Double {
        let perimeter = topLeft.distanceTo(point: topLeft)
        return Double(perimeter)
    }
    
    init(rectangleFeature: CIRectangleFeature) {
        self.topLeft = rectangleFeature.topLeft
    }

    @available(iOS 11.0, *)
    init(rectangleObservation: VNRectangleObservation) {
        self.topLeft = rectangleObservation.topLeft
    }

    init(topLeft: CGPoint) {
        self.topLeft = topLeft
    }
    
    /// Applies a `CGAffineTransform` to the quadrilateral.
    ///
    /// - Parameters:
    ///   - t: the transform to apply.
    /// - Returns: The transformed quadrilateral.
    func applying(_ transform: CGAffineTransform) -> Quadrilateral {
        let quadrilateral = Quadrilateral(topLeft: topLeft.applying(transform))
        
        return quadrilateral
    }
    
    /// Checks whether the quadrilateral is withing a given distance of another quadrilateral.
    ///
    /// - Parameters:
    ///   - distance: The distance (threshold) to use for the condition to be met.
    ///   - rectangleFeature: The other rectangle to compare this instance with.
    /// - Returns: True if the given rectangle is within the given distance of this rectangle instance.
    func isWithin(_ distance: CGFloat, ofRectangleFeature rectangleFeature: Quadrilateral) -> Bool {
        
        let topLeftRect = topLeft.surroundingSquare(withSize: distance)
        if !topLeftRect.contains(rectangleFeature.topLeft) {
            return false
        }
        return true
    }
    
    func isSame(_ distance: CGFloat,  ofRectangleFeature rectangleFeature: Quadrilateral) -> Bool {
        
        let topLeftRect = topLeft.surroundingSquare(withSize: distance)
        if !topLeftRect.same(width: rectangleFeature.topLeft)  {
            return false
        }
        return true
        
    }
    
    /// Reorganizes the current quadrilateal, making sure that the points are at their appropriate positions. For example, it ensures that the top left point is actually the top and left point point of the quadrilateral.
    mutating func reorganize() {
        let points = [topLeft]
        let ySortedPoints = sortPointsByYValue(points)
        
        guard ySortedPoints.count == 4 else {
            return
        }
        
        let topMostPoints = Array(ySortedPoints[0..<2])
        let bottomMostPoints = Array(ySortedPoints[2..<4])
        let xSortedTopMostPoints = sortPointsByXValue(topMostPoints)
        let xSortedBottomMostPoints = sortPointsByXValue(bottomMostPoints)
        
        guard xSortedTopMostPoints.count > 1,
            xSortedBottomMostPoints.count > 1 else {
                return
        }
        
        topLeft = xSortedTopMostPoints[0]
    }
    
    /// Scales the quadrilateral based on the ratio of two given sizes, and optionaly applies a rotation.
    ///
    /// - Parameters:
    ///   - fromSize: The size the quadrilateral is currently related to.
    ///   - toSize: The size to scale the quadrilateral to.
    ///   - rotationAngle: The optional rotation to apply.
    /// - Returns: The newly scaled and potentially rotated quadrilateral.
    func scale(_ fromSize: CGSize, _ toSize: CGSize, withRotationAngle rotationAngle: CGFloat = 0.0) -> Quadrilateral {
        var invertedfromSize = fromSize
        let rotated = rotationAngle != 0.0
        
        if rotated && rotationAngle != CGFloat.pi {
            invertedfromSize = CGSize(width: fromSize.height, height: fromSize.width)
        }
            
        var transformedQuad = self
        let invertedFromSizeWidth = invertedfromSize.width == 0 ? .leastNormalMagnitude : invertedfromSize.width
        let invertedFromSizeHeight = invertedfromSize.height == 0 ? .leastNormalMagnitude : invertedfromSize.height
        
        let scaleWidth = toSize.width / invertedFromSizeWidth
        let scaleHeight = toSize.height / invertedFromSizeHeight
        let scaledTransform = CGAffineTransform(scaleX: scaleWidth, y: scaleHeight)
        transformedQuad = transformedQuad.applying(scaledTransform)
        
        if rotated {
            let rotationTransform = CGAffineTransform(rotationAngle: rotationAngle)
            
            let fromImageBounds = CGRect(origin: .zero, size: fromSize).applying(scaledTransform).applying(rotationTransform)
            
            let toImageBounds = CGRect(origin: .zero, size: toSize)
            let translationTransform = CGAffineTransform.translateTransform(fromCenterOfRect: fromImageBounds, toCenterOfRect: toImageBounds)
            
            transformedQuad = transformedQuad.applyTransforms([rotationTransform, translationTransform])
        }
        
        return transformedQuad
    }
    
    // Convenience functions
    
    /// Sorts the given `CGPoints` based on their y value.
    /// - Parameters:
    ///   - points: The poinmts to sort.
    /// - Returns: The points sorted based on their y value.
    private func sortPointsByYValue(_ points: [CGPoint]) -> [CGPoint] {
        return points.sorted { (point1, point2) -> Bool in
            point1.y < point2.y
        }
    }
    
    /// Sorts the given `CGPoints` based on their x value.
    /// - Parameters:
    ///   - points: The points to sort.
    /// - Returns: The points sorted based on their x value.
    private func sortPointsByXValue(_ points: [CGPoint]) -> [CGPoint] {
        return points.sorted { (point1, point2) -> Bool in
            point1.x < point2.x
        }
    }
}

extension Quadrilateral {
    
    /// Converts the current to the cartesian coordinate system (where 0 on the y axis is at the bottom).
    ///
    /// - Parameters:
    ///   - height: The height of the rect containing the quadrilateral.
    /// - Returns: The same quadrilateral in the cartesian corrdinate system.
    func toCartesian(withHeight height: CGFloat) -> Quadrilateral {
        let topLeft = self.topLeft.cartesian(withHeight: height)
        return Quadrilateral(topLeft: topLeft)
    }
}

extension Quadrilateral: Equatable {
    public static func == (lhs: Quadrilateral, rhs: Quadrilateral) -> Bool {
        return lhs.topLeft == rhs.topLeft
    }
    
    func rotate(imageSize: CGSize) -> Quadrilateral {
        let topLeft = CGPoint(x: imageSize.width - self.topLeft.y, y: self.topLeft.x)
        return Quadrilateral(topLeft: topLeft)
    }
}

