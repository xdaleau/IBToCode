//
//  IBTCExtractProperties.swift
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


extension UIColor {
    // Reliable ?
    func isEqualToColor(otherColor : UIColor) -> Bool {
        let selfCIColor = CIColor(color: self)
        let otherCIColor = CIColor(color: otherColor)
        return (selfCIColor.red == otherCIColor.red && selfCIColor.blue == otherCIColor.blue && selfCIColor.green == otherCIColor.green && selfCIColor.alpha == otherCIColor.alpha)
    }
}

class IBTCProperties {
    
    static func extractProperties(ibtcView: IBTCView) -> Dictionary<String,Any>? {
        
        func extractTextAlignment(alignment:Int) -> String{
            switch alignment {
            case NSTextAlignment.left.rawValue:
                return ".left"
            case NSTextAlignment.center.rawValue:
                return ".center"
            case NSTextAlignment.right.rawValue:
                return ".left"
            case NSTextAlignment.justified.rawValue:
                return ".justified"
            case NSTextAlignment.natural.rawValue:
                return ".natural"
            default:
                return "Failed"
            }
        }
        
        func extractLineBreakMode(mode:Int) -> String {
            switch mode {
            case NSLineBreakMode.byCharWrapping.rawValue:
                return ".byCharWrapping"
            case NSLineBreakMode.byClipping.rawValue:
                return ".byClipping"
            case NSLineBreakMode.byTruncatingHead.rawValue:
                return ".byTruncatingHead"
            case NSLineBreakMode.byTruncatingMiddle.rawValue:
                return ".byTruncatingMiddle"
            case NSLineBreakMode.byTruncatingTail.rawValue:
                return ".byTruncatingTail"
            case NSLineBreakMode.byWordWrapping.rawValue:
                return ".byWordWrapping"
            default:
                return "Failed"
            }
        }
        
        func extractFont(font:UIFont) -> String {
            return("UIFont(name: \"\(font.fontName)\", size: \(font.pointSize))")
        }
        
        func extractBorderStyle(borderStyle:Int) -> String {
            switch borderStyle {
            case UITextBorderStyle.none.rawValue:
                return ".none"
            case UITextBorderStyle.line.rawValue:
                return ".line"
            case UITextBorderStyle.bezel.rawValue:
                return ".bezel"
            case UITextBorderStyle.roundedRect.rawValue:
                return ".roundedRect"
            default:
                return "Failed"
            }
        }
        
        func extractImage(image:UIImage?) -> String {
            guard image != nil else {
                return ""
            }
            // can't get the image name
            return "UIImage(named:\"\")"
        }
        
        func extractContentMode(contentMode: Int) -> String {
            switch contentMode {
            case UIViewContentMode.bottom.rawValue:
                return ".bottom"
            case UIViewContentMode.bottomLeft.rawValue:
                return ".bottomLeft"
            case UIViewContentMode.bottomRight.rawValue:
                return ".bottomRight"
            case UIViewContentMode.center.rawValue:
                return ".center"
            case UIViewContentMode.left.rawValue:
                return ".left"
            case UIViewContentMode.right.rawValue:
                return ".right"
            case UIViewContentMode.scaleAspectFill.rawValue:
                return ".scaleAspectFill"
            case UIViewContentMode.scaleToFill.rawValue:
                return ".scaleToFill"
            case UIViewContentMode.scaleAspectFit.rawValue:
                return ".scaleAspectFit"
            case UIViewContentMode.top.rawValue:
                return ".top"
            case UIViewContentMode.topLeft.rawValue:
                return ".topLeft"
            case UIViewContentMode.topRight.rawValue:
                return ".topRight"
            default:
                return "Failed"
            }
        }
        
        func extractColor(color:UIColor) -> String {
            
            let namedColors:[(name:String,color:UIColor)] = [
                (name:"white", color:.white),
                (name:"black", color:.black),
                (name:"gray", color:.gray),
                (name:"lightGray", color:.lightGray),
                (name:"darkGray", color:.darkGray),
                (name:"red", color:.red),
                (name:"clear", color:.clear)
            ]
            
            for namedColor in namedColors {
                let colorsAreEqual = namedColor.color.isEqualToColor(otherColor: color)
                if colorsAreEqual {
                    return "UIColor.\(namedColor.name)"
                }
            }
            
            let ciColor = CIColor(color: color)
            let red = ciColor.red
            let green = ciColor.green
            let blue = ciColor.blue
            let alpha = ciColor.alpha
            
            return "UIColor(colorLiteralRed: \(red), green: \(green), blue: \(blue), alpha: \(alpha))"
        }
        
       
        var properties:Dictionary<String,Any> = Dictionary()
        var propertiesList:[String] = []
        let commonList = ["backgroundColor", "tag"]
        propertiesList += commonList
        
        let viewType = type(of: ibtcView.view)
        switch String(describing: viewType) {
        case "UIView":
            
            break
        case "UILabel":
            propertiesList += ["text", "textColor", "font", "numberOfLines", "lineBreakMode", "textAlignment"]
            break
        case "UITextField":
            propertiesList += ["placeholder", "textColor", "font", "borderStyle"]
            break
        case "UITextView":
            propertiesList += ["text"]
        case "UIButton":
            propertiesList += ["titleLabel"]
        case "UISegmentedControl":
            propertiesList += ["segments"]
        case "UIImageView":
            propertiesList += ["contentMode","image"]
        default:()
        }
        
        for key in propertiesList{
            
            if key == "segments" {
                if let segmentedControl = ibtcView.view as? UISegmentedControl {
                    for index in 0..<segmentedControl.numberOfSegments {
                        if let title = segmentedControl.titleForSegment(at: index) {
                            ibtcView.initFunctions.append("insertSegment(withTitle:\"\(title)\", at: \(index), animated: false)")
                            //insertSegment(withTitle: <#T##String?#>, at: <#T##Int#>, animated: <#T##Bool#>)
                        }
                    }
                }
                continue
            }
            
            if var value = ibtcView.view.value(forKey:key){
                //print("prop \(key) \(value)")
                
                if ["backgroundColor", "textColor"].contains(key) {
                    value = extractColor(color: value as! UIColor)
                }
                
                if key == "lineBreakMode" {
                    value = extractLineBreakMode(mode: value as! Int)
                }
                
                if key == "textAlignment" {
                    value = extractTextAlignment(alignment: value as! Int)
                }
                
                if key == "font" {
                    value = extractFont(font: value as! UIFont)
                }
                
                if key == "image" {
                    value = extractImage(image: value as? UIImage)
                }
                
                if key == "contentMode" {
                    value = extractContentMode(contentMode: value as! Int)
                }
                
                if key == "borderStyle" {
                    value = extractBorderStyle(borderStyle: value as! Int)
                }
                
                if key == "tag" {
                    if value as! Int == 0 {
                        continue
                    }
                }
                
                if key == "titleLabel" {
                    if let label = value as? UILabel{
                        ibtcView.initFunctions.append("setTitle(\"\(label.text!)\", for: .normal)")
                        ibtcView.initFunctions.append("setTitleColor(\(extractColor(color: label.textColor!)), for: .normal)")
                        continue
                    }
                }
                
                if ["text", "title", "placeholder"].contains(key) {
                    value = "\"\(value)\""
                }
                
                properties[key] = value
            }
            
        }
        
        return properties
    }
}

