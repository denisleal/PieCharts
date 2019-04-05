//
//  PieLineViewLayer.swift
//  PieCharts
//
//  Created by admdenlea01 on 2019-04-05.
//  Copyright © 2019 Ivan Schuetz. All rights reserved.
//

import UIKit

open class PieLineCustomViewsLayerSettings {

    public var viewRadius: CGFloat?
    public var lineColor: UIColor = UIColor.black
    public var lineWidth: CGFloat = 1
    public var lineSegmentLength: CGFloat = 100
    public var isCentered = true

    public var hideOnOverflow = true // NOTE: Considers only space defined by angle with origin at the center of the pie chart. Arcs (inner/outer radius) are ignored.

    public init() {}
}

open class PieLineCustomViewsLayer: PieChartLayer {

    public weak var chart: PieChart?

    public var settings: PieLineCustomViewsLayerSettings = PieLineCustomViewsLayerSettings()

    public var onNotEnoughSpace: ((UIView, CGSize) -> Void)?

    fileprivate var sliceViews = [PieSlice: (lineLayer: CALayer?, view: UIView)]()

    public var animator: PieViewLayerAnimator = AlphaPieViewLayerAnimator()

    public var viewGenerator: ((PieSlice, CGPoint) -> UIView)?

    public init() {}

    public func onEndAnimation(slice: PieSlice) {
        addItems(slice: slice)
    }

    public func addItems(slice: PieSlice) {
        guard sliceViews[slice] == nil else {return}

        var lineLayer: CALayer? = nil
        let p1 = slice.view.calculatePosition(angle: slice.view.midAngle, p: slice.view.center, offset: slice.view.outerRadius - 6)
        let p2 = slice.view.calculatePosition(angle: slice.view.midAngle, p: slice.view.center, offset: settings.viewRadius ?? slice.view.outerRadius)
        let angle = slice.view.midAngle.truncatingRemainder(dividingBy: (CGFloat.pi * 2))
        let isRightSide = angle >= 0 && angle <= (CGFloat.pi / 2) || (angle > (CGFloat.pi * 3 / 2) && angle <= CGFloat.pi * 2)

        if let viewRadius = settings.viewRadius, viewRadius > slice.view.outerRadius {
            lineLayer = createLine(p1: p1, p2: p2)
        }

        let center = p2 //settings.viewRadius.map{slice.view.midPoint(radius: $0)} ?? slice.view.arcCenter

        guard let view = viewGenerator?(slice, center) else {print("Need a view generator to create views!"); return}

        let size = view.frame.size

        let availableSize = CGSize(width: slice.view.maxRectWidth(center: center, height: size.height), height: size.height)

        if !settings.hideOnOverflow || availableSize.contains(size) {
            view.center = center
            if !settings.isCentered {
                let direction: CGFloat = isRightSide ? 1 : -1
                view.frame = view.frame.applying(.init(translationX: direction*size.width/2, y: 0))
            }

            chart?.addSubview(view)

        } else {
            onNotEnoughSpace?(view, availableSize)
        }

        if let lineLayer = lineLayer {
            chart?.container.addSublayer(lineLayer)
        }

        animator.animate(view)

        sliceViews[slice] = (lineLayer, view)
    }

    public func createLine(p1: CGPoint, p2: CGPoint, p3: CGPoint? = nil) -> CALayer {
        let path = UIBezierPath()
        path.move(to: p1)
        path.addLine(to: p2)
        if let p3 = p3 {
            path.addLine(to: p3)
        }

        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = settings.lineColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.borderWidth = settings.lineWidth

        return layer
    }

    public func onSelected(slice: PieSlice, selected: Bool) {
        guard let label = sliceViews[slice]?.view else {print("Invalid state: slice not in dictionary"); return}

        let p = slice.view.calculatePosition(angle: slice.view.midAngle, p: label.center, offset: selected ? slice.view.selectedOffset : -slice.view.selectedOffset)
        UIView.animate(withDuration: 0.15) {
            label.center = p
        }
    }

    public func clear() {
        for (_, sliceView) in sliceViews {
            sliceView.view.removeFromSuperview()
        }
        sliceViews.removeAll()
    }
}
