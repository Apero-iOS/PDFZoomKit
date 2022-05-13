import Foundation
import AVFoundation
import UIKit

final class ZoomGestureController {
    
    private let pdfView: UIView?
    private let quadView: QuadrilateralView
    private var previousPanPosition: CGPoint?
    private var closestCorner: CornerPosition?
    private var scaleQuadView: CGFloat = 2
    
    init(pdfView: UIView, quadView: QuadrilateralView, scale: CGFloat = 2) {
        self.pdfView = pdfView
        self.quadView = quadView
        self.scaleQuadView = scale
    }

    @objc func handle(pan: UIGestureRecognizer) {
        guard let drawnQuad = quadView.quad else {
            return
        }
        
        guard pan.state != .ended else {
            self.previousPanPosition = nil
            self.closestCorner = nil
            quadView.resetHighlightedCornerViews()
            return
        }
        
        let position = pan.location(in: pdfView)

        let previousPanPosition = self.previousPanPosition ?? position
        let closestCorner = self.closestCorner ?? position.closestCornerFrom(quad: drawnQuad)
        
        let offset = CGAffineTransform(translationX: position.x - previousPanPosition.x, y: position.y - previousPanPosition.y)
        let cornerView = quadView.cornerViewForCornerPosition(position: closestCorner)
        let draggedCornerViewCenter = cornerView.center.applying(offset)
        
        quadView.moveCorner(cornerView: cornerView, atPoint: draggedCornerViewCenter)
        
        self.previousPanPosition = position
        self.closestCorner = closestCorner
        
        let scale = (pdfView?.frame.width ?? .zero) / quadView.frame.width
        let scaledDraggedCornerViewCenter = CGPoint(x: draggedCornerViewCenter.x , y: draggedCornerViewCenter.y * scale)
        let targetSize = CGSize(width: quadView.highlightedCornerViewSize.width * scale, height: quadView.highlightedCornerViewSize.height * scale)
        guard let zoomedImage = pdfView?.scaledView(atPoint: scaledDraggedCornerViewCenter, scaleFactor: scaleQuadView, targetSize: targetSize) else {
            return
        }
        quadView.highlightCornerAtPosition(position: closestCorner, with: zoomedImage)
    }
    
    func zoomLocation(location: CGPoint) {
        guard let drawnQuad = quadView.quad else {
            return
        }

        let position = location
        
        let previousPanPosition = self.previousPanPosition ?? position
        let closestCorner = self.closestCorner ?? position.closestCornerFrom(quad: drawnQuad)
        
        let offset = CGAffineTransform(translationX: position.x - previousPanPosition.x, y: position.y - previousPanPosition.y)
        let cornerView = quadView.cornerViewForCornerPosition(position: closestCorner)
        let draggedCornerViewCenter = cornerView.center.applying(offset)
        
        quadView.moveCorner(cornerView: cornerView, atPoint: draggedCornerViewCenter)
        
        self.previousPanPosition = position
        self.closestCorner = closestCorner
        
        let scale = (pdfView?.frame.width ?? .zero) / quadView.frame.width
        let scaledDraggedCornerViewCenter = CGPoint(x: draggedCornerViewCenter.x * scale, y: draggedCornerViewCenter.y * scale)
        let targetSize = CGSize(width: quadView.highlightedCornerViewSize.width * scale, height: quadView.highlightedCornerViewSize.height * scale)
        guard let zoomedImage = pdfView?.scaledView(atPoint: scaledDraggedCornerViewCenter, scaleFactor: scaleQuadView, targetSize: targetSize) else {
            return
        }
        
        quadView.highlightCornerAtPosition(position: closestCorner, with: zoomedImage)
    }
    
    
}
