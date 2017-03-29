//
//  IBToCodeOutput.swift
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

import UIKit

class IBTCOutput {
    
    static var hierarchyOutput: String!
    static var codeOutput: String!
    
    /// Log the view hierarchy
    class func logHierarchy(hierarchy:IBTCView, depth:UInt = 0){

        if depth == 0 {
            hierarchyOutput = ""
        }
        var prefix = ""
        var i:UInt = 0
        while i < depth {
            prefix = "  "+prefix
            i += 1
        }
        let skip = IBToCode.ignoreViewsWithNoConstraints && hierarchy.constraints.count == 0
        if !skip {
            var viewInfo = prefix + " + \(hierarchy.name)"
            if hierarchy.view.tag != 0 {
                viewInfo += " (tag:\(hierarchy.view.tag))"
            }
            //- center \(hierarchy.view.center)
            viewInfo += " - \(hierarchy.constraints.count) constraints \n"
            hierarchyOutput.append(viewInfo)
        }
        for subView in hierarchy.subviews{
            logHierarchy(hierarchy: subView, depth: depth + 1)
        }
        
        if depth == 0 {
            print("Hierarchy:\n\n"+hierarchyOutput)
        }
    }
    
    /// Log the generated code
    class func logCode(hierarchy:IBTCView, viewController:UIViewController, depth:UInt = 0){
        if depth == 0 {
            codeOutput = ""
        }
        
        let skip = IBToCode.ignoreViewsWithNoConstraints && hierarchy.constraints.count == 0
        if !skip {
            let viewType = String(describing: type(of:hierarchy.view))
            let parentName = hierarchy.superView != nil ? hierarchy.superView!.name : "view"
            
            codeOutput.append("\nlet \(hierarchy.name) = \(viewType)()\n")
            codeOutput.append("\(parentName).addSubview(\(hierarchy.name))\n")
            // TODO
            //print(hierarchy.view.contentHuggingPriority(for: .horizontal))
            
            // log properties
            if let properties = hierarchy.properties {
                for key in properties.keys {
                    codeOutput.append("\(hierarchy.name).\(key) = \(properties[key]!)\n")
                }
            }
            for initFunction in hierarchy.initFunctions{
                codeOutput.append("\(hierarchy.name).\(initFunction)\n")
            }
            
            //log constraints
            if let root = IBToCode.getHierarchyRoot(hierarchy: hierarchy) {
                if hierarchy.constraints.count > 0 {
                    switch IBToCode.constraintFormat{
                    case .snapKit3:
                        codeOutput.append(getSnapKit3Code(viewController: viewController, rootHierarchy: root, currentView: hierarchy, constraints:hierarchy.constraints))
                        break
                    case .nsLayoutConstraint:
                        codeOutput.append(getNSLayoutConstraintCode(viewController: viewController, rootHierarchy: root, currentView: hierarchy, constraints:hierarchy.constraints))
                        break
                    case .anchors:
                        codeOutput.append(getAnchorsConstraintCode(viewController: viewController, rootHierarchy: root, currentView: hierarchy, constraints:hierarchy.constraints))
                        break
                    }
                }
            }
        }
        
        for subView in hierarchy.subviews {
            logCode(hierarchy: subView, viewController: viewController, depth: depth+1)
        }
        

        if depth == 0 {
            print("Code:\n"+codeOutput)
        }
        
    }
    
    
    // SNAPKIT Output Syntax
    
    class func getSnapKit3Code(viewController: UIViewController, rootHierarchy: IBTCView, currentView: IBTCView, constraints:[NSLayoutConstraint]) ->String {
        var result = "\(currentView.name).translatesAutoresizingMaskIntoConstraints = false\n" + "\(currentView.name).snp.makeConstraints { (make) -> Void in\n"
        for constraint in constraints{
            result += "    " + convertToSnapKit3(viewController: viewController, rootHierarchy: rootHierarchy, constraint: constraint)+"\n"
            //result += "    \(constraint) \n"
        }
        result += "}\n"
        return result
    }
    
    class func convertToSnapKit3(viewController: UIViewController, rootHierarchy: IBTCView, constraint:NSLayoutConstraint) ->String{
        
        // TODO: handle priorities
        // TODO: replace "view 2" by "superview" when possible
        // TODO: omit attributes when identical
        
        // Inner functions
        func convertAttribute(attribute:NSLayoutAttribute)->String{
            var result = ""
            switch attribute {
            case .left:
                result = "left"
            case .right:
                result = "right"
            case .leading:
                result = "leading"
            case .trailing:
                result = "trailing"
            case .top:
                result = "top"
            case .topMargin:
                result = "top"
            case .bottom:
                result = "bottom"
            case .centerX:
                result = "centerX"
            case .centerXWithinMargins:
                result = "centerXWithinMargins"
            case .centerY:
                result = "centerY"
            case .centerYWithinMargins:
                result = "centerYWithinMargins"
            case .width:
                result = "width"
            case .height:
                result = "height"
            default:()
            }
            return result
        }
        
        func convertRelation(relation:NSLayoutRelation)->String{
            var result = ""
            switch constraint.relation{
            case .equal:
                result = "equalTo"
            case .greaterThanOrEqual:
                result = "greaterThanOrEqualTo"
            case .lessThanOrEqual:
                result = "lessThanOrEqualTo"
            }
            return result
        }
        
        let relation = convertRelation(relation: constraint.relation)
        let firstAttr = convertAttribute(attribute: constraint.firstAttribute)
        let secondAtt = convertAttribute(attribute: constraint.secondAttribute)
        
        /*var firstItemName = "nil"
        if let firstView = constraint.firstItem as? UIView {
            if let firstViewMatch = IBToCode.findViewInHierachy(view: firstView, hierarchy: rootHierarchy){
                firstItemName = firstViewMatch.name
            }
        }*/
        
        var secondItemName = "nil"
        if let secondView = constraint.secondItem as? UIView {
            if let secondViewMatch = IBToCode.findViewInHierachy(view: secondView, hierarchy: rootHierarchy){
                secondItemName = secondViewMatch.name
            }
        }
        
        // Support top and bottom layout guide
        if let layoutGuide = constraint.secondItem as? UILayoutSupport {
            //print("Casting to UILayoutSupport OK !!!!")
            if layoutGuide === viewController.topLayoutGuide {
                secondItemName = "topLayoutGuide"
            }
            if layoutGuide === viewController.bottomLayoutGuide {
                secondItemName = "bottomLayoutGuide"
            }
        }
        
        //print("*     secondItemType \(String(describing:type(of:constraint.secondItem)))")
        
        //print("\(type(of:constraint.firstItem)) \(type(of:constraint.secondItem)) ")
        
        var result = ""
        if (constraint.firstAttribute == .width || constraint.firstAttribute == .height) && secondItemName == "nil"{
            result = "make.\(firstAttr).\(relation)(\(constraint.constant))"
        }else{
            result = "make.\(firstAttr).\(relation)(\(secondItemName).snp.\(secondAtt))"
            if constraint.constant != 0 {
                result += ".offset(\(constraint.constant))"
            }
        }
        
        return result
    }
    
    
    // Anchors Output syntax
    
    class func getAnchorsConstraintCode(viewController: UIViewController, rootHierarchy: IBTCView, currentView: IBTCView, constraints:[NSLayoutConstraint]) ->String {
        var result = "\(currentView.name).translatesAutoresizingMaskIntoConstraints = false\n"
        
        for constraint in constraints{
            let convertedConstraint = convertToAnchorConstraint(viewController: viewController, rootHierarchy: rootHierarchy, constraint: constraint)
            result +=  convertedConstraint + "\n"
        }
        return result
    }
    
    
    class func convertToAnchorConstraint(viewController: UIViewController, rootHierarchy: IBTCView, constraint:NSLayoutConstraint) -> String {
        
        // TODO: handle priorities
        
        // Inner functions
        func convertAttribute(attribute:NSLayoutAttribute)->String{
            var result = ""
            switch attribute {
            case .left:
                result = "left"
            case .right:
                result = "right"
            case .leading:
                result = "leading"
            case .trailing:
                result = "trailing"
            case .top:
                result = "top"
            case .topMargin:
                result = "top"
            case .bottom:
                result = "bottom"
            case .centerX:
                result = "centerX"
            case .centerY:
                result = "centerY"
            case .width:
                result = "width"
            case .height:
                result = "height"
            case .centerXWithinMargins:
                result = "centerX"
            case .centerYWithinMargins:
                result = "centerY"
            default:
                result = "notAnAttribute"
            }
            return result
        }
        
        func convertRelation(relation:NSLayoutRelation)->String{
            var result = ""
            switch constraint.relation{
            case .equal:
                result = "equalTo"
            case .greaterThanOrEqual:
                result = "greaterThanOrEqualTo"
            case .lessThanOrEqual:
                result = "lessThanOrEqualTo"
            }
            return result
        }
        
        var relation = convertRelation(relation: constraint.relation)
        let firstAttr = convertAttribute(attribute: constraint.firstAttribute)
        let secondAttr = convertAttribute(attribute: constraint.secondAttribute)
        let isActive = constraint.isActive ? "true" : "false"
        
        var firstItemName = "nil"
        if let firstView = constraint.firstItem as? UIView {
            if let firstViewMatch = IBToCode.findViewInHierachy(view: firstView, hierarchy: rootHierarchy){
                firstItemName = firstViewMatch.name
            }
        }
        
        var secondItemName = "nil"
        if let secondView = constraint.secondItem as? UIView {
            if let secondViewMatch = IBToCode.findViewInHierachy(view: secondView, hierarchy: rootHierarchy){
                secondItemName = secondViewMatch.name
            }
        }
        
        
        // Support top and bottom layout guide
        if let layoutGuide = constraint.secondItem as? UILayoutSupport {
            //print("Casting to UILayoutSupport OK !!!!")
            if layoutGuide === viewController.topLayoutGuide {
                secondItemName = "topLayoutGuide"
            }
            if layoutGuide === viewController.bottomLayoutGuide {
                secondItemName = "bottomLayoutGuide"
            }
        }
        
        var secondItemString = ""
        if secondItemName == "nil"{
            relation += "Constant"
            secondItemString = "\(constraint.constant)"
        }else{
            secondItemString = "\(secondItemName).\(secondAttr)Anchor"
            if constraint.constant != 0 {
                secondItemString += ", constant: \(constraint.constant)"
            }
        }
        
        if constraint.multiplier != 1 {
            secondItemString += ", multiplier: \(constraint.multiplier)"
        }
    
        let result = "\(firstItemName).\(firstAttr)Anchor.constraint(\(relation): \(secondItemString)).isActive = \(isActive)"
        
        return (result)
    }
    
    // NSLayoutConstraint Output syntax
    
    class func getNSLayoutConstraintCode(viewController: UIViewController, rootHierarchy: IBTCView, currentView: IBTCView, constraints:[NSLayoutConstraint]) ->String {
        var result = "\(currentView.name).translatesAutoresizingMaskIntoConstraints = false\n"
        var constraintsSets: Dictionary<String, [String]> = Dictionary()
        for constraint in constraints{
            
            let convertedConstraint = convertToNSLayoutConstraint(viewController: viewController, rootHierarchy: rootHierarchy, constraint: constraint)
            
            if constraintsSets[convertedConstraint.constraintTargetViewName] == nil {
                constraintsSets[convertedConstraint.constraintTargetViewName] = []
            }
            let isActive = constraint.isActive
            if isActive {
                constraintsSets[convertedConstraint.constraintTargetViewName]!.append(convertedConstraint.varName)
            }
            let prefix = isActive ? "" : "//"
            result += prefix + convertedConstraint.output + "\n"
        }
        
        for item2Name in constraintsSets.keys {
            let itemName = item2Name == "nil" ? currentView.name : item2Name
            result += "\(itemName).addConstraints([\(constraintsSets[item2Name]!.joined(separator: ", "))])\n"
        }
        
        return result
    }
    
    
    class func convertToNSLayoutConstraint(viewController: UIViewController, rootHierarchy: IBTCView, constraint:NSLayoutConstraint) -> (varName:String, constraintTargetViewName:String, output:String) {
        
        // TODO: handle priorities
        
        // Inner functions
        func convertAttribute(attribute:NSLayoutAttribute)->String{
            var result = ""
            switch attribute {
            case .left:
                result = "left"
            case .right:
                result = "right"
            case .leading:
                result = "leading"
            case .trailing:
                result = "trailing"
            case .top:
                result = "top"
            case .topMargin:
                result = "top"
            case .bottom:
                result = "bottom"
            case .centerX:
                result = "centerX"
            case .centerXWithinMargins:
                result = "centerXWithinMargins"
            case .centerY:
                result = "centerY"
            case .centerYWithinMargins:
                result = "centerYWithinMargins"
            case .width:
                result = "width"
            case .height:
                result = "height"
            default:
                result = "notAnAttribute"
            }
            return result
        }
        
        func convertRelation(relation:NSLayoutRelation)->String{
            var result = ""
            switch constraint.relation{
            case .equal:
                result = "equal"
            case .greaterThanOrEqual:
                result = "greaterThanOrEqual"
            case .lessThanOrEqual:
                result = "lessThanOrEqual"
            }
            return result
        }
        
        let relation = convertRelation(relation: constraint.relation)
        let firstAttr = convertAttribute(attribute: constraint.firstAttribute)
        let secondAtt = convertAttribute(attribute: constraint.secondAttribute)
        
        // Tricky
        // We need to add the constraints to the highest view in the hierarchy between item1.superView and item2.superView
        // in the case of width or height, it's between item1 and item2
        
        var targetViewName = "nil"
        var firstItemSuperViewDepth:UInt?

        var firstItemName = "nil"
        if let firstView = constraint.firstItem as? UIView {
            if let firstViewMatch = IBToCode.findViewInHierachy(view: firstView, hierarchy: rootHierarchy){
                firstItemName = firstViewMatch.name
                if ["width", "height"].contains(firstAttr){
                    targetViewName = firstViewMatch.name
                    firstItemSuperViewDepth = firstViewMatch.depth
                }else{
                    if let firstViewMatchSuperView = firstViewMatch.superView {

                        targetViewName = firstViewMatchSuperView.name
                        firstItemSuperViewDepth = firstViewMatchSuperView.depth
                    }
                }
            }
        }

        var secondItemName = "nil"
        if let secondView = constraint.secondItem as? UIView {
            if let secondViewMatch = IBToCode.findViewInHierachy(view: secondView, hierarchy: rootHierarchy){
                secondItemName = secondViewMatch.name
                if ["width", "height"].contains(firstAttr){
                    if let firstItemSuperViewDepthUnWrapped = firstItemSuperViewDepth {
                        if secondViewMatch.depth < firstItemSuperViewDepthUnWrapped {
                            targetViewName = secondItemName
                        }
                    }
                }else{
                    if let secondViewMatchSuperView = secondViewMatch.superView {

                        if let firstItemSuperViewDepthUnWrapped = firstItemSuperViewDepth {
                            if secondViewMatchSuperView.depth < firstItemSuperViewDepthUnWrapped {
                                targetViewName = secondViewMatchSuperView.name
                            }
                        }
                    }
                }
            }
        }

        
        // Support top and bottom layout guide
        if let layoutGuide = constraint.secondItem as? UILayoutSupport {
            //print("Casting to UILayoutSupport OK !!!!")
            if layoutGuide === viewController.topLayoutGuide {
                secondItemName = "topLayoutGuide"
            }
            if layoutGuide === viewController.bottomLayoutGuide {
                secondItemName = "bottomLayoutGuide"
            }
        }
        
        let varName = "\(firstItemName)\(firstAttr.capitalized)Constraint"
        let result = "let \(varName) = NSLayoutConstraint(item: \(firstItemName), attribute: .\(firstAttr), relatedBy: .\(relation), toItem: \(secondItemName), attribute: .\(secondAtt), multiplier: \(constraint.multiplier), constant: \(constraint.constant))"
        
        return (varName: varName, constraintTargetViewName: targetViewName, output: result)
    }


}
