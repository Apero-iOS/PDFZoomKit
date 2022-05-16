//
//  ToolZoomManager.swift
//  PDFZoomKit
//
//  Created by ANH VU on 12/05/2022.
//

import Foundation
import UIKit
import AVFoundation
import PDFKit

public class ToolZoomManager {
    
//    MARK: - Propety
    private var strokeColor: CGColor = UIColor.white.cgColor
    private var zoomGestureManager: ZoomGestureManager!
    private var quadViewWidthConstraint = NSLayoutConstraint()
    private var quadViewHeightConstraint = NSLayoutConstraint()
    private var touchDown: UILongPressGestureRecognizer!
    private var quad: Quadrilateral!
    private var mainView: UIView!
    private var viewPDF: PDFView!
    private var originFrame: CGFloat = 100
    private var scale: CGFloat = 2
    
    private lazy var quadView: QuadrilateralView = {
        let quadView = QuadrilateralView()
        quadView.editable = true
        quadView.translatesAutoresizingMaskIntoConstraints = false
        return quadView
    }()
    
    //    MARK: - Init
    public init(viewPDF: PDFView, mainView: UIView, originFrame: CGFloat = 100, strokeColor: CGColor = UIColor.gray.cgColor, scale: CGFloat = 2) {
        self.viewPDF = viewPDF
        self.strokeColor = strokeColor
        self.originFrame = originFrame
        self.mainView = mainView
        zoomGestureManager = ZoomGestureManager(pdfView: viewPDF, quadView: quadView, scale: scale)
        touchDown = UILongPressGestureRecognizer(target: zoomGestureManager, action: #selector(zoomGestureManager.handle(pan:)))
        touchDown.isEnabled = false
        touchDown.minimumPressDuration = 0
        quadView.addGestureRecognizer(touchDown)
        //        self.view.clipsToBounds = true
    }
    
    // MARK: - public Function
    public func showToolZoom(isShow: Bool) {
        if isShow {
            self.quad = viewPDF.document?.defaultQuadOffset(offset: originFrame)
            self.setupViews()
            self.setupConstraints()
            self.adjustQuadViewConstraints()
            self.displayQuad()
        } else {
            self.quadView.removeFromSuperview()
            self.quadView.resetHighlightedCornerViews()
        }
        self.touchDown.isEnabled = isShow
    }
    
    // MARK: - Private Function
    private func setupConstraints() {
        quadViewWidthConstraint = quadView.widthAnchor.constraint(equalToConstant: 0.0)
        quadViewHeightConstraint = quadView.heightAnchor.constraint(equalToConstant: 0.0)
        
        let quadViewConstraints = [
            quadView.centerXAnchor.constraint(equalTo: viewPDF.centerXAnchor),
            quadView.centerYAnchor.constraint(equalTo: viewPDF.centerYAnchor),
            quadViewWidthConstraint,
            quadViewHeightConstraint
        ]
        
        NSLayoutConstraint.activate(quadViewConstraints + viewPDF.constraints)
    }
    
    private func setupViews() {
        mainView.addSubview(quadView)
    }
    
    /// The quadView should be lined up on top of the actual image displayed by the imageView.
    /// Since there is no way to know the size of that image before run time, we adjust the constraints to make sure that the quadView is on top of the displayed image.
    private func adjustQuadViewConstraints() {
        let frame = AVMakeRect(aspectRatio: viewPDF.frame.size, insideRect: viewPDF.bounds)
        quadViewWidthConstraint.constant = frame.size.width
        quadViewHeightConstraint.constant = frame.size.height
    }
    
    private func displayQuad() {
        quadView.strokeColor = strokeColor
        let imageSize = viewPDF.frame.size
        let imageFrame = CGRect(origin: quadView.frame.origin, size: CGSize(width: quadViewWidthConstraint.constant, height: quadViewHeightConstraint.constant))
        
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: imageSize, aspectFillInSize: imageFrame.size)
        let transforms = [scaleTransform]
        let transformedQuad = quad.applyTransforms(transforms)
        
        quadView.drawQuadrilateral(quad: transformedQuad, animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.zoomGestureManager.zoomLocation(location: transformedQuad.topLeft)
        }
    }
}
