//
//  IBTC.swift
//
//  IBToCode
//  Generate the code needed to recreate a layout made in Interface Builder programmatically.
//
//  Created by Xavier Daleau on 28/02/2017.
//  Copyright (c) 2017 Xavier Daleau <xavier.daleau@gmail.com>

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.

//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import UIKit

/// This class stores all the data needed to rebuild a view in code
class IBTCView {
    
    var view: UIView
    var name: String
    var subviews: [IBTCView]
    var subViewIndex: UInt
    var superView: IBTCView?
    var constraints: [NSLayoutConstraint]
    var order:UInt = 0
    var depth:UInt = 0
    var properties: Dictionary<String,Any>!
    var initFunctions:[String] = []
    
    init(view:UIView, name:String, subviews:[IBTCView], subViewIndex:UInt, superView:IBTCView?, constraints:[NSLayoutConstraint], depth:UInt, order:UInt){
        self.view = view
        self.name = name
        self.subviews = subviews
        self.subViewIndex = subViewIndex
        self.superView = superView
        self.constraints = constraints
        self.order = order
        self.depth = depth
        self.properties = IBTCProperties.extractProperties(ibtcView: self)
    }     
}

extension IBTCView: Equatable {
    static func == (lhs: IBTCView, rhs: IBTCView) -> Bool {
        return lhs.view == rhs.view
    }
}


public class IBToCode {
    
    
    // OPTIONS
    
    public enum IBTCViewSortingMode{
        case none
        case topToDown
        case distance
        case leftToRight
    }
    
    public enum IBTCConstraintsFormats{
        case nsLayoutConstraint
        case anchors
        case snapKit3  // Snapkit 3.0
    }
    
    
    public static let version = "0.1.1"

    
    /// You can chose here the way you want the layout constraints to be written. Options are anchor constraints, regular constraints and Snapkit.
    public static var constraintFormat: IBTCConstraintsFormats = .nsLayoutConstraint
    /// This variable let you removes views without constraints from the output. Most of the time, these views are added by the system and we don't want to recreate them.
    public static var ignoreViewsWithNoConstraints:Bool = true
    /// This variable enable the log of the view hierarchy
    public static var logHierarchy: Bool = true
    /// This variable let you change the way view are sorted and therefore their order in the hierarchy. It's not perfect, so you might have let its value to none and change the views order in IB using "Editor/Arrange/.."
    public static var sortingMode: IBTCViewSortingMode = .none
    
    /// Find a IBTCView by using its view property
    class func findViewInHierachy(view:UIView, hierarchy:IBTCView) -> IBTCView? {
        
        
        if hierarchy.view == view {
            return hierarchy
        }else{
            for subView in hierarchy.subviews {
                if let subViewMatch = findViewInHierachy(view: view, hierarchy: subView){
                    return subViewMatch
                }
            }
        }
        
        return nil
    }
    
    /// Get a IBTCView root IBTCViewView
    class func getHierarchyRoot(hierarchy:IBTCView) ->IBTCView?{
        if hierarchy.superView == nil {
            return hierarchy
        }else{
            return getHierarchyRoot(hierarchy: hierarchy.superView!)
        }
    }
    
    /// Get view path (sibling index tree)
    class func getFullSiblingPath(hierarchy:IBTCView, path:[UInt] = []) ->[UInt]{
        if hierarchy.superView == nil {
            return path
        }else{
            let newPath = [hierarchy.subViewIndex] + path
            return getFullSiblingPath(hierarchy: hierarchy.superView!, path: newPath)
        }
    }
    
    public class func generateCode(viewController: UIViewController?, view:UIView? = nil){
        // we now need viewController to access topLayoutGuide and bottomLayoutGuide
        // we take the view parameter as root or by default the viewController's view
        let targetView = view == nil ? viewController?.view : view
        if targetView != nil {
            buildHierarchy(view: targetView!, viewController:viewController)
        }
    }
    
    /// Rebuild the view hierarchy, and log the generated code in the console.
    class func buildHierarchy(view:UIView, viewController:UIViewController?, depth:UInt = 0, siblingsCount:UInt = 0, hierarchy:IBTCView? = nil, order:UInt=0){
        
        let hasSuperview = view.superview != nil    
        var tmpOrder = order
        
        // Keep track of the number of siblings (views with same type) - needed for naming
        var typesSiblingsCount = Dictionary<String,UInt>()
        
        func getViewType(view:UIView)->String{
            
            var result = String(describing: type(of:view))
            if result.contains("UI"){
                let index = result.index(result.startIndex, offsetBy: 2)
                result = result.substring(from: index)
            }
            
            let firstChar = String(result.characters.prefix(1)).lowercased()
            let otherChars = String(result.characters.dropFirst())
            result = firstChar + otherChars
            
            return result
        }
     
        var tmpHierarchy = hierarchy
        // create hierarchy root (depth 0)
        if tmpHierarchy == nil {
            let viewName = "\(getViewType(view:view))_0"
            tmpHierarchy = IBTCView(view: view, name: viewName, subviews: [], subViewIndex: 0, superView: nil, constraints: [], depth:depth, order: tmpOrder)
           tmpOrder += 1
        }else{
            // add view to parent subviews
            if view.superview != nil {
                //print ("hasSuperview")
                if let superviewView = findViewInHierachy(view: view.superview!, hierarchy: tmpHierarchy!){
                    //print("superview found  \(superviewView.name)")
                    var tmpSubviews = superviewView.subviews
                    
                    var fullSiblingPath = getFullSiblingPath(hierarchy: superviewView).map{String($0)}.joined(separator: "_")
                    if fullSiblingPath.characters.count > 0 {
                        fullSiblingPath += "_"
                    }
                    let viewName = "\(getViewType(view:view))_\(fullSiblingPath)\(UInt(tmpSubviews.count))"
                    
                    let newView = IBTCView(view: view, name: viewName, subviews: [], subViewIndex: UInt(tmpSubviews.count), superView: superviewView, constraints: [], depth:depth, order: tmpOrder)
                    tmpOrder += 1
                    
                    tmpSubviews.append(newView)
                    superviewView.subviews = tmpSubviews
                }
            }
        }
        
        // loop over children if view is UIView (otherwise, we also get the labels inside buttons for example
        
        let viewType = type(of:view)
        
        var shouldLoopOverSubViews:Bool = viewType == UIView.self || viewType == UIScrollView.self
        if #available(iOS 9.0, *) {
            shouldLoopOverSubViews = viewType == UIView.self || viewType == UIScrollView.self || viewType == UIStackView.self
        }
        
        if shouldLoopOverSubViews {
            
            // Sort subviews, could be improved
            
            var sortedSubViews: [UIView] = view.subviews
            switch sortingMode {
                case .leftToRight:
                    sortedSubViews = view.subviews.sorted(by: {$0.center.x < $1.center.x})
                break
                case .topToDown:
                    //sortedSubViews = view.subviews.sorted(by: {$0.center.y < $1.center.y})
                    sortedSubViews = view.subviews.sorted(by: {
                        let offset = $0.center.y - $1.center.y
                        if abs(offset) < 10 {
                            return $0.center.x < $1.center.x
                        }else{
                            return offset<0
                        }
                    })
                break
                case .distance:
                    sortedSubViews = view.subviews.sorted(by: {pow($0.center.x, 2) + pow($0.center.y, 2) < pow($1.center.x, 2) + pow($1.center.y, 2)})
                break
                default:()
            }           
            
            for subview in sortedSubViews {
                // print("\(depth) : \(subview.frame.origin.y)")
                // get rid of UILayoutGuide
                if subview is UILayoutSupport{
                    continue
                }else{
                    //
                    let subViewType = getViewType(view: view)
                    if let currentSiblingsCount = typesSiblingsCount[subViewType]{
                        typesSiblingsCount[subViewType] = currentSiblingsCount + 1
                    }else{
                        typesSiblingsCount[subViewType] = 0
                    }
                    buildHierarchy(view: subview, viewController:viewController, depth: depth+1, siblingsCount: typesSiblingsCount[subViewType]!, hierarchy: tmpHierarchy, order: tmpOrder)
                    tmpOrder += 1
                }
            }
        }
        
        
        // End of process, Hierarchy is built
        if depth == 0 {
            
            // rename view_0_0 view when we can reasonably think that this is the viewController's (root) view
            if let rootView = tmpHierarchy {
                if rootView.constraints.count == 0 {
                    rootView.name = "view"
                }
            }
            
            addConstraints(hierarchy: tmpHierarchy!)
            cleanUpConstraints(hierarchy: tmpHierarchy!)
            
            
            // OUTPUT
            print("IBToCode version \(version)\n")
            
            // Display hierarchy for debuging purpose
            if logHierarchy {
                IBTCOutput.logHierarchy(hierarchy: tmpHierarchy!)
            }
            //
            IBTCOutput.logCode(hierarchy: tmpHierarchy!, viewController: viewController)
        }
    }
    
    /// Get all the view constraints
    private class func addConstraints(hierarchy:IBTCView){
        
        if let root = getHierarchyRoot(hierarchy: hierarchy) {
            let viewConstraints = getViewConstraints(viewToFind:hierarchy, hierarchy: root)
            hierarchy.constraints = viewConstraints
        }
        
        for subview in hierarchy.subviews{
            addConstraints(hierarchy: subview)
        }
    }
        
    /// Get every constraints relative to our view (constraints where our view is either item1 or item2)
    class func getViewConstraints(viewToFind:IBTCView, hierarchy:IBTCView)->[NSLayoutConstraint]{
        var constraints: [NSLayoutConstraint] = []
        
        let trueConstraints = filterConstraints(constraints: hierarchy.view.constraints)
        
        let filteredConstraints = trueConstraints.filter(){
            // print("\(viewToFind.name) \(hierarchy.name) \($0.firstItem)")
            //var result = false
            if let firstItemAsUIView = $0.firstItem as? UIView{
                if firstItemAsUIView == viewToFind.view {
                    return true
                }
            }
            if let secondItemAsUIView = $0.secondItem as? UIView{
                if secondItemAsUIView == viewToFind.view{
                    return true
                }
            }
            
            return false
        }
        constraints += filteredConstraints
        //print("\(viewToFind.name) \(filteredConstraints)")
        
        
        
        for subview in hierarchy.subviews {
            constraints +=  getViewConstraints(viewToFind:viewToFind, hierarchy:subview)
        }
        
        //print("constraints found \(viewToFind.name) : \(constraints.count)")
        
        return constraints
    }
    
    
    /// Remove constraints linked to "older" siblings
    class func cleanUpConstraints(hierarchy:IBTCView){

        var filteredConstraints = hierarchy.constraints.filter(){
            
            if let secondItemAsUIView = $0.secondItem as? UIView {
                
                if let root = getHierarchyRoot(hierarchy: hierarchy) {
                    //print("search in hierarchy  \(firstItemAsUIView.tag) \(root.subviews.count)")
                    
                    if let secondItemAsView = findViewInHierachy(view: secondItemAsUIView, hierarchy: root){
                        
                        let skip = secondItemAsView.order > hierarchy.order
                        if skip == true{
                            return false
                        }
                    }
                }
            }
            
            if let firstItemAsUIView = $0.firstItem as? UIView {
                if let root = getHierarchyRoot(hierarchy: hierarchy) {
                    //print("search in hierarchy  \(firstItemAsUIView.tag) \(root.subviews.count)")
                    
                    if let firstItemAsView = findViewInHierachy(view: firstItemAsUIView, hierarchy: root){
                        
                        let skip = firstItemAsView.order > hierarchy.order
                        if skip == true{
                            return false
                        }
                    }
                }
            }
            return true
        }
        
        // reverse constraints if needed
        for index in 0 ..< filteredConstraints.count {
            let constraint = filteredConstraints[index]
            if let firstItemAsUIView = constraint.firstItem as? UIView {
                if firstItemAsUIView != hierarchy.view {
                    //print("need to be reversed")
                    filteredConstraints[index] = reverseConstraint(constraint: constraint)
                }
            }
        }
        
        hierarchy.constraints = filteredConstraints
        
        for subview in hierarchy.subviews {
            cleanUpConstraints(hierarchy: subview)
        }
    }
    
    /// Reverse constraint.firstItem and constraint.secondItem
    class func reverseConstraint(constraint:NSLayoutConstraint)->NSLayoutConstraint{
        
        var inversedRelation:NSLayoutRelation!
        switch constraint.relation{
        case .equal:
            inversedRelation = .equal
        case .greaterThanOrEqual:
            inversedRelation = .lessThanOrEqual
        case .lessThanOrEqual:
           inversedRelation = .greaterThanOrEqual
        }
        
        let reservedConstraint = NSLayoutConstraint(item: constraint.secondItem!, attribute: constraint.secondAttribute, relatedBy: inversedRelation, toItem: constraint.firstItem, attribute: constraint.firstAttribute, multiplier: constraint.multiplier, constant: -constraint.constant)
        return reservedConstraint
    }
    
    
    /// Get rid of _UILayoutSupportConstraint constraints
    class func filterConstraints(constraints:[NSLayoutConstraint]) ->[NSLayoutConstraint]{
        
        /// DEBUG
        /*
        func typeof(object:AnyObject?)->String{
            if object == nil {
                return "nil"
            }else{
                return String(describing: type(of:object!))
            }
        }
        
        func getAttr(attr:Int) ->String {
            switch attr {
            case NSLayoutAttribute.bottom.rawValue:
                return "bottom"
            case NSLayoutAttribute.bottomMargin.rawValue:
                return "bottomMargin"
            case NSLayoutAttribute.centerX.rawValue:
                return "centerX"
            case NSLayoutAttribute.centerXWithinMargins.rawValue:
                return "centerXWithinMargins"
            case NSLayoutAttribute.centerY.rawValue:
                return "centerY"
            case NSLayoutAttribute.centerYWithinMargins.rawValue:
                return "centerYWithinMargins"
            case NSLayoutAttribute.firstBaseline.rawValue:
                return "firstBaseline"
            case NSLayoutAttribute.height.rawValue:
                return "height"
            case NSLayoutAttribute.lastBaseline.rawValue:
                return "lastBaseline"
            case NSLayoutAttribute.leading.rawValue:
                return "leading"
            case NSLayoutAttribute.leadingMargin.rawValue:
                return "leadingMargin"
            case NSLayoutAttribute.left.rawValue:
                return "left"
            case NSLayoutAttribute.leftMargin.rawValue:
                return "leftMargin"
            case NSLayoutAttribute.notAnAttribute.rawValue:
                return "notAnAttribute"
            case NSLayoutAttribute.right.rawValue:
                return "right"
            case NSLayoutAttribute.rightMargin.rawValue:
                return "rightMargin"
            case NSLayoutAttribute.top.rawValue:
                return "top"
            case NSLayoutAttribute.topMargin.rawValue:
                return "topMargin"
            case NSLayoutAttribute.trailing.rawValue:
                return "trailing"
            case NSLayoutAttribute.trailingMargin.rawValue:
                return "trailingMargin"
            case NSLayoutAttribute.width.rawValue:
                return "width"
            default:
                return "unknownAttribute"
            }
        }
        
        print(">>>>")
        for constraint in constraints {
            
            print("\(typeof(object: constraint.firstItem)) \(getAttr(attr: constraint.firstAttribute.rawValue)) \(typeof(object:constraint.secondItem)) \(getAttr(attr: constraint.secondAttribute.rawValue)) \(constraint.relation.rawValue)")
        }
        print("<<<<")
         */
        /// DEBUG
        
        let filteredConstraints = constraints.filter({type(of:$0) == NSLayoutConstraint.self})
        return filteredConstraints
    }
   
}
